import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'candles.dart';
import 'elliott.dart';
import 'indicators.dart';
import 'mtf.dart';
import 'sources/source.dart';

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

/// A setup the user chose to track, resolved later against real prices.
class TrackedSetup {
  TrackedSetup({
    required this.id,
    required this.source,
    required this.frame,
    required this.side,
    required this.entry,
    required this.stop,
    required this.tp1,
    required this.tp2,
    required this.count,
    required this.fit,
    required this.madeAt,
    this.status = SetupStatus.open,
    this.resolvedAt,
    this.exit,
    this.htf,
    this.macd,
  });

  final String id;
  final CandleSource source;
  final Timeframe frame;
  final Side side;
  final double entry;
  final double stop;
  final double tp1;
  final double tp2;

  /// The wave count it came from, e.g. "Impulse ↑ · wave 3 in progress".
  final String count;
  final double fit;
  final DateTime madeAt;

  /// The higher timeframe's verdict when the setup was tracked; null if not checked.
  final HtfVerdict? htf;

  /// Whether MACD momentum backed the trade when it was tracked; null if not recorded.
  final MacdVerdict? macd;
  SetupStatus status;
  DateTime? resolvedAt;

  /// Price the result is measured at: stop, TP1, or the last price when it expired.
  double? exit;

  /// Setups that hit neither level within [expiryCandles] of their timeframe are closed.
  DateTime get expiresAt => madeAt.add(frame.size * expiryCandles);

  double get risk => (entry - stop).abs();

  /// Result in R (multiples of the risk taken). Null while open.
  double? get resultR {
    final x = exit;
    if (x == null || risk == 0) return null;
    return (side == Side.long ? x - entry : entry - x) / risk;
  }

  /// Walks [candles] (oldest first) and settles the setup at the first level touched.
  /// When one candle spans both stop and target, the stop is assumed first (conservative).
  /// The candle containing [madeAt] may include pre-entry prices; sources pass their
  /// finest resolution so that window is short.
  void resolve(List<Candle> candles, DateTime now) {
    if (status != SetupStatus.open) return;
    final long = side == Side.long;
    for (var i = 0; i < candles.length; i++) {
      final c = candles[i];
      // Skip candles that closed before the setup was made (the next one already started).
      if (i + 1 < candles.length && !candles[i + 1].start.isAfter(madeAt)) continue;
      if (c.start.isAfter(expiresAt)) break;
      final hitStop = long ? c.low <= stop : c.high >= stop;
      final hitTarget = long ? c.high >= tp1 : c.low <= tp1;
      if (hitStop) {
        _settle(SetupStatus.stopped, stop, c.start);
        return;
      }
      if (hitTarget) {
        _settle(SetupStatus.target, tp1, c.start);
        return;
      }
    }
    if (now.isAfter(expiresAt) && candles.isNotEmpty) {
      _settle(SetupStatus.expired, candles.last.close, now);
    }
  }

  void _settle(SetupStatus s, double price, DateTime at) {
    status = s;
    exit = price;
    resolvedAt = at;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source.toJson(),
        'frame': frame.name,
        'side': side.name,
        'entry': entry,
        'stop': stop,
        'tp1': tp1,
        'tp2': tp2,
        'count': count,
        'fit': fit,
        'madeAt': madeAt.toIso8601String(),
        'status': status.name,
        'resolvedAt': resolvedAt?.toIso8601String(),
        'exit': exit,
        'htf': htf?.name,
        'macd': macd?.name,
      };

  factory TrackedSetup.fromJson(Map<String, dynamic> j) => TrackedSetup(
        id: j['id'] as String,
        source: CandleSource.fromJson(j['source'] as Map<String, dynamic>),
        frame: Timeframe.values.byName(j['frame'] as String),
        side: Side.values.byName(j['side'] as String),
        entry: (j['entry'] as num).toDouble(),
        stop: (j['stop'] as num).toDouble(),
        tp1: (j['tp1'] as num).toDouble(),
        tp2: (j['tp2'] as num).toDouble(),
        count: j['count'] as String,
        fit: (j['fit'] as num).toDouble(),
        madeAt: DateTime.parse(j['madeAt'] as String),
        status: SetupStatus.values.byName(j['status'] as String),
        resolvedAt: j['resolvedAt'] == null ? null : DateTime.parse(j['resolvedAt'] as String),
        exit: (j['exit'] as num?)?.toDouble(),
        htf: j['htf'] == null ? null : HtfVerdict.values.byName(j['htf'] as String),
        macd: j['macd'] == null ? null : MacdVerdict.values.byName(j['macd'] as String),
      );

  factory TrackedSetup.fromSetup(TradeSetup s, CandleSource source, Timeframe frame, DateTime now,
          {HtfVerdict? htf, MacdVerdict? macd}) =>
      TrackedSetup(
        id: '${source.id}:${now.millisecondsSinceEpoch}',
        source: source,
        frame: frame,
        side: s.side,
        entry: s.entry,
        stop: s.stop,
        tp1: s.tp1,
        tp2: s.tp2,
        count: s.scenario.title,
        fit: s.scenario.score,
        madeAt: now,
        htf: htf,
        macd: macd,
      );
}

/// Aggregate track record. R is the honest measure: a 70% hit rate still loses
/// money if winners are small and losers large.
class Scorecard {
  Scorecard(this.all)
      : closed = all.where((s) => s.status != SetupStatus.open).toList(),
        open = all.where((s) => s.status == SetupStatus.open).length;

  final List<TrackedSetup> all;
  final List<TrackedSetup> closed;
  final int open;

  int get wins => closed.where((s) => s.status == SetupStatus.target).length;
  int get losses => closed.where((s) => s.status == SetupStatus.stopped).length;
  int get expired => closed.where((s) => s.status == SetupStatus.expired).length;
  double get totalR => closed.fold(0.0, (t, s) => t + (s.resultR ?? 0));
  double? get avgR => closed.isEmpty ? null : totalR / closed.length;
  double? get hitRate => wins + losses == 0 ? null : wins / (wins + losses);

  /// One sub-scorecard per key, in [order]. Setups whose key is null are left out.
  Map<K, Scorecard> groupBy<K>(K? Function(TrackedSetup) key, Iterable<K> order) => {
        for (final k in order)
          if (all.any((s) => key(s) == k)) k: Scorecard(all.where((s) => key(s) == k).toList()),
      };

  /// Results per timeframe: does the method work better on 4h than on 5m?
  Map<Timeframe, Scorecard> get byFrame => groupBy((s) => s.frame, Timeframe.values);

  /// Closed setups by higher-timeframe verdict, to show whether agreement actually
  /// improves results. Setups never checked, and groups with nothing closed yet, are left out.
  /// Closed setups by whether MACD backed them when tracked: does momentum help?
  Map<MacdVerdict, Scorecard> get byMacd => {
        for (final e in Scorecard(closed).groupBy((s) => s.macd, MacdVerdict.values).entries) e.key: e.value,
      };

  Map<HtfVerdict, Scorecard> get byHtf => {
        for (final e in Scorecard(closed).groupBy((s) => s.htf, HtfVerdict.values).entries) e.key: e.value,
      };
}

class SetupStore {
  static const _key = 'setups.v1';

  static Future<List<TrackedSetup>> load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => TrackedSetup.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> save(List<TrackedSetup> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((s) => s.toJson()).toList()));
  }

  static Future<void> add(TrackedSetup s) async => save([s, ...await load()]);

  static Future<void> remove(String id) async => save((await load())..removeWhere((s) => s.id == id));

  /// Resolves open setups against fresh prices. Returns the ones that closed just now.
  static Future<List<TrackedSetup>> resolveOpen() async {
    final items = await load();
    final now = DateTime.now();
    final closed = <TrackedSetup>[];
    for (final s in items.where((s) => s.status == SetupStatus.open)) {
      try {
        s.resolve(await s.source.since(s.madeAt), now);
        if (s.status != SetupStatus.open) closed.add(s);
      } catch (_) {
        // Try again next time.
      }
    }
    if (closed.isNotEmpty) {
      // Merge into the latest copy so setups added meanwhile survive.
      final latest = await load();
      final byId = {for (final s in closed) s.id: s};
      await save([for (final s in latest) byId[s.id] ?? s]);
    }
    return closed;
  }
}

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

