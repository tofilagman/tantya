/// A trade plan read off a wave count, and the shared settlement constants. Pure Dart
/// (no Flutter), so the server-side track record can use the exact same rules as the app.
library;

import 'candles.dart';
import 'elliott.dart';

enum Side { long, short }

/// The stop sits this many ATR(14) beyond the invalidation level.
const stopBufferAtr = 0.5;

/// Tracked setups that hit neither level within this many candles expire.
const expiryCandles = 50;

/// A trade plan read off one wave count: enter at the current price, stop where the
/// count is wrong, take profit at the Fibonacci target zone.
class TradeSetup {
  TradeSetup({
    required this.side,
    required this.entry,
    required this.stop,
    required this.tp1,
    required this.tp2,
    required this.scenario,
  });

  final Side side;
  final double entry;
  final double stop;
  final double tp1;
  final double tp2;
  final Scenario scenario;

  double get risk => (entry - stop).abs();
  double get rr1 => risk == 0 ? 0 : (tp1 - entry).abs() / risk;
  double get rr2 => risk == 0 ? 0 : (tp2 - entry).abs() / risk;

  /// Reward:risk under 1 to the first target isn't worth taking at this price.
  bool get poorRR => rr1 < 1;

  /// Null when the count can't produce a coherent trade at [price] (e.g. price is
  /// already past the first target, or sitting on the stop).
  ///
  /// [buffer] moves the stop that far beyond the invalidation level, so ordinary
  /// noise (a wick through the exact wave extreme) doesn't take the trade out.
  static TradeSetup? from(Scenario s, double price, {double buffer = 0}) {
    final side = s.direction > 0 ? Side.long : Side.short;
    final d = s.direction;
    final tp1 = d > 0 ? s.targetLow : s.targetHigh;
    final tp2 = d > 0 ? s.targetHigh : s.targetLow;
    final stop = s.stop - d * buffer;
    if (d * (tp1 - price) <= 0) return null; // first target already reached
    if (d * (price - stop) <= 0) return null; // at or through the stop
    return TradeSetup(side: side, entry: price, stop: stop, tp1: tp1, tp2: tp2, scenario: s);
  }
}

enum SetupStatus { open, target, stopped, expired }

/// Average true range over the last [period] candles — the typical candle's span.
double atr(List<Candle> candles, {int period = 14}) {
  if (candles.length < 2) return 0;
  final from = candles.length > period ? candles.length - period : 1;
  var sum = 0.0;
  for (var i = from; i < candles.length; i++) {
    final c = candles[i], prev = candles[i - 1].close;
    sum += [c.high - c.low, (c.high - prev).abs(), (c.low - prev).abs()].reduce((a, b) => a > b ? a : b);
  }
  return sum / (candles.length - from);
}

