/// Backtest: replay the app's own setups over past candles and settle them, to see
/// how the method would have done before trusting it with real money.
///
/// No look-ahead: at each candle the engine sees only the [BacktestConfig.window]
/// candles up to and including it, exactly as the live chart would have. A setup
/// is "entered" at that candle's close and settled on the following candles with the
/// same rules as tracked setups: whichever of TP1 or the stop is touched first; a
/// candle spanning both counts as the stop; after [expiryCandles] it closes at the
/// market. One trade at a time; the next is looked for after the previous closes.
/// Not modelled: fees, funding, slippage, partial fills.
library;

import 'dart:math' as math;

import 'candles.dart';
import 'elliott.dart';
import 'evidence.dart';
import 'indicators.dart';
import 'setup.dart';

class BacktestConfig {
  const BacktestConfig({
    this.window = 300,
    this.minRR = 1.0,
    this.minScore = 0,
    this.minEvidence,
    this.minAdx,
    this.bounds,
  });

  /// Candles the engine sees at each step (the live chart's 300).
  final int window;

  /// Skip setups whose reward:risk to TP1 is below this.
  final double minRR;

  /// Skip counts scoring below this (0..1).
  final double minScore;

  /// Skip setups whose evidence ratio (0..1) is below this; null = no filter.
  final double? minEvidence;

  /// Skip setups taken while ADX(14) is below this (a range, where waves tend to fail);
  /// null = no filter.
  final double? minAdx;
  final (double, double)? bounds;
}

/// One simulated trade. Plain data, so it can cross isolates.
class BacktestTrade {
  BacktestTrade({
    required this.entryIndex,
    required this.madeAt,
    required this.side,
    required this.entry,
    required this.stop,
    required this.tp1,
    required this.tp2,
    required this.count,
    required this.wave,
    required this.score,
    required this.evidence,
    required this.macd,
    this.adx,
  });

  final int entryIndex;
  final DateTime madeAt;
  final Side side;
  final double entry, stop, tp1, tp2;

  /// e.g. "Impulse ↑ · wave 3 in progress".
  final String count;

  /// The wave the setup traded, e.g. '3'.
  final String wave;
  final double score;
  final double? evidence;
  final MacdVerdict? macd;

  /// ADX(14) at entry: trend strength.
  final double? adx;

  SetupStatus status = SetupStatus.open;
  double? exit;
  int? exitIndex;

  double get risk => (entry - stop).abs();
  double? get r => exit == null || risk == 0 ? null : (side == Side.long ? exit! - entry : entry - exit!) / risk;
}

class BacktestResult {
  BacktestResult(this.trades, {required this.candles, required this.from, required this.to, required this.steps});

  /// Closed trades, oldest first (a trade still open at the end is left out).
  final List<BacktestTrade> trades;
  final int candles;
  final DateTime from, to;

  /// Candles where the engine looked for a setup.
  final int steps;

  int get wins => trades.where((t) => t.status == SetupStatus.target).length;
  int get losses => trades.where((t) => t.status == SetupStatus.stopped).length;
  int get expired => trades.where((t) => t.status == SetupStatus.expired).length;
  double? get hitRate => wins + losses == 0 ? null : wins / (wins + losses);
  double get totalR => trades.fold(0.0, (t, x) => t + (x.r ?? 0));
  double? get avgR => trades.isEmpty ? null : totalR / trades.length;

  /// Running total of R after each trade.
  List<double> get equity {
    var e = 0.0;
    return [for (final t in trades) e += t.r ?? 0];
  }

  /// Largest fall from a running peak, in R (≥ 0).
  double get maxDrawdownR {
    var peak = 0.0, worst = 0.0, e = 0.0;
    for (final t in trades) {
      e += t.r ?? 0;
      peak = math.max(peak, e);
      worst = math.max(worst, peak - e);
    }
    return worst;
  }

  int get longestLosingStreak {
    var run = 0, best = 0;
    for (final t in trades) {
      run = (t.r ?? 0) < 0 ? run + 1 : 0;
      best = math.max(best, run);
    }
    return best;
  }

  /// Results grouped by [key], in the order of [order]; groups without trades are left out.
  Map<K, BacktestResult> groupBy<K>(K? Function(BacktestTrade) key, Iterable<K> order) => {
        for (final k in order)
          if (trades.any((t) => key(t) == k))
            k: BacktestResult(trades.where((t) => key(t) == k).toList(),
                candles: candles, from: from, to: to, steps: steps),
      };
}

/// Runs the backtest over [candles] (oldest first). Pure and synchronous: call it via
/// `Isolate.run` from the UI. [onProgress] reports the share of candles done.
BacktestResult runBacktest(List<Candle> candles, Timeframe frame, BacktestConfig cfg,
    {void Function(double)? onProgress}) {
  final trades = <BacktestTrade>[];
  final w = cfg.window;
  var steps = 0;
  var t = w - 1;
  while (t < candles.length - 1) {
    if (onProgress != null && t % 50 == 0) onProgress((t - w + 1) / math.max(1, candles.length - w));
    final view = candles.sublist(t - w + 1, t + 1);
    steps++;
    final trade = _setupAt(view, t, cfg);
    if (trade == null) {
      t++;
      continue;
    }
    settleTrade(trade, candles);
    if (trade.status == SetupStatus.open) break; // ran out of data before it closed
    trades.add(trade);
    t = trade.exitIndex! + 1;
  }
  return BacktestResult(
    trades,
    candles: candles.length,
    from: candles.isEmpty ? DateTime(0) : candles[math.min(w - 1, candles.length - 1)].start,
    to: candles.isEmpty ? DateTime(0) : candles.last.start,
    steps: steps,
  );
}

/// The setup the live app would have shown on [view], or null if none passes the filters.
BacktestTrade? _setupAt(List<Candle> view, int index, BacktestConfig cfg) {
  final a = analyze(view, bounds: cfg.bounds);
  final s = a.primary;
  if (s == null || s.score < cfg.minScore) return null;
  final price = view.last.close;
  final setup = TradeSetup.from(s, price, buffer: atr(view) * stopBufferAtr);
  if (setup == null || setup.rr1 < cfg.minRR) return null;
  final ind = Indicators.of(view);
  final evidence = evidenceReport(s, ind).ratio;
  final adxNow = ind.adx14.last;
  if (cfg.minEvidence != null && (evidence ?? 0) < cfg.minEvidence!) return null;
  if (cfg.minAdx != null && (adxNow ?? 0) < cfg.minAdx!) return null;
  return BacktestTrade(
    entryIndex: index,
    madeAt: view.last.start,
    side: setup.side,
    entry: setup.entry,
    stop: setup.stop,
    tp1: setup.tp1,
    tp2: setup.tp2,
    count: s.title,
    wave: s.next == 'new trend' ? '1' : s.next,
    score: s.score,
    evidence: evidence,
    macd: MacdState.of(ind.macd)?.verdictFor(setup.side),
    adx: adxNow,
  );
}

/// Same rules as [TrackedSetup.resolve], on the candles after entry.
void settleTrade(BacktestTrade tr, List<Candle> candles) {
  final long = tr.side == Side.long;
  final last = math.min(candles.length - 1, tr.entryIndex + expiryCandles);
  for (var i = tr.entryIndex + 1; i <= last; i++) {
    final c = candles[i];
    if (long ? c.low <= tr.stop : c.high >= tr.stop) {
      tr
        ..status = SetupStatus.stopped
        ..exit = tr.stop
        ..exitIndex = i;
      return;
    }
    if (long ? c.high >= tr.tp1 : c.low <= tr.tp1) {
      tr
        ..status = SetupStatus.target
        ..exit = tr.tp1
        ..exitIndex = i;
      return;
    }
  }
  if (tr.entryIndex + expiryCandles <= candles.length - 1) {
    tr
      ..status = SetupStatus.expired
      ..exit = candles[last].close
      ..exitIndex = last;
  }
}
