// lib/domain/entities/settings.dart
import '../../money/enums.dart';

class Settings {
  final double extraSavingPercent; // 0–100
  final RoundingMode rounding;

  // Nuevos campos para recordatorios
  final bool remindersEnabled;
  final int reminderHour;   // 0..23
  final int reminderMinute; // 0..59

  const Settings({
    this.extraSavingPercent = 0,
    this.rounding = RoundingMode.none,
    this.remindersEnabled = false,
    this.reminderHour = 9,
    this.reminderMinute = 0,
  });

  Settings copyWith({
    double? extraSavingPercent,
    RoundingMode? rounding,
    bool? remindersEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) =>
      Settings(
        extraSavingPercent: extraSavingPercent ?? this.extraSavingPercent,
        rounding: rounding ?? this.rounding,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
      );

  Map<String, dynamic> toMap() => {
        'extraSavingPercent': extraSavingPercent,
        'rounding': rounding.name,
        'remindersEnabled': remindersEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
      };

  static Settings fromMap(Map<String, dynamic> m) {
    return Settings(
      extraSavingPercent: (m['extraSavingPercent'] ?? 0).toDouble(),
      rounding: RoundingMode.values.firstWhere(
        (r) => r.name == (m['rounding'] ?? RoundingMode.none.name),
      ),
      remindersEnabled: (m['remindersEnabled'] ?? false) as bool,
      reminderHour: (m['reminderHour'] ?? 9) as int,
      reminderMinute: (m['reminderMinute'] ?? 0) as int,
    );
  }
}
