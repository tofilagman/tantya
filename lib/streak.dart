/// "Streak" signal (from the users' trading group): on a low timeframe (e.g. 3m) several
/// candles in a row of one colour with MACD moving the same way, confirmed when the higher
/// timeframe (e.g. 15m) also shows candles in a row of that colour. Red = expect a drop,
/// green = expect a rise.
///
/// Causal: the higher-timeframe candles are built from the low-timeframe candles up to
/// the signal, so the confirming candle is the one still forming at that moment, exactly
/// what a trader switching charts would see.
library;

import 'candles.dart';
import 'indicators.dart';

class StreakConfig {
  const StreakConfig({this.lowRun = 3, this.highRun = 2, this.factor = 5, this.macd = true, this.confirm = true});

  /// Candles in a row on the low timeframe.
  final int lowRun;

  /// Candles in a row on the higher timeframe, counting the one still forming.
  final int highRun;

  /// Low-timeframe candles per higher-timeframe candle (3m → 15m = 5).
  final int factor;

  /// Require the MACD histogram on the move's side of zero and growing that way.
  final bool macd;

  /// Require the higher-timeframe confirmation.
  final bool confirm;
}

class StreakSignal {
  const StreakSignal(this.index, this.dir, this.extreme);

  /// Low-timeframe candle the signal fires on (at its close).
  final int index;

  /// −1 drop, +1 rise.
  final int dir;

  /// The streak's high (drop) or low (rise): the trade is wrong past it.
  final double extreme;
}

int _colour(Candle c) => c.close > c.open ? 1 : c.close < c.open ? -1 : 0;

/// Higher-timeframe candles as they stood at the close of low-timeframe candle [i]:
/// closed ones before it plus the one still forming. Newest last.
List<Candle> htfAt(List<Candle> low, int i, Duration size, {int count = 4}) {
  final out = <Candle>[];
  final ms = size.inMilliseconds;
  int bucket(Candle c) => c.start.millisecondsSinceEpoch ~/ ms;
  var j = i;
  while (j >= 0 && out.length < count) {
    final b = bucket(low[j]);
    var k = j;
    while (k - 1 >= 0 && bucket(low[k - 1]) == b) {
      k--;
    }
    var hi = low[k].high, lo = low[k].low;
    for (var m = k + 1; m <= j; m++) {
      if (low[m].high > hi) hi = low[m].high;
      if (low[m].low < lo) lo = low[m].low;
    }
    out.insert(0, Candle(DateTime.fromMillisecondsSinceEpoch(b * ms, isUtc: true), low[k].open, hi, lo, low[j].close));
    j = k - 1;
  }
  return out;
}

/// Every streak signal in [low] (oldest first), firing once per streak: on the first
/// candle where all conditions hold.
List<StreakSignal> detectStreaks(List<Candle> low, Duration lowSize, {StreakConfig cfg = const StreakConfig()}) {
  final hist = Macd.of(low).histogram;
  final out = <StreakSignal>[];
  final highSize = lowSize * cfg.factor;
  var lastDir = 0, lastAt = -1000;
  for (var i = cfg.lowRun; i < low.length; i++) {
    final dir = _colour(low[i]);
    if (dir == 0) continue;
    var run = 0;
    for (var j = i; j >= 0 && _colour(low[j]) == dir; j--) {
      run++;
    }
    if (run < cfg.lowRun) continue;
    // One signal per streak.
    if (dir == lastDir && lastAt >= i - run + 1) continue;
    if (cfg.macd) {
      final h = hist[i], p = hist[i - 1];
      if (h == null || p == null || h * dir <= 0 || (h - p) * dir <= 0) continue;
    }
    if (cfg.confirm) {
      final htf = htfAt(low, i, highSize, count: cfg.highRun);
      if (htf.length < cfg.highRun || htf.any((c) => _colour(c) != dir)) continue;
    }
    var extreme = dir < 0 ? low[i].high : low[i].low;
    for (var j = i - run + 1; j <= i; j++) {
      extreme = dir < 0 ? (low[j].high > extreme ? low[j].high : extreme) : (low[j].low < extreme ? low[j].low : extreme);
    }
    out.add(StreakSignal(i, dir, extreme));
    lastDir = dir;
    lastAt = i;
  }
  return out;
}
