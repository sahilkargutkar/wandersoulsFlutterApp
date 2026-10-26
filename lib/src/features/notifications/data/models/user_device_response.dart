class UserDeviceResponse {
  final String? id;
  final String? platform;
  final bool isActive;
  final DateTime? updatedAt;

  const UserDeviceResponse({
    this.id,
    this.platform,
    this.isActive = true,
    this.updatedAt,
  });

  factory UserDeviceResponse.fromJson(Map<String, dynamic> json) {
    return UserDeviceResponse(
      id: json['id'] as String?,
      platform: json['platform'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform,
      'isActive': isActive,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
