class ThresholdRule {
  final String id;
  final int percentage;
  final String label;
  final bool isEnabled;
  final String soundType;
  final String? customSoundPath;

  const ThresholdRule({
    required this.id,
    required this.percentage,
    required this.label,
    this.isEnabled = true,
    this.soundType = 'siren',
    this.customSoundPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'percentage': percentage,
      'label': label,
      'isEnabled': isEnabled,
      'soundType': soundType,
      'customSoundPath': customSoundPath,
    };
  }

  factory ThresholdRule.fromJson(Map<String, dynamic> json) {
    return ThresholdRule(
      id: json['id'] as String,
      percentage: (json['percentage'] as num).toInt(),
      label: json['label'] as String? ?? 'Threshold',
      isEnabled: json['isEnabled'] as bool? ?? true,
      soundType: json['soundType'] as String? ?? 'siren',
      customSoundPath: json['customSoundPath'] as String?,
    );
  }

  ThresholdRule copyWith({
    String? id,
    int? percentage,
    String? label,
    bool? isEnabled,
    String? soundType,
    String? customSoundPath,
  }) {
    return ThresholdRule(
      id: id ?? this.id,
      percentage: percentage ?? this.percentage,
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
      soundType: soundType ?? this.soundType,
      customSoundPath: customSoundPath ?? this.customSoundPath,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThresholdRule &&
        other.id == id &&
        other.percentage == percentage &&
        other.label == label &&
        other.isEnabled == isEnabled &&
        other.soundType == soundType &&
        other.customSoundPath == customSoundPath;
  }

  @override
  int get hashCode =>
      Object.hash(id, percentage, label, isEnabled, soundType, customSoundPath);
}
