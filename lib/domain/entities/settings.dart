import '../../money/enums.dart';

class Settings {
  final double extraSavingPercent; // 0–100
  final RoundingMode rounding;

  const Settings({
    this.extraSavingPercent = 0,
    this.rounding = RoundingMode.none,
  });

  Settings copyWith({
    double? extraSavingPercent,
    RoundingMode? rounding,
  }) =>
      Settings(
        extraSavingPercent: extraSavingPercent ?? this.extraSavingPercent,
        rounding: rounding ?? this.rounding,
      );
}
