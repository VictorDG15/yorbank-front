class AuthSession {
  const AuthSession({required this.accessToken, required this.refreshToken, required this.customerName});
  final String accessToken;
  final String refreshToken;
  final String customerName;
}
