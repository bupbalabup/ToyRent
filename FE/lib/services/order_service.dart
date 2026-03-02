import '../models/order_model.dart';
import '../models/toy_model.dart';
import 'api_service.dart';

class ShippingAddressPayload {
  const ShippingAddressPayload({
    required this.fullName,
    required this.phone,
    required this.province,
    required this.district,
    required this.ward,
    required this.street,
  });

  final String fullName;
  final String phone;
  final String province;
  final String district;
  final String ward;
  final String street;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fullName': fullName,
      'phone': phone,
      'province': province,
      'district': district,
      'ward': ward,
      'street': street,
    };
  }
}

class OrderService {
  OrderService(this._apiService);

  final ApiService _apiService;

  Future<List<OrderModel>> fetchOrders() async {
    final response = await _apiService.get('/orders/me', withAuth: true);
    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    final list = (data?['orders'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();
    return list.map(OrderModel.fromJson).toList(growable: false);
  }

  Future<OrderModel> createOrder({
    required List<(ToyModel, int)> items,
    required DateTime rentalStartDate,
    required DateTime rentalEndDate,
    required String fulfillmentType,
    required String paymentMethod,
    ShippingAddressPayload? shippingAddress,
    String? voucherCode,
  }) async {

    final payload = <String, dynamic>{
      'rentalStartDate': rentalStartDate.toIso8601String(),
      'rentalEndDate': rentalEndDate.toIso8601String(),
      'fulfillmentType': fulfillmentType,
      'paymentMethod': paymentMethod,
      'items': items
          .map(
            (entry) => <String, dynamic>{
              'toyId': entry.$1.id,
              'quantity': entry.$2,
            },
          )
          .toList(growable: false),
    };

    if (shippingAddress != null) {
      payload['shippingAddress'] = shippingAddress.toJson();
    }

    if (voucherCode != null && voucherCode.trim().isNotEmpty) {
      payload['voucherCode'] = voucherCode.trim();
    }

    final response = await _apiService.post('/orders', payload, withAuth: true);
    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    return OrderModel.fromJson(data?['order'] as Map<String, dynamic>);
  }
}
