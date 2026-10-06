import 'dart:async';
import 'dart:math' as math;

import 'candles.dart';
import 'elliott.dart';
import 'mtf.dart';
import 'setup.dart';
import 'sources/binance.dart';

/// One pair's best setup on the scanned timeframe.
class ScanResult {
  ScanResult({
    required this.ticker,
    required this.analysis,
    required this.setup,
    required this.progress,
    required this.baseRank,
    this.htf,
  });

  final Ticker ticker;
  final EwAnalysis analysis;
  final TradeSetup setup;

  /// How much of the way from the wave's start to TP1 price has already travelled, 0..1.
  /// Low = fresh: most of the move is still ahead.
  final double progress;

  /// [rankSetup] on this timeframe alone.
  final double baseRank;

  /// The higher timeframe's verdict, when it was checked.
  HtfCheck? htf;

  /// Higher is better: [baseRank] × the higher-timeframe factor (agree 1, unknown 0.85,
  /// conflict 0.6). Unchecked or no higher timeframe (1D) counts as 1.
  double get rank => baseRank * (htf?.rankFactor ?? 1);

  Scenario get scenario => setup.scenario;
}

/// Ranking used by the scanner: a textbook count, worth taking, not already played out,
/// and backed by the alternates.
///
/// rank = fit × min(R:R to TP1, 3)/3 × (1 − ½·progress) × (1 if counts agree, else 0.8)
double rankSetup(TradeSetup s, {required double progress, required bool consensus}) =>
    s.scenario.score *
    (math.min(s.rr1, 3) / 3) *
    (1 - 0.5 * progress) *
    (consensus ? 1.0 : 0.8);

/// Runs the chart's exact pipeline on one series: count → primary setup with the ATR
/// stop buffer → rank. Null when there's no count or no coherent trade at the current price.
ScanResult? evaluatePair(Ticker ticker, List<Candle> candles) {
  if (candles.length < 30) return null;
  final a = analyze(candles);
  final primary = a.primary;
  if (primary == null) return null;
  final price = candles.last.close;
  final setup = TradeSetup.from(primary, price, buffer: atr(candles) * stopBufferAtr);
  if (setup == null) return null;
  final start = primary.points.last.pivot.price;
  final span = setup.tp1 - start;
  final progress = span == 0 ? 1.0 : ((price - start) / span).clamp(0.0, 1.0);
  return ScanResult(
    ticker: ticker,
    analysis: a,
    setup: setup,
    progress: progress,
    baseRank: rankSetup(setup, progress: progress, consensus: a.consensus),
  );
}

class ScanCancelled implements Exception {}

/// Fetches candles for every pair (a few at a time, to stay well inside Binance's
/// rate limits) and returns the pairs that produced a setup, best first.
/// [onProgress] reports pairs done; [cancelled] is polled between requests;
/// [onCandles] receives each pair's candles (the background scan keys setups by time).
/// With [checkHigher], every pair with a setup is also counted one timeframe up
/// (one more request each) and judged for agreement.
Future<List<ScanResult>> scan(
  List<Ticker> pairs,
  Timeframe frame, {
  BinanceApi? api,
  int concurrency = 6,
  void Function(int done, int total)? onProgress,
  bool Function()? cancelled,
  void Function(String symbol, List<Candle> candles)? onCandles,
  bool checkHigher = true,
}) async {
  final higher = checkHigher ? frame.higher : null;
  final client = api ?? BinanceApi();
  final results = <ScanResult>[];
  var next = 0, done = 0;

  Future<void> worker() async {
    while (next < pairs.length) {
      if (cancelled?.call() ?? false) throw ScanCancelled();
      final t = pairs[next++];
      try {
        final candles = await client.klines(t.symbol, frame);
        onCandles?.call(t.symbol, candles);
        final r = evaluatePair(t, candles);
        if (r != null) {
          if (higher != null) {
            try {
              final h = analyze(await client.klines(t.symbol, higher));
              r.htf = HtfCheck.judge(r.setup.side, higher, h);
            } catch (_) {
              r.htf = HtfCheck(higher, null, HtfVerdict.unknown);
            }
          }
          results.add(r);
        }
      } on ScanCancelled {
        rethrow;
      } catch (_) {
        // One bad pair (delisted, network blip) shouldn't sink the scan.
      }
      onProgress?.call(++done, pairs.length);
    }
  }

  await Future.wait([for (var i = 0; i < math.min(concurrency, pairs.length); i++) worker()]);
  if (cancelled?.call() ?? false) throw ScanCancelled();
  return results..sort((a, b) => b.rank.compareTo(a.rank));
}
