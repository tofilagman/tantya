/// Watched crypto pairs and their alerts: price levels and big moves, plus what the wave
/// engine says: a new buy/sell setup, the count changing, the target zone being reached,
/// or the count being invalidated.
///
/// The count and setup are read from closed candles only, so a candle still forming
/// can't make them flicker between checks; price levels use the latest price.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'candles.dart';
import 'elliott.dart';
import 'trade.dart';

/// What the engine said at one check.
class PairSnapshot {
  const PairSnapshot({required this.price, this.scenario, this.setup});

  /// Latest traded price.
  final double price;

  /// The primary count on closed candles; null when no count passes the rules.
  final Scenario? scenario;

  /// The trade the count gives at [price], when its reward:risk to TP1 is at least 1.
  final TradeSetup? setup;

  /// [closed] are closed candles, oldest first; [price] the latest price.
  static PairSnapshot of(List<Candle> closed, double price) {
    final view = closed.length > 300 ? closed.sublist(closed.length - 300) : closed;
    final s = view.length < 50 ? null : analyze(view).primary;
    final setup = s == null ? null : TradeSetup.from(s, price, buffer: atr(view) * stopBufferAtr);
    return PairSnapshot(price: price, scenario: s, setup: setup == null || setup.poorRR ? null : setup);
  }
}

/// Timeframes worth watching: background checks run every ~15 minutes at best.
const pairWatchFrames = [Timeframe.m15, Timeframe.m30, Timeframe.h1, Timeframe.h4, Timeframe.d1];

class PairWatch {
  PairWatch({
    required this.symbol,
    required this.title,
    required this.frame,
    required this.lastPrice,
    required this.baseline,
    this.setups = true,
    this.countChanges = true,
    this.targets = true,
    this.above,
    this.below,
    this.movePct = 0,
    this.count,
    this.direction,
    this.targetLow,
    this.targetHigh,
    this.invalidation,
    this.invalidSide,
    this.targetHit = false,
    this.invalidated = false,
    this.setupKey,
    this.primed = false,
  });

  final String symbol;

  /// Display name, e.g. "BTC/USDT".
  final String title;
  final Timeframe frame;

  // Rules.
  /// A new buy/sell setup appears.
  bool setups;

  /// The wave count changes.
  bool countChanges;

  /// The count's target zone is reached, or the count is invalidated.
  bool targets;

  /// Price crosses up through / down through these levels.
  double? above, below;

  /// Price moves this many percent from [baseline]; 0 = off.
  double movePct;

  // State from the last check.
  double lastPrice;

  /// Price the next "moved N%" alert is measured from; reset on each alert.
  double baseline;

  /// The count at the last check (its title), or null before the first check.
  String? count;
  int? direction;
  double? targetLow, targetHigh, invalidation;
  int? invalidSide;

  /// Already notified for this count.
  bool targetHit, invalidated;

  /// The setup last seen (side and count), so the same one isn't announced twice.
  String? setupKey;

  /// Whether a first state has been recorded; nothing but price alerts fire before that.
  bool primed;

  String get key => '$symbol:${frame.name}';

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'title': title,
        'frame': frame.name,
        'setups': setups,
        'countChanges': countChanges,
        'targets': targets,
        'above': above,
        'below': below,
        'movePct': movePct,
        'lastPrice': lastPrice,
        'baseline': baseline,
        'count': count,
        'direction': direction,
        'targetLow': targetLow,
        'targetHigh': targetHigh,
        'invalidation': invalidation,
        'invalidSide': invalidSide,
        'targetHit': targetHit,
        'invalidated': invalidated,
        'setupKey': setupKey,
        'primed': primed,
      };

  factory PairWatch.fromJson(Map<String, dynamic> j) => PairWatch(
        symbol: j['symbol'] as String,
        title: j['title'] as String,
        frame: Timeframe.values.byName(j['frame'] as String),
        setups: j['setups'] as bool? ?? true,
        countChanges: j['countChanges'] as bool? ?? true,
        targets: j['targets'] as bool? ?? true,
        above: (j['above'] as num?)?.toDouble(),
        below: (j['below'] as num?)?.toDouble(),
        movePct: (j['movePct'] as num?)?.toDouble() ?? 0,
        lastPrice: (j['lastPrice'] as num).toDouble(),
        baseline: (j['baseline'] as num).toDouble(),
        count: j['count'] as String?,
        direction: j['direction'] as int?,
        targetLow: (j['targetLow'] as num?)?.toDouble(),
        targetHigh: (j['targetHigh'] as num?)?.toDouble(),
        invalidation: (j['invalidation'] as num?)?.toDouble(),
        invalidSide: j['invalidSide'] as int?,
        targetHit: j['targetHit'] as bool? ?? false,
        invalidated: j['invalidated'] as bool? ?? false,
        setupKey: j['setupKey'] as String?,
        primed: j['primed'] as bool? ?? false,
      );

  /// Copies the rules from [rules] and keeps this watch's state.
  void applyRules(PairWatch rules) {
    setups = rules.setups;
    countChanges = rules.countChanges;
    targets = rules.targets;
    above = rules.above;
    below = rules.below;
    movePct = rules.movePct;
  }

  /// Records [snap] as the current state without alerting (used when a watch is created
  /// from the chart, where the user can already see the count and setup).
  void prime(PairSnapshot snap) {
    lastPrice = snap.price;
    baseline = snap.price;
    _takeCount(snap.scenario);
    setupKey = _setupKeyOf(snap);
    primed = true;
  }

  void _takeCount(Scenario? s) {
    count = s?.title;
    direction = s?.direction;
    targetLow = s?.targetLow;
    targetHigh = s?.targetHigh;
    invalidation = s?.invalidation;
    invalidSide = s?.invalidSide;
    targetHit = false;
    invalidated = false;
  }

  static String? _setupKeyOf(PairSnapshot snap) {
    final s = snap.setup;
    return s == null ? null : '${s.side.name}|${s.scenario.title}';
  }
}

enum PairAlertKind { setup, target, invalidated, countChanged, level, move }

class PairAlert {
  const PairAlert(this.kind, this.text);
  final PairAlertKind kind;
  final String text;
}

/// Applies [snap] to [w], mutating its state, and returns the alerts it triggers.
/// [fmt] formats prices.
List<PairAlert> applySnapshot(PairWatch w, PairSnapshot snap, {String Function(double)? fmt}) {
  final f = fmt ?? (double p) => p.toString();
  final out = <PairAlert>[];
  final prev = w.lastPrice, price = snap.price;
  final primed = w.primed;

  // Price levels and moves.
  if (w.above != null && prev < w.above! && price >= w.above!) {
    out.add(PairAlert(PairAlertKind.level, 'Rose above ${f(w.above!)} (now ${f(price)})'));
  }
  if (w.below != null && prev > w.below! && price <= w.below!) {
    out.add(PairAlert(PairAlertKind.level, 'Fell below ${f(w.below!)} (now ${f(price)})'));
  }
  if (w.movePct > 0 && w.baseline > 0) {
    final moved = (price - w.baseline) / w.baseline * 100;
    if (moved.abs() >= w.movePct - 1e-9) {
      out.add(PairAlert(PairAlertKind.move,
          '${moved > 0 ? '+' : '−'}${moved.abs().toStringAsFixed(1)}% (${f(w.baseline)} → ${f(price)})'));
      w.baseline = price;
    }
  }

  // The count known at the last check: did price reach its target, or break it?
  if (w.count != null && w.direction != null) {
    final d = w.direction!;
    if (!w.targetHit && w.targetLow != null && w.targetHigh != null &&
        (d > 0 ? price >= w.targetLow! : price <= w.targetHigh!)) {
      w.targetHit = true;
      if (w.targets) {
        out.add(PairAlert(PairAlertKind.target,
            'Target reached: ${w.count} (zone ${f(w.targetLow!)}–${f(w.targetHigh!)}, now ${f(price)})'));
      }
    }
    if (!w.invalidated && w.invalidation != null && w.invalidSide != null &&
        (w.invalidSide! > 0 ? price > w.invalidation! : price < w.invalidation!)) {
      w.invalidated = true;
      if (w.targets) {
        out.add(PairAlert(PairAlertKind.invalidated,
            'Count invalidated: ${w.count} (price ${w.invalidSide! > 0 ? 'above' : 'below'} ${f(w.invalidation!)})'));
      }
    }
  }

  // The count itself.
  final now = snap.scenario?.title;
  if (now != w.count) {
    if (w.countChanges && primed) {
      out.add(PairAlert(PairAlertKind.countChanged,
          now == null ? 'No valid count now (was: ${w.count})' : 'Count changed: ${w.count ?? 'none'} → $now'));
    }
    w._takeCount(snap.scenario);
  }

  // A new setup.
  final key = PairWatch._setupKeyOf(snap);
  if (key != null && key != w.setupKey && w.setups && primed) {
    final s = snap.setup!;
    out.add(PairAlert(
      PairAlertKind.setup,
      '${s.side == Side.long ? 'LONG' : 'SHORT'} setup · ${s.scenario.title}\n'
      'Entry ${f(s.entry)} · SL ${f(s.stop)} · TP1 ${f(s.tp1)} · R:R ${s.rr1.toStringAsFixed(2)}',
    ));
  }
  w.setupKey = key;
  w.lastPrice = price;
  w.primed = true;
  return out;
}

class PairWatchStore {
  static const _key = 'pairWatch.v1';

  static Future<List<PairWatch>> load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // the background isolate writes too
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => PairWatch.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> save(List<PairWatch> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((i) => i.toJson()).toList()));
  }

  static Future<void> upsert(PairWatch w) async {
    final items = await load();
    final i = items.indexWhere((e) => e.key == w.key);
    if (i >= 0) {
      items[i] = w;
    } else {
      items.add(w);
    }
    await save(items);
  }

  static Future<void> remove(String key) async => save((await load())..removeWhere((e) => e.key == key));
}
