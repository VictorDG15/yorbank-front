import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/api_client.dart';
import '../domain/loan_models.dart';

final loanApiProvider = Provider((ref) => LoanApi(ref.watch(dioProvider)));

final loanProductsProvider = FutureProvider<List<LoanProduct>>((ref) {
  return ref.watch(loanApiProvider).products();
});

final loanApplicationsProvider =
    FutureProvider<List<LoanApplicationSummary>>((ref) {
  return ref.watch(loanApiProvider).applications();
});

class LoanApi {
  LoanApi(this._dio);

  static const _downloadsChannel = MethodChannel('ybank/downloads');

  final Dio _dio;

  Future<List<LoanProduct>> products() async {
    final response = await _dio.get('/api/v1/loans/products');
    final items = (response.data['data'] ?? response.data) as List<dynamic>;
    return items
        .map((e) => LoanProduct.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<LoanSimulation> simulate({
    required int productId,
    required double amount,
    required int months,
    required String accountNumber,
    required DateTime startDate,
    required int paymentDay,
    required String purpose,
    required double declaredMonthlyIncome,
  }) async {
    final response = await _dio.post(
      '/api/v1/loans/simulate',
      data: _requestBody(
        productId: productId,
        amount: amount,
        months: months,
        accountNumber: accountNumber,
        startDate: startDate,
        paymentDay: paymentDay,
        purpose: purpose,
        declaredMonthlyIncome: declaredMonthlyIncome,
      ),
    );
    final data = response.data['data'] ?? response.data;
    return LoanSimulation.fromJson(Map<String, dynamic>.from(data));
  }

  Future<LoanApplicationResult> apply({
    required int productId,
    required double amount,
    required int months,
    required String accountNumber,
    required DateTime startDate,
    required int paymentDay,
    required String purpose,
    required double declaredMonthlyIncome,
  }) async {
    final response = await _dio.post(
      '/api/v1/loans/applications',
      data: _requestBody(
        productId: productId,
        amount: amount,
        months: months,
        accountNumber: accountNumber,
        startDate: startDate,
        paymentDay: paymentDay,
        purpose: purpose,
        declaredMonthlyIncome: declaredMonthlyIncome,
      ),
    );
    final data = response.data['data'] ?? response.data;
    return LoanApplicationResult.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<LoanApplicationSummary>> applications() async {
    final response = await _dio.get('/api/v1/loans/applications');
    final items = (response.data['data'] ?? response.data) as List<dynamic>;
    return items
        .map(
          (e) => LoanApplicationSummary.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<String> downloadSchedulePdf(int applicationId) async {
    final response = await _dio.get<List<int>>(
      '/api/v1/loans/applications/$applicationId/schedule.pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data ?? const <int>[];
    final fileName = 'cronograma-prestamo-$applicationId.pdf';

    if (Platform.isAndroid) {
      try {
        final savedPath = await _downloadsChannel.invokeMethod<String>(
          'savePdfToDownloads',
          {
            'fileName': fileName,
            'mimeType': 'application/pdf',
            'bytes': Uint8List.fromList(bytes),
          },
        );
        return savedPath ?? 'Descargas/$fileName';
      } on MissingPluginException {
        return _saveAndroidFallback(bytes, fileName);
      } on PlatformException {
        return _saveAndroidFallback(bytes, fileName);
      }
    }

    final separator = Platform.pathSeparator;
    final file = File('${Directory.systemTemp.path}$separator$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String> _saveAndroidFallback(List<int> bytes, String fileName) async {
    final downloads = Directory('/storage/emulated/0/Download');
    if (downloads.existsSync()) {
      final file = File('${downloads.path}/${fileName}');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    }
    final separator = Platform.pathSeparator;
    final file = File('${Directory.systemTemp.path}$separator$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Map<String, dynamic> _requestBody({
    required int productId,
    required double amount,
    required int months,
    required String accountNumber,
    required DateTime startDate,
    required int paymentDay,
    required String purpose,
    required double declaredMonthlyIncome,
  }) {
    return {
      'productId': productId,
      'amount': amount,
      'months': months,
      'accountNumber': accountNumber,
      'startDate': _date(startDate),
      'paymentDay': paymentDay,
      'purpose': purpose,
      'declaredMonthlyIncome': declaredMonthlyIncome,
    };
  }

  String _date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
