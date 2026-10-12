/// Trade journal: the trades you actually took, with your size, fills, exit and notes, so
/// you can see your real results and which habits cost you money.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import 'sizing.dart';
import 'trade.dart';

enum JournalStatus { open, closed, cancelled }

/// Mistakes worth tracking: what each one cost shows up in the stats.
const journalMistakes = [
  'Moved my stop',
  'Chased the entry',
  'Exited early',
  'No setup',
  'Oversized',
  'Revenge trade',
  'Ignored higher timeframe',
];

class JournalEntry {
  JournalEntry({
    required this.id,
    required this.title,
    required this.side,
    required this.entry,
    required this.stop,
    required this.size,
    required this.riskAmount,
    required this.openedAt,
    this.sourceId,
    this.frame,
    this.tp1,
    this.tp2,
    this.feeRate = defaultFeeRate,
    this.leverage = 1,
    this.count,
    this.status = JournalStatus.open,
    this.exit,
    this.closedAt,
    this.followedPlan,
    List<String>? mistakes,
    this.notes = '',
  }) : mistakes = mistakes ?? [];

  final String id;

  /// e.g. "BTC/USDT".
  String title;

  /// The app's source id (e.g. "binance:BTCUSDT") when logged from a chart.
  final String? sourceId;

  /// Timeframe label, e.g. "1h", when logged from a chart.
  final String? frame;
  Side side;
  double entry, stop, size, riskAmount, feeRate;
  double? tp1, tp2;
  int leverage;

  /// The wave count it came from, if any.
  final String? count;
  DateTime openedAt;
  JournalStatus status;
  double? exit;
  DateTime? closedAt;

  /// Did you follow your plan (entry, stop, target, size)? Null = not answered.
  bool? followedPlan;
  List<String> mistakes;
  String notes;

  bool get isClosed => status == JournalStatus.closed && exit != null;

  /// Net result after fees, in quote currency; null unless closed.
  double? get pnl => !isClosed
      ? null
      : (side == Side.long ? exit! - entry : entry - exit!) * size - feeRate * (entry + exit!) * size;

  /// [pnl] in multiples of the amount risked.
  double? get r => pnl == null || riskAmount <= 0 ? null : pnl! / riskAmount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (sourceId != null) 'sourceId': sourceId,
        if (frame != null) 'frame': frame,
        'side': side.name,
        'entry': entry,
        'stop': stop,
        if (tp1 != null) 'tp1': tp1,
        if (tp2 != null) 'tp2': tp2,
        'size': size,
        'riskAmount': riskAmount,
        'feeRate': feeRate,
        'leverage': leverage,
        if (count != null) 'count': count,
        'openedAt': openedAt.toIso8601String(),
        'status': status.name,
        if (exit != null) 'exit': exit,
        if (closedAt != null) 'closedAt': closedAt!.toIso8601String(),
        if (followedPlan != null) 'followedPlan': followedPlan,
        'mistakes': mistakes,
        'notes': notes,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id'] as String,
        title: j['title'] as String,
        sourceId: j['sourceId'] as String?,
        frame: j['frame'] as String?,
        side: Side.values.byName(j['side'] as String),
        entry: (j['entry'] as num).toDouble(),
        stop: (j['stop'] as num).toDouble(),
        tp1: (j['tp1'] as num?)?.toDouble(),
        tp2: (j['tp2'] as num?)?.toDouble(),
        size: (j['size'] as num).toDouble(),
        riskAmount: (j['riskAmount'] as num).toDouble(),
        feeRate: (j['feeRate'] as num?)?.toDouble() ?? defaultFeeRate,
        leverage: j['leverage'] as int? ?? 1,
        count: j['count'] as String?,
        openedAt: DateTime.parse(j['openedAt'] as String),
        status: JournalStatus.values.byName(j['status'] as String),
        exit: (j['exit'] as num?)?.toDouble(),
        closedAt: j['closedAt'] == null ? null : DateTime.parse(j['closedAt'] as String),
        followedPlan: j['followedPlan'] as bool?,
        mistakes: [for (final m in j['mistakes'] as List? ?? const []) m as String],
        notes: j['notes'] as String? ?? '',
      );

  /// A new open entry from a sizing plan.
  factory JournalEntry.fromPlan(PositionPlan p,
          {required String title, String? sourceId, String? frame, String? count, DateTime? now}) =>
      JournalEntry(
        id: '${(now ?? DateTime.now()).microsecondsSinceEpoch}',
        title: title,
        sourceId: sourceId,
        frame: frame,
        side: p.side,
        entry: p.entry,
        stop: p.stop,
        tp1: p.tp1,
        tp2: p.tp2,
        size: p.size,
        riskAmount: p.riskAmount,
        feeRate: p.feeRate,
        leverage: p.fitsSpot ? 1 : p.leverage,
        count: count,
        openedAt: now ?? DateTime.now(),
      );

  static const csvHeader =
      'opened,closed,pair,timeframe,side,entry,stop,tp1,exit,size,leverage,risk,pnl,r,status,followed_plan,mistakes,count,notes';

  String toCsv() {
    String q(String s) => '"${s.replaceAll('"', '""')}"';
    return [
      openedAt.toIso8601String(),
      closedAt?.toIso8601String() ?? '',
      q(title),
      frame ?? '',
      side.name,
      entry,
      stop,
      tp1 ?? '',
      exit ?? '',
      size,
      leverage,
      riskAmount,
      pnl?.toStringAsFixed(2) ?? '',
      r?.toStringAsFixed(2) ?? '',
      status.name,
      followedPlan == null ? '' : (followedPlan! ? 'yes' : 'no'),
      q(mistakes.join('; ')),
      q(count ?? ''),
      q(notes),
    ].join(',');
  }
}

/// Results over the closed entries.
class JournalStats {
  JournalStats(Iterable<JournalEntry> entries)
      : closed = entries.where((e) => e.isClosed).toList()..sort((a, b) => a.closedAt!.compareTo(b.closedAt!)),
        open = entries.where((e) => e.status == JournalStatus.open).length;

  /// Oldest close first.
  final List<JournalEntry> closed;
  final int open;

  int get wins => closed.where((e) => e.pnl! > 0).length;
  double? get winRate => closed.isEmpty ? null : wins / closed.length;
  double get totalPnl => closed.fold(0.0, (t, e) => t + e.pnl!);
  double? get avgR => closed.isEmpty ? null : closed.fold(0.0, (t, e) => t + e.r!) / closed.length;
  double? get bestR => closed.isEmpty ? null : closed.map((e) => e.r!).reduce(math.max);
  double? get worstR => closed.isEmpty ? null : closed.map((e) => e.r!).reduce(math.min);

  /// Running total P&L after each close.
  List<double> get equity {
    var t = 0.0;
    return [for (final e in closed) t += e.pnl!];
  }

  JournalStats where(bool Function(JournalEntry) test) => JournalStats(closed.where(test));

  /// Total P&L of trades tagged with each mistake (tags that were used only).
  Map<String, JournalStats> get byMistake => {
        for (final m in journalMistakes)
          if (closed.any((e) => e.mistakes.contains(m))) m: where((e) => e.mistakes.contains(m)),
      };
}

class JournalStore {
  static const _key = 'journal.v1';

  static Future<List<JournalEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => JournalEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> save(List<JournalEntry> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  /// Adds or replaces [e] (newest first).
  static Future<void> upsert(JournalEntry e) async {
    final items = await load();
    final i = items.indexWhere((x) => x.id == e.id);
    if (i >= 0) {
      items[i] = e;
    } else {
      items.insert(0, e);
    }
    await save(items);
  }

  static Future<void> remove(String id) async => save((await load())..removeWhere((e) => e.id == id));
}

/// Remembered sizing inputs, so the sheet opens with your balance and risk.
class SizingDefaults {
  const SizingDefaults({this.balance, this.riskPct = 1, this.feePct = 0.1});
  final double? balance;
  final double riskPct, feePct;

  static const _key = 'sizing.defaults.v1';

  static Future<SizingDefaults> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const SizingDefaults();
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return SizingDefaults(
      balance: (j['balance'] as num?)?.toDouble(),
      riskPct: (j['riskPct'] as num?)?.toDouble() ?? 1,
      feePct: (j['feePct'] as num?)?.toDouble() ?? 0.1,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode({'balance': balance, 'riskPct': riskPct, 'feePct': feePct}));
  }
}
