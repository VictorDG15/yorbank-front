import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/api_client.dart';
import '../../../core/result/result.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(tokenStorageProvider),
  );
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._repository, this._tokenStorage)
      : super(const AsyncData(null));

  final AuthRepository _repository;
  final dynamic _tokenStorage;
  CancelToken? _pendingRequest;
  int _requestVersion = 0;

  void cancelPending() {
    _requestVersion++;
    _pendingRequest?.cancel('request cancelled');
    _pendingRequest = null;
    state = const AsyncData(null);
  }

  Future<LoginChallenge?> prepareLogin({
    required String segment,
    required String documentType,
    required String documentNumber,
    required String cardNumber,
  }) async {
    final version = ++_requestVersion;
    _pendingRequest?.cancel('new prepare request');
    final cancelToken = CancelToken();
    _pendingRequest = cancelToken;
    state = const AsyncLoading();
    final result = await _repository.prepareLogin(
      segment: segment,
      documentType: documentType,
      documentNumber: documentNumber,
      cardNumber: cardNumber,
      cancelToken: cancelToken,
    );
    if (version != _requestVersion || cancelToken.isCancelled) {
      if (version == _requestVersion) state = const AsyncData(null);
      return null;
    }
    _pendingRequest = null;

    switch (result) {
      case Success(data: final challenge):
        state = const AsyncData(null);
        return challenge;
      case Failure(message: final message):
        state = AsyncError(message, StackTrace.current);
        return null;
    }
  }

  Future<bool> login({
    required LoginChallenge challenge,
    required String password,
  }) async {
    final version = ++_requestVersion;
    _pendingRequest?.cancel('new login request');
    final cancelToken = CancelToken();
    _pendingRequest = cancelToken;
    state = const AsyncLoading();
    final result = await _repository.login(
      challenge: challenge,
      password: password,
      cancelToken: cancelToken,
    );
    if (version != _requestVersion || cancelToken.isCancelled) {
      if (version == _requestVersion) state = const AsyncData(null);
      return false;
    }
    _pendingRequest = null;

    switch (result) {
      case Success(data: final session):
        await _tokenStorage.save(session.accessToken, session.refreshToken);
        state = const AsyncData(null);
        return true;
      case Failure(message: final message):
        state = AsyncError(message, StackTrace.current);
        return false;
    }
  }

  Future<void> logout() async => _tokenStorage.clear();

  @override
  void dispose() {
    _pendingRequest?.cancel('controller disposed');
    super.dispose();
  }
}
