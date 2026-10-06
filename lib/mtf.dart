/// Multi-timeframe agreement: does the bigger picture point the same way as a setup?
library;

import 'candles.dart';
import 'elliott.dart';
import 'setup.dart';

enum HtfVerdict { agree, conflict, unknown }

/// The higher timeframe's reading for one setup.
class HtfCheck {
  const HtfCheck(this.frame, this.primary, this.verdict);

  final Timeframe frame;

  /// The higher timeframe's primary count; null when it has none.
  final Scenario? primary;
  final HtfVerdict verdict;

  /// Ranking multiplier: agreement keeps full weight, a conflict costs 40%.
  double get rankFactor => switch (verdict) {
        HtfVerdict.agree => 1.0,
        HtfVerdict.unknown => 0.85,
        HtfVerdict.conflict => 0.6,
      };

  /// Compares the setup's direction with the wave the higher timeframe has in progress.
  /// A long 1h setup "agrees" when the 4h primary count also expects price to rise.
  static HtfCheck judge(Side side, Timeframe frame, EwAnalysis? higher) {
    final p = higher?.primary;
    if (p == null) return HtfCheck(frame, null, HtfVerdict.unknown);
    final up = side == Side.long;
    return HtfCheck(frame, p, (p.direction > 0) == up ? HtfVerdict.agree : HtfVerdict.conflict);
  }
}
