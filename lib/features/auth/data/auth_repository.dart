import 'package:dio/dio.dart';

import '../../../core/http/api_client.dart';
import '../../../core/result/result.dart';
import '../domain/auth_session.dart';

class LoginChallenge {
  const LoginChallenge({
    required this.segment,
    required this.documentType,
    required this.documentNumber,
    required this.cardNumber,
    required this.maskedCard,
    required this.cardType,
  });

  final String segment;
  final String documentType;
  final String documentNumber;
  final String cardNumber;
  final String maskedCard;
  final String cardType;
}

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<Result<LoginChallenge>> prepareLogin({
    required String segment,
    required String documentType,
    required String documentNumber,
    required String cardNumber,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/login/prepare',
        data: {
          'segment': segment,
          'documentType': documentType,
          'documentNumber': documentNumber,
          'cardNumber': cardNumber,
        },
        cancelToken: cancelToken,
      );
      final data = response.data['data'] ?? response.data;
      return Success(
        LoginChallenge(
          segment: data['segment'] ?? segment,
          documentType: data['documentType'] ?? documentType,
          documentNumber: data['documentNumber'] ?? documentNumber,
          cardNumber: cardNumber,
          maskedCard: data['maskedCard'] ?? _maskCard(cardNumber),
          cardType: data['cardType'] ?? 'Tarjeta YBank',
        ),
      );
    } on DioException catch (e) {
      return Failure(_messageFromDio(e, 'No se pudo validar la tarjeta'));
    }
  }

  Future<Result<AuthSession>> login({
    required LoginChallenge challenge,
    required String password,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/login',
        data: {
          'segment': challenge.segment,
          'documentType': challenge.documentType,
          'documentNumber': challenge.documentNumber,
          'cardNumber': challenge.cardNumber,
          'password': password,
        },
        cancelToken: cancelToken,
      );
      final data = response.data['data'] ?? response.data;
      return Success(
        AuthSession(
          accessToken: data['accessToken'] ?? data['token'] ?? '',
          refreshToken: data['refreshToken'] ?? '',
          customerName: data['customerName'] ?? 'Cliente YBank',
        ),
      );
    } on DioException catch (e) {
      return Failure(_messageFromDio(e, 'No se pudo iniciar sesion'));
    }
  }

  Future<Result<void>> verifyOtp(String code) async {
    if (code == '123456') return const Success(null);
    return const Failure('Codigo invalido');
  }

  String _maskCard(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return '**** $digits';
    return '**** **** **** ${digits.substring(digits.length - 4)}';
  }

  String _messageFromDio(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'No hay conexion con el backend. Revisa WiFi, firewall o IP $apiBaseUrl';
      default:
        return fallback;
    }
  }
}
