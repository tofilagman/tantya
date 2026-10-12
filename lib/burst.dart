/// Momentum bursts: the footprint of a fast, heavy move (the users call it "riding
/// with the whale"): within a few candles, volume spikes, the MACD histogram jumps
/// far outside its normal range, RSI moves sharply and the fast EMA twists through
/// the slower ones.
///
/// It detects the pattern, not intent: news, liquidations and breakouts make the
/// same footprint, and bursts often reverse. [burstStats] measures, on past data,
/// how often a burst continued versus reversed.
///
/// Everything here is causal: the reading at candle i uses only candles ≤ i, so
/// scanning past data has no look-ahead.
library;

import 'dart:math' as math;

import 'candles.dart';
import 'indicators.dart';

class BurstConfig {
  const BurstConfig({
    this.window = 5,
    this.volumeSpike = 3.0,
    this.macdSigma = 2.5,
    this.rsiJump = 15,
    this.minSignals = 2,
  });

  /// Candles a burst unfolds over.
  final int window;

  /// Volume at least this many times the 50-candle average, somewhere in the window.
  final double volumeSpike;

  /// MACD histogram at least this many standard deviations from its recent norm.
  final double macdSigma;

  /// RSI move over the window, in points.
  final double rsiJump;

  /// Besides the volume spike (required), how many of MACD / RSI / EMA twist must fire.
  final int minSignals;
}

class BurstEvent {
  const BurstEvent({
    required this.index,
    required this.dir,
    required this.volumeRatio,
    required this.macdZ,
    required this.rsiMove,
    required this.emaTwist,
    required this.macdFired,
    required this.rsiFired,
    required this.origin,
  });

  /// Candle the burst was confirmed on.
  final int index;

  /// +1 up, −1 down.
  final int dir;

  /// Peak volume in the window ÷ the 50-candle average before it.
  final double volumeRatio;

  /// MACD histogram in standard deviations (signed).
  final double macdZ;

  /// RSI change over the window (signed points).
  final double rsiMove;

  /// Fast EMA 3 crossed both EMA 25 and EMA 50 in the burst's direction.
  final bool emaTwist;

  /// Where the burst started: the window's low (up burst) or high (down burst).
  /// Price back through here means the burst failed.
  final double origin;

  /// Which momentum signals passed their thresholds (the volume spike always did).
  final bool macdFired, rsiFired;

  /// Signals that fired, of 4 (volume + MACD + RSI + EMA twist).
  int get strength => 1 + (macdFired ? 1 : 0) + (rsiFired ? 1 : 0) + (emaTwist ? 1 : 0);
}

/// Every burst in [candles], oldest first. After one fires, the same direction can't fire
/// again for [BurstConfig.window] candles (one burst, not five).
List<BurstEvent> detectBursts(List<Candle> candles, Indicators ind, {BurstConfig cfg = const BurstConfig()}) {
  final out = <BurstEvent>[];
  final w = cfg.window;
  final hist = ind.macd.histogram;
  final e3 = ind.emas[3]!, e25 = ind.ema25, e50 = ind.ema50;
  var lastAt = -1000, lastDir = 0;
  const volLookback = 50, histLookback = 100;

  for (var i = math.max(volLookback + w, 60); i < candles.length; i++) {
    // Volume spike: the heaviest candle in the window vs the 50 candles before it.
    var avg = 0.0;
    for (var j = i - w - volLookback + 1; j <= i - w; j++) {
      avg += candles[j].volume;
    }
    avg /= volLookback;
    if (avg <= 0) continue;
    var peak = 0.0;
    for (var j = i - w + 1; j <= i; j++) {
      peak = math.max(peak, candles[j].volume);
    }
    final volRatio = peak / avg;
    if (volRatio < cfg.volumeSpike) continue;

    // Direction: the move over the window.
    final move = candles[i].close - candles[i - w].close;
    if (move == 0) continue;
    final dir = move > 0 ? 1 : -1;
    if (dir == lastDir && i - lastAt <= w) continue;

    // MACD histogram vs its own recent spread (before the window).
    var macdZ = 0.0;
    final h = hist[i];
    if (h != null) {
      final past = [for (var j = math.max(0, i - w - histLookback); j <= i - w; j++) ?hist[j]];
      if (past.length >= 30) {
        final mean = past.reduce((a, b) => a + b) / past.length;
        final sd = math.sqrt(past.fold(0.0, (t, v) => t + (v - mean) * (v - mean)) / past.length);
        if (sd > 0) macdZ = (h - mean) / sd;
      }
    }
    final macdOk = macdZ.abs() >= cfg.macdSigma && macdZ.sign == dir;

    // RSI move over the window.
    final r0 = ind.rsi14[i - w], r1 = ind.rsi14[i];
    final rsiMove = r0 == null || r1 == null ? 0.0 : r1 - r0;
    final rsiOk = rsiMove.abs() >= cfg.rsiJump && rsiMove.sign == dir;

    // EMA twist: EMA 3 was on the other side of EMA 25 or 50 at the window's start and
    // is now beyond both in the burst's direction.
    bool beyond(int j) {
      final a = e3[j], b = e25[j], c = e50[j];
      if (a == null || b == null || c == null) return false;
      return dir > 0 ? a > b && a > c : a < b && a < c;
    }
    final twist = beyond(i) && !beyond(i - w);

    final signals = (macdOk ? 1 : 0) + (rsiOk ? 1 : 0) + (twist ? 1 : 0);
    if (signals < cfg.minSignals) continue;

    var origin = dir > 0 ? double.infinity : -double.infinity;
    for (var j = i - w; j <= i; j++) {
      origin = dir > 0 ? math.min(origin, candles[j].low) : math.max(origin, candles[j].high);
    }
    out.add(BurstEvent(
      index: i,
      dir: dir,
      volumeRatio: volRatio,
      macdZ: macdZ,
      rsiMove: rsiMove,
      emaTwist: twist,
      macdFired: macdOk,
      rsiFired: rsiOk,
      origin: origin,
    ));
    lastAt = i;
    lastDir = dir;
  }
  return out;
}

/// What happened after one burst, entering at its candle's close.
class BurstOutcome {
  BurstOutcome(this.event, this.forward, this.result);
  final BurstEvent event;

  /// Return in the burst's direction after each horizon (fraction; +0.02 = +2%), or
  /// null if the data ends before it.
  final Map<int, double?> forward;

  /// The "ride the whale" trade: stop at the burst's origin, target 2× that risk,
  /// closed after [BurstStats.tradeExpiry] candles. Null if the data ends first.
  final double? result;
}

class BurstStats {
  BurstStats(this.outcomes);

  static const horizons = [3, 12, 24];
  static const tradeExpiry = 24;
  static const targetR = 2.0;

  final List<BurstOutcome> outcomes;

  int get count => outcomes.length;

  /// Share of bursts whose price had moved further in the burst's direction after [h].
  double? continuation(int h) {
    final v = [for (final o in outcomes) ?o.forward[h]];
    return v.isEmpty ? null : v.where((x) => x > 0).length / v.length;
  }

  double? avgForward(int h) {
    final v = [for (final o in outcomes) ?o.forward[h]];
    return v.isEmpty ? null : v.reduce((a, b) => a + b) / v.length;
  }

  List<double> get trades => [for (final o in outcomes) ?o.result];
  double? get tradeWinRate => trades.isEmpty ? null : trades.where((r) => r > 0).length / trades.length;
  double? get tradeAvgR => trades.isEmpty ? null : trades.reduce((a, b) => a + b) / trades.length;

  BurstStats where(bool Function(BurstEvent) test) =>
      BurstStats(outcomes.where((o) => test(o.event)).toList());
}

/// Measures every burst in [candles]: forward returns at each horizon, and the trade.
BurstStats burstStats(List<Candle> candles, List<BurstEvent> events) {
  final out = <BurstOutcome>[];
  for (final e in events) {
    final entry = candles[e.index].close;
    final forward = <int, double?>{
      for (final h in BurstStats.horizons)
        h: e.index + h < candles.length ? e.dir * (candles[e.index + h].close - entry) / entry : null,
    };

    final risk = (entry - e.origin).abs();
    double? result;
    if (risk > 0) {
      final stop = e.origin, target = entry + e.dir * BurstStats.targetR * risk;
      for (var j = e.index + 1; j <= e.index + BurstStats.tradeExpiry && j < candles.length; j++) {
        final c = candles[j];
        // Same conservative rule as setups: a candle touching both counts as the stop.
        if (e.dir > 0 ? c.low <= stop : c.high >= stop) {
          result = -1;
          break;
        }
        if (e.dir > 0 ? c.high >= target : c.low <= target) {
          result = BurstStats.targetR;
          break;
        }
      }
      if (result == null && e.index + BurstStats.tradeExpiry < candles.length) {
        result = e.dir * (candles[e.index + BurstStats.tradeExpiry].close - entry) / risk;
      }
    }
    out.add(BurstOutcome(e, forward, result));
  }
  return BurstStats(out);
}
