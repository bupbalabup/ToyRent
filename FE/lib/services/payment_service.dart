import '../core/errors/app_exception.dart';
import 'api_service.dart';

class PaymentService {
  PaymentService(this._apiService);

  final ApiService _apiService;

  Future<Map<String, dynamic>> checkout({
    required String orderId,
    required String paymentMethod,
  }) async {
    final response = await _apiService.post(
      '/payments/checkout',
      <String, dynamic>{
        'orderId': orderId,
        'paymentMethod': paymentMethod,
      },
      withAuth: true,
    );

    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw AppException('Invalid payment response');
    }

    return data;
  }
}
