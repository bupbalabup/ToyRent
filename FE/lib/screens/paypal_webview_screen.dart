import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaypalWebviewResult {
  final bool success;
  final bool cancelled;
  final String? paypalOrderId;

  PaypalWebviewResult({
    required this.success,
    required this.cancelled,
    this.paypalOrderId,
  });
}

class PaypalWebviewScreen extends StatefulWidget {
  final String paymentUrl;

  const PaypalWebviewScreen({super.key, required this.paymentUrl});

  @override
  State<PaypalWebviewScreen> createState() => _PaypalWebviewScreenState();
}

class _PaypalWebviewScreenState extends State<PaypalWebviewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (_) {
            if (!_loading) return;
            setState(() {
              _loading = true;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _loading = false;
            });
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _error = error.description;
              _loading = false;
            });
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) {
              return NavigationDecision.navigate;
            }

            if (request.url.contains('/api/payment/success')) {
              Navigator.of(context).pop(
                PaypalWebviewResult(
                  success: true,
                  cancelled: false,
                  paypalOrderId: uri.queryParameters['token'],
                ),
              );
              return NavigationDecision.prevent;
            }

            if (request.url.contains('/api/payment/cancel')) {
              Navigator.of(context).pop(
                PaypalWebviewResult(
                  success: false,
                  cancelled: true,
                  paypalOrderId: uri.queryParameters['token'],
                ),
              );
              return NavigationDecision.prevent;
            }

            if (request.url.contains('/api/payment/error')) {
              Navigator.of(context).pop(
                PaypalWebviewResult(
                  success: false,
                  cancelled: false,
                  paypalOrderId: uri.queryParameters['token'],
                ),
              );
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  Future<void> _openExternalFallback() async {
    final uri = Uri.parse(widget.paymentUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open external browser.')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Complete payment in browser, then return and tap Done.'),
      ),
    );
  }

  void _manualDone() {
    Navigator.of(context).pop(
      PaypalWebviewResult(success: true, cancelled: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('PayPal Checkout'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'PayPal checkout opens in a browser tab on web. Complete payment there, then return here and tap Done Payment.',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _openExternalFallback,
                child: const Text('Open PayPal'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _manualDone,
                child: const Text('Done Payment'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PayPal Checkout'),
        actions: [
          TextButton(
            onPressed: _openExternalFallback,
            child: const Text('Open Browser'),
          )
        ],
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            MaterialBanner(
              content: Text('WebView error: $_error'),
              actions: [
                TextButton(onPressed: _openExternalFallback, child: const Text('Fallback')),
              ],
            ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _manualDone,
                child: const Text('Done Payment'),
              ),
            ),
          )
        ],
      ),
    );
  }
}
