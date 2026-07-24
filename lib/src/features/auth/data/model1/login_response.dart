class LoginResponse {
  final String userId;
  final String token;

  LoginResponse({required this.userId, required this.token});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(userId: json["userId"], token: json["token"]);
  }
}
