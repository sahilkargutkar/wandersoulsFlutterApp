class RegisterDeviceRequest {
  final String fcmToken;
  final String platform;

  const RegisterDeviceRequest({
    required this.fcmToken,
    required this.platform,
  });

  factory RegisterDeviceRequest.fromJson(Map<String, dynamic> json) {
    return RegisterDeviceRequest(
      fcmToken: json['fcmToken'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fcmToken': fcmToken,
      'platform': platform,
    };
  }
}
