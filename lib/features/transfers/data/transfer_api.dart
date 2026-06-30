import 'package:dio/dio.dart';

class TransferApi {
  TransferApi(this._dio);
  final Dio _dio;

  Future<void> createTransfer({required String toAccount, required double amount, required String description}) async {
    await _dio.post('/api/v1/transfers', data: {
      'originAccount': '001-101-00045821',
      'destinationAccount': toAccount,
      'amount': amount,
      'currency': 'PEN',
      'description': description,
    });
  }
}
