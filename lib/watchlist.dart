import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One watched outcome of one market, plus the alert rules for it.
class WatchItem {
  WatchItem({
    required this.marketId,
    required this.question,
    required this.outcomeIndex,
    required this.outcome,
    required this.baseline,
    required this.lastPrice,
    this.movePoints = 5,
    this.above,
    this.below,
    this.resolved = false,
  });

  final String marketId;
  final String question;
  final int outcomeIndex;
  final String outcome;

  /// Price the next "moved by N points" alert is measured from. Reset on each alert.
  double baseline;
  double lastPrice;

  /// Alert when the price moves this many percentage points from [baseline]. 0 disables.
  int movePoints;

  /// Alert when the price crosses up through this level (0–1).
  double? above;

  /// Alert when the price crosses down through this level (0–1).
  double? below;
  bool resolved;

  String get key => '$marketId:$outcomeIndex';

  Map<String, dynamic> toJson() => {
        'marketId': marketId,
        'question': question,
        'outcomeIndex': outcomeIndex,
        'outcome': outcome,
        'baseline': baseline,
        'lastPrice': lastPrice,
        'movePoints': movePoints,
        'above': above,
        'below': below,
        'resolved': resolved,
      };

  factory WatchItem.fromJson(Map<String, dynamic> j) => WatchItem(
        marketId: j['marketId'] as String,
        question: j['question'] as String,
        outcomeIndex: j['outcomeIndex'] as int,
        outcome: j['outcome'] as String,
        baseline: (j['baseline'] as num).toDouble(),
        lastPrice: (j['lastPrice'] as num).toDouble(),
        movePoints: (j['movePoints'] as int?) ?? 5,
        above: (j['above'] as num?)?.toDouble(),
        below: (j['below'] as num?)?.toDouble(),
        resolved: (j['resolved'] as bool?) ?? false,
      );
}

/// Applies a fresh [price] to [item], mutating it, and returns the alert lines it triggers.
List<String> evaluate(WatchItem item, double price, {required bool closed}) {
  final alerts = <String>[];
  final prev = item.lastPrice;
  if (closed) {
    if (!item.resolved) {
      item.resolved = true;
      alerts.add('Market closed — ${item.outcome} settled at ${pct(price)}');
    }
    item.lastPrice = price;
    return alerts;
  }
  final above = item.above;
  if (above != null && prev < above && price >= above) {
    alerts.add('${item.outcome} rose above ${pct(above)} (now ${pct(price)})');
  }
  final below = item.below;
  if (below != null && prev > below && price <= below) {
    alerts.add('${item.outcome} fell below ${pct(below)} (now ${pct(price)})');
  }
  if (item.movePoints > 0) {
    final moved = (price - item.baseline) * 100;
    // Round so 0.55 → 0.60 counts as exactly 5 points despite float error.
    if ((moved.abs() * 1000).round() >= item.movePoints * 1000) {
      final sign = moved > 0 ? '+' : '−';
      alerts.add('${item.outcome} $sign${moved.abs().toStringAsFixed(1)} pts '
          '(${pct(item.baseline)} → ${pct(price)})');
      item.baseline = price;
    }
  }
  item.lastPrice = price;
  return alerts;
}

String pct(double p) {
  final v = p * 100;
  if (v > 0 && v < 1) return '<1%';
  if (v < 100 && v > 99) return '>99%';
  return '${v.round()}%';
}

class WatchStore {
  static const _key = 'watchlist.v1';

  static Future<List<WatchItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    // The background isolate and the UI keep separate caches; always read fresh.
    await prefs.reload();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => WatchItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> save(List<WatchItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((i) => i.toJson()).toList()));
  }

  static Future<void> upsert(WatchItem item) async {
    final items = await load();
    final i = items.indexWhere((e) => e.key == item.key);
    if (i >= 0) {
      items[i] = item;
    } else {
      items.add(item);
    }
    await save(items);
  }

  static Future<void> remove(String key) async {
    final items = await load()..removeWhere((e) => e.key == key);
    await save(items);
  }
}
