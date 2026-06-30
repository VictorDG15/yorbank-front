import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/api_client.dart';
import '../domain/account_summary.dart';
import '../domain/account_movement.dart';
import '../domain/banking_catalog.dart';
import '../domain/home_summary.dart';

final bankingApiProvider = Provider((ref) {
  return BankingApi(ref.watch(dioProvider));
});

final homeSummaryProvider = FutureProvider<HomeSummary>((ref) {
  return ref.watch(bankingApiProvider).homeSummary();
});

final accountSummariesProvider = FutureProvider<List<AccountSummary>>((ref) {
  return ref.watch(bankingApiProvider).accounts();
});

final accountMovementsProvider = FutureProvider<List<AccountMovement>>((ref) {
  return ref.watch(bankingApiProvider).movements();
});

final transferBanksProvider = FutureProvider<List<TransferBank>>((ref) {
  return ref.watch(bankingApiProvider).transferBanks();
});

final serviceBillsProvider = FutureProvider<List<ServiceBill>>((ref) {
  return ref.watch(bankingApiProvider).services();
});

final yapeContactsProvider = FutureProvider<List<YapeContact>>((ref) {
  return ref.watch(bankingApiProvider).yapeContacts();
});

final mobileOperatorsProvider = FutureProvider<List<MobileOperator>>((ref) {
  return ref.watch(bankingApiProvider).mobileOperators();
});

class BankingApi {
  BankingApi(this._dio);
  final Dio _dio;

  Future<HomeSummary> homeSummary() async {
    final response = await _dio.get('/api/v1/accounts/home-summary');
    final data = response.data['data'] ?? response.data;
    return HomeSummary.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<AccountSummary>> accounts() async {
    final response = await _dio.get('/api/v1/accounts');
    final items = (response.data['data'] ?? response.data) as List<dynamic>;
    return items
        .map((e) => AccountSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<AccountMovement>> movements() async {
    final response = await _dio.get('/api/v1/accounts/movements');
    final items = (response.data['data'] ?? response.data) as List<dynamic>;
    return items
        .map((e) => AccountMovement.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<TransferBank>> transferBanks() async {
    final response = await _dio.get('/api/v1/transfers/banks');
    final items = (response.data['data'] ?? response.data) as List<dynamic>;
    return items
        .map((e) => TransferBank.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<OperationReceipt> createTransfer({
    required String originAccount,
    required String destinationAccount,
    required String destinationBankCode,
    required double amount,
    required String currency,
    required String description,
  }) async {
    final response = await _dio.post(
      '/api/v1/transfers',
      data: {
        'originAccount': originAccount,
        'destinationAccount': destinationAccount,
        'destinationBankCode': destinationBankCode,
        'amount': amount,
        'currency': currency,
        'description': description,
      },
    );
    final data = response.data['data'] ?? response.data;
    return OperationReceipt.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<ServiceBill>> services() async {
    final response = await _dio.get('/api/v1/payments/services');
    final items = (response.data['data'] ?? response.data) as List<dynamic>;
    return items
        .map((e) => ServiceBill.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<OperationReceipt> payService({
    required String accountNumber,
    required String serviceCode,
    required double amount,
  }) async {
    final response = await _dio.post(
      '/api/v1/payments',
      data: {
        'accountNumber': accountNumber,
        'serviceCode': serviceCode,
        'amount': amount,
      },
    );
    final data = response.data['data'] ?? response.data;
    return OperationReceipt.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<YapeContact>> yapeContacts() async {
    final response = await _dio.get('/api/v1/payments/yape-contacts');
    final items = (response.data['data'] ?? response.data) as List<dynamic>;
    return items
        .map((e) => YapeContact.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<OperationReceipt> payYape({
    required String originAccount,
    required String phone,
    required double amount,
  }) async {
    final response = await _dio.post(
      '/api/v1/payments/yape',
      data: {
        'originAccount': originAccount,
        'phone': phone,
        'amount': amount,
      },
    );
    final data = response.data['data'] ?? response.data;
    return OperationReceipt.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<MobileOperator>> mobileOperators() async {
    final response = await _dio.get('/api/v1/payments/mobile-operators');
    final items = (response.data['data'] ?? response.data) as List<dynamic>;
    return items
        .map((e) => MobileOperator.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<OperationReceipt> rechargeMobile({
    required String originAccount,
    required String operatorCode,
    required String phone,
    required double amount,
  }) async {
    final response = await _dio.post(
      '/api/v1/payments/recharges',
      data: {
        'originAccount': originAccount,
        'operatorCode': operatorCode,
        'phone': phone,
        'amount': amount,
      },
    );
    final data = response.data['data'] ?? response.data;
    return OperationReceipt.fromJson(Map<String, dynamic>.from(data));
  }
}
