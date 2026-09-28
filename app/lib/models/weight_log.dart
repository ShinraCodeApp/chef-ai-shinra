class WeightLog {
  final double weightKg;
  final String recordedAt;

  WeightLog({required this.weightKg, required this.recordedAt});

  factory WeightLog.fromJson(Map<String, dynamic> json) => WeightLog(
        weightKg: (json['weightKg'] as num).toDouble(),
        recordedAt: json['recordedAt'] as String,
      );
}
