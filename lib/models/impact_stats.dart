class ImpactStats {
  final double totalWasteRecycled;
  final double totalCO2Saved;
  final double carbonCredits;

  const ImpactStats({
    required this.totalWasteRecycled,
    required this.totalCO2Saved,
    required this.carbonCredits,
  });

  factory ImpactStats.fromMap(Map<String, dynamic> map) {
    return ImpactStats(
      totalWasteRecycled: (map['totalWasteRecycled'] as num?)?.toDouble() ?? 0,
      totalCO2Saved: (map['totalCO2Saved'] as num?)?.toDouble() ?? 0,
      carbonCredits: (map['carbonCredits'] as num?)?.toDouble() ?? 0,
    );
  }
}
