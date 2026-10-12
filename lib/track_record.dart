/// The public track record: every setup the engine produces on a fixed list of pairs,
/// logged automatically by a scheduled job the moment it appears, and settled later by
/// the same rules as tracked setups. Nothing is picked by hand and nothing is removed;
/// the git history of the `track-record` branch shows each signal was published
/// before its outcome was known.
///
/// Pure Dart (no Flutter): the job (tool/track_record.dart) and the app both use it.
library;

import 'dart:math' as math;

import 'backtest.dart';
import 'candles.dart';
import 'evidence.dart';
import 'trade.dart';

/// Where the job publishes, and the app reads from.
const trackRecordBranch = 'track-record';
const trackRecordRaw = String.fromEnvironment('TRACK_RECORD_RAW',
    defaultValue: 'https://raw.githubusercontent.com/tofilagman/tantya/$trackRecordBranch');
const trackRecordPage = 'https://github.com/tofilagman/tantya/tree/$trackRecordBranch';
const trackRecordHistory = 'https://github.com/tofilagman/tantya/commits/$trackRecordBranch';

/// The fixed universe, chosen before any result was known: liquid Binance USDT pairs.
const trackPairs = [
  'BTCUSDT', 'ETHUSDT', 'BNBUSDT', 'SOLUSDT', 'XRPUSDT', 'DOGEUSDT', 'ADAUSDT', 'TRXUSDT', //
  'LINKUSDT', 'AVAXUSDT', 'DOTUSDT', 'LTCUSDT', 'BCHUSDT', 'XLMUSDT', 'NEARUSDT', 'UNIUSDT',
  'SUIUSDT', 'AAVEUSDT', 'HBARUSDT', 'TONUSDT',
];
const trackFrames = [Timeframe.h1, Timeframe.h4];

/// A new signal is only logged if the job runs within this long of the candle opening,
/// so the entry price is (close to) what was known at the candle close. A late run
/// skips that candle; which candles are skipped never depends on the outcome.
const maxEntryDelay = Duration(minutes: 20);

/// Binance spot taker fee per side, charged on entry and exit.
const takerFee = 0.001;

class PublicSignal {
  PublicSignal({
    required this.symbol,
    required this.frame,
    required this.side,
    required this.entry,
    required this.stop,
    required this.tp1,
    required this.tp2,
    required this.count,
    required this.wave,
    required this.score,
    required this.candleOpen,
    required this.madeAt,
    required this.engine,
    this.evidence,
    this.adx,
    this.status = SetupStatus.open,
    this.exit,
    this.closedAt,
  });

  final String symbol;
  final Timeframe frame;
  final Side side;
  final double entry, stop, tp1, tp2;
  final String count, wave;
  final double score;
  final double? evidence, adx;

  /// Start of the candle the trade was entered in; settlement starts with it.
  final DateTime candleOpen;

  /// When the job published it (UTC).
  final DateTime madeAt;

  /// Git commit of the engine that produced it.
  final String engine;

  SetupStatus status;
  double? exit;
  DateTime? closedAt;

  String get id => '$symbol:${frame.label}:${candleOpen.millisecondsSinceEpoch}';
  double get risk => (entry - stop).abs();

  /// Result in R before fees; null while open.
  double? get r => exit == null || risk == 0 ? null : (side == Side.long ? exit! - entry : entry - exit!) / risk;

  /// Fees for the round trip, in R.
  double get feeR => exit == null || risk == 0 ? 0 : takerFee * (entry + exit!) / risk;

  /// Result in R after fees; null while open.
  double? get netR => r == null ? null : r! - feeR;

  EvidenceLevel? get evidenceLevel => EvidenceReport.levelOf(evidence);

  /// Settles against [candles] (any order of history that covers the trade), using only
  /// candles that had closed by [now]. Same rules as tracked setups: whichever of TP1 or
  /// the stop is touched first; a candle touching both counts as the stop; after
  /// [expiryCandles] candles it closes at the last close.
  void settle(List<Candle> candles, DateTime now) {
    if (status != SetupStatus.open) return;
    final after = candles
        .where((c) => !c.start.isBefore(candleOpen) && !c.start.add(frame.size).isAfter(now))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final long = side == Side.long;
    for (final (i, c) in after.indexed) {
      if (i >= expiryCandles) break;
      final end = c.start.add(frame.size);
      if (long ? c.low <= stop : c.high >= stop) {
        _close(SetupStatus.stopped, stop, end);
        return;
      }
      if (long ? c.high >= tp1 : c.low <= tp1) {
        _close(SetupStatus.target, tp1, end);
        return;
      }
      if (i == expiryCandles - 1) {
        _close(SetupStatus.expired, c.close, end);
        return;
      }
    }
  }

  void _close(SetupStatus s, double price, DateTime at) {
    status = s;
    exit = price;
    closedAt = at.toUtc();
  }

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'frame': frame.name,
        'side': side.name,
        'entry': entry,
        'stop': stop,
        'tp1': tp1,
        'tp2': tp2,
        'count': count,
        'wave': wave,
        'score': double.parse(score.toStringAsFixed(4)),
        if (evidence != null) 'evidence': double.parse(evidence!.toStringAsFixed(4)),
        if (adx != null) 'adx': double.parse(adx!.toStringAsFixed(2)),
        'candleOpen': candleOpen.toUtc().toIso8601String(),
        'madeAt': madeAt.toUtc().toIso8601String(),
        'engine': engine,
        'status': status.name,
        if (exit != null) 'exit': exit,
        if (closedAt != null) 'closedAt': closedAt!.toUtc().toIso8601String(),
      };

  factory PublicSignal.fromJson(Map<String, dynamic> j) => PublicSignal(
        symbol: j['symbol'] as String,
        frame: Timeframe.values.byName(j['frame'] as String),
        side: Side.values.byName(j['side'] as String),
        entry: (j['entry'] as num).toDouble(),
        stop: (j['stop'] as num).toDouble(),
        tp1: (j['tp1'] as num).toDouble(),
        tp2: (j['tp2'] as num).toDouble(),
        count: j['count'] as String,
        wave: j['wave'] as String,
        score: (j['score'] as num).toDouble(),
        evidence: (j['evidence'] as num?)?.toDouble(),
        adx: (j['adx'] as num?)?.toDouble(),
        candleOpen: DateTime.parse(j['candleOpen'] as String),
        madeAt: DateTime.parse(j['madeAt'] as String),
        engine: j['engine'] as String,
        status: SetupStatus.values.byName(j['status'] as String),
        exit: (j['exit'] as num?)?.toDouble(),
        closedAt: j['closedAt'] == null ? null : DateTime.parse(j['closedAt'] as String),
      );

  /// The signal the app would show for [symbol] on [frame] right now, or null.
  /// [candles] must include the still-forming candle last; the count is read from the
  /// closed candles before it, and the trade is entered at the forming candle's latest
  /// price. Null as well when the forming candle is older than [maxEntryDelay].
  static PublicSignal? detect(String symbol, Timeframe frame, List<Candle> candles, DateTime now,
      {String engine = 'local', int window = 300, Duration maxDelay = maxEntryDelay}) {
    if (candles.length < 2) return null;
    final forming = candles.last;
    if (forming.start.add(frame.size).isBefore(now)) return null; // not actually forming
    if (now.difference(forming.start) > maxDelay) return null;
    final closed = candles.sublist(math.max(0, candles.length - 1 - window), candles.length - 1);
    if (closed.length < 100) return null;
    final t = setupAt(closed, closed.length - 1, const BacktestConfig(), price: forming.close);
    if (t == null) return null;
    return PublicSignal(
      symbol: symbol,
      frame: frame,
      side: t.side,
      entry: t.entry,
      stop: t.stop,
      tp1: t.tp1,
      tp2: t.tp2,
      count: t.count,
      wave: t.wave,
      score: t.score,
      evidence: t.evidence,
      adx: t.adx,
      candleOpen: forming.start.toUtc(),
      madeAt: now.toUtc(),
      engine: engine,
    );
  }
}

/// Totals over a set of signals. Open ones count towards [open] only.
class TrackStats {
  TrackStats(Iterable<PublicSignal> signals)
      : closed = signals.where((s) => s.status != SetupStatus.open).toList()
          ..sort((a, b) => a.closedAt!.compareTo(b.closedAt!)),
        open = signals.where((s) => s.status == SetupStatus.open).length;

  /// Oldest close first.
  final List<PublicSignal> closed;
  final int open;

  int get wins => closed.where((s) => s.status == SetupStatus.target).length;
  int get losses => closed.where((s) => s.status == SetupStatus.stopped).length;
  int get expired => closed.where((s) => s.status == SetupStatus.expired).length;
  double? get hitRate => wins + losses == 0 ? null : wins / (wins + losses);
  double get totalR => closed.fold(0.0, (t, s) => t + s.r!);
  double get totalNetR => closed.fold(0.0, (t, s) => t + s.netR!);
  double? get avgR => closed.isEmpty ? null : totalR / closed.length;
  double? get avgNetR => closed.isEmpty ? null : totalNetR / closed.length;

  /// Running total of net R after each close.
  List<double> get equity {
    var e = 0.0;
    return [for (final s in closed) e += s.netR!];
  }

  /// Largest fall from a running peak of net R (≥ 0).
  double get maxDrawdownR {
    var peak = 0.0, worst = 0.0;
    for (final e in equity) {
      peak = math.max(peak, e);
      worst = math.max(worst, peak - e);
    }
    return worst;
  }

  Map<String, dynamic> toJson() => {
        'closed': closed.length,
        'open': open,
        'wins': wins,
        'losses': losses,
        'expired': expired,
        'hitRate': hitRate,
        'avgR': avgR,
        'avgNetR': avgNetR,
        'totalR': totalR,
        'totalNetR': totalNetR,
        'maxDrawdownR': maxDrawdownR,
      };
}

/// The whole record, as published.
class TrackRecord {
  TrackRecord(this.signals);

  /// Newest first.
  final List<PublicSignal> signals;

  TrackStats get stats => TrackStats(signals);
  Map<Timeframe, TrackStats> get byFrame => {
        for (final f in trackFrames) f: TrackStats(signals.where((s) => s.frame == f)),
      };
  Map<EvidenceLevel, TrackStats> get byEvidence => {
        for (final e in EvidenceLevel.values) e: TrackStats(signals.where((s) => s.evidenceLevel == e)),
      };

  DateTime? get since => signals.isEmpty ? null : signals.map((s) => s.madeAt).reduce((a, b) => a.isBefore(b) ? a : b);

  /// Adds [s] unless a signal for the same pair, frame and candle already exists, or one
  /// is still open on that pair and frame (one trade at a time, as in the backtest).
  bool add(PublicSignal s) {
    if (signals.any((x) => x.id == s.id)) return false;
    if (signals.any((x) => x.symbol == s.symbol && x.frame == s.frame && x.status == SetupStatus.open)) return false;
    signals.insert(0, s);
    return true;
  }

  List<Map<String, dynamic>> toJson() => [for (final s in signals) s.toJson()];
  factory TrackRecord.fromJson(List<dynamic> j) =>
      TrackRecord([for (final e in j) PublicSignal.fromJson(e as Map<String, dynamic>)]);
}
