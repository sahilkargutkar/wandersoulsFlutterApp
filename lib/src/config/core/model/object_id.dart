class Id {
  final int timestamp;
  final DateTime creationTime;
  const Id({required this.timestamp, required this.creationTime});

  factory Id.fromJson(Map<String, dynamic> json) {
    return Id(
      timestamp: json['timestamp'],
      creationTime: DateTime.parse(json['creationTime']),
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'creationTime': creationTime.toIso8601String(),
  };
}
