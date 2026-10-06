import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'candles.dart';
import 'mtf.dart';
import 'scanner.dart';
import 'setup.dart';
import 'sources/binance.dart';

enum Bias { all, long, short }

/// What the background scan looks for. Saved from the scanner screen's current settings.
class ScanAlertSettings {
  ScanAlertSettings({
    required this.frame,
    required this.universe,
    this.bias = Bias.all,
    this.minRR = 1.5,
    this.agreeOnly = false,
    this.minFit = 0.6,
    this.maxProgress = 0.5,
    this.htfAgreeOnly = true,
  });

  final Timeframe frame;
  final int universe;
  final Bias bias;

  /// Minimum reward:risk to TP1; 0 = any.
  final double minRR;
  final bool agreeOnly;

  /// Minimum ranking score (0..1): textbook shape and big enough to matter.
  final double minFit;

  /// Only fresh setups: less than this share of the move to TP1 already done.
  final double maxProgress;

  /// Only setups the next timeframe up agrees with (costs one extra request per setup).
  /// Ignored on 1D, which has no higher timeframe.
  final bool htfAgreeOnly;

  bool get _checksHigher => htfAgreeOnly && frame.higher != null;

  /// 5m is left out: a 15-minute background job can't keep up with it, and it burns data.
  static const frames = [Timeframe.m15, Timeframe.h1, Timeframe.h4, Timeframe.d1];

  bool matches(ScanResult r) {
    final s = r.setup;
    if (bias == Bias.long && s.side != Side.long) return false;
    if (bias == Bias.short && s.side != Side.short) return false;
    if (s.rr1 < minRR) return false;
    if (agreeOnly && !r.analysis.consensus) return false;
    if (r.scenario.score < minFit) return false;
    if (_checksHigher && r.htf?.verdict != HtfVerdict.agree) return false;
    return r.progress < maxProgress;
  }

  /// Rough mobile data per day: ~15 KB gzipped per pair per scan (×2 when the higher
  /// timeframe is checked; most pairs have a setup), one scan per candle (at most every
  /// 15 minutes), plus the ~2 MB ticker list once a day.
  double get megabytesPerDay {
    final scansPerDay = const Duration(days: 1).inMinutes /
        (frame.size.inMinutes < 15 ? 15 : frame.size.inMinutes);
    return scansPerDay * universe * 15 * (_checksHigher ? 2 : 1) / 1024 + 2;
  }

  Map<String, dynamic> toJson() => {
        'frame': frame.name,
        'universe': universe,
        'bias': bias.name,
        'minRR': minRR,
        'agreeOnly': agreeOnly,
        'minFit': minFit,
        'maxProgress': maxProgress,
        'htfAgreeOnly': htfAgreeOnly,
      };

  factory ScanAlertSettings.fromJson(Map<String, dynamic> j) => ScanAlertSettings(
        frame: Timeframe.values.byName(j['frame'] as String),
        universe: j['universe'] as int,
        bias: Bias.values.byName(j['bias'] as String),
        minRR: (j['minRR'] as num).toDouble(),
        agreeOnly: j['agreeOnly'] as bool,
        minFit: (j['minFit'] as num).toDouble(),
        maxProgress: (j['maxProgress'] as num).toDouble(),
        // Alerts saved before this option existed keep their old behaviour (and data use).
        htfAgreeOnly: j['htfAgreeOnly'] as bool? ?? false,
      );
}

/// Identifies a setup across scans: same pair, timeframe, direction and wave, and the
/// same wave start time. Candle indexes shift as new candles arrive, so times are used.
String setupKey(ScanResult r, Timeframe frame, List<Candle> candles) {
  final start = candles[r.scenario.points.last.pivot.index].start.millisecondsSinceEpoch;
  return '${r.ticker.symbol}|${frame.name}|${r.setup.side.name}|${r.scenario.next}|$start';
}

/// Background scan state: settings, the pairs to scan, and which setups were already notified.
class ScanAlertStore {
  static const _settingsKey = 'scanAlerts.settings.v1';
  static const _symbolsKey = 'scanAlerts.symbols.v1';
  static const _symbolsAtKey = 'scanAlerts.symbolsAt.v1';
  static const _lastRunKey = 'scanAlerts.lastRun.v1';
  static const _seenKey = 'scanAlerts.seen.v1';

  static Future<SharedPreferences> _prefs() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    return p;
  }

  static Future<ScanAlertSettings?> settings() async {
    final raw = (await _prefs()).getString(_settingsKey);
    return raw == null ? null : ScanAlertSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> enable(ScanAlertSettings s) async {
    final p = await _prefs();
    await p.setString(_settingsKey, jsonEncode(s.toJson()));
    // New criteria: scan on the next run, and refresh the pair list.
    await p.remove(_lastRunKey);
    await p.remove(_symbolsAtKey);
  }

  static Future<void> disable() async => (await _prefs()).remove(_settingsKey);

  /// Top pairs by volume, refreshed at most daily (the full ticker list is ~2 MB).
  static Future<List<Ticker>> _universe(SharedPreferences p, BinanceApi api, int n, DateTime now) async {
    final at = p.getInt(_symbolsAtKey);
    final cached = p.getStringList(_symbolsKey);
    if (cached != null && cached.length >= n && at != null &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(at)) < const Duration(days: 1)) {
      return cached.take(n).map(Ticker.bare).toList();
    }
    final all = await api.tickers()
      ..sort((a, b) => b.quoteVolume.compareTo(a.quoteVolume));
    final top = all.where((t) => t.mainstream).take(100).toList();
    await p.setStringList(_symbolsKey, top.map((t) => t.symbol).toList());
    await p.setInt(_symbolsAtKey, now.millisecondsSinceEpoch);
    return top.take(n).toList();
  }

  /// Runs a scan if alerts are on and a new candle has opened since the last one.
  /// Returns setups that match and haven't been reported before, best first.
  static Future<List<ScanResult>> runDue({BinanceApi? api, DateTime? now}) async {
    api ??= BinanceApi();
    now ??= DateTime.now();
    final p = await _prefs();
    final s = await settings();
    if (s == null) return const [];
    final last = p.getInt(_lastRunKey);
    if (last != null &&
        s.frame.bucketOf(DateTime.fromMillisecondsSinceEpoch(last)) == s.frame.bucketOf(now)) {
      return const []; // same candle as last time: nothing new to count
    }

    final pairs = await _universe(p, api, s.universe, now);
    final candlesBySymbol = <String, List<Candle>>{};
    final results = await scan(
      pairs,
      s.frame,
      api: api,
      concurrency: 4,
      checkHigher: s._checksHigher,
      onCandles: (symbol, candles) => candlesBySymbol[symbol] = candles,
    );
    await p.setInt(_lastRunKey, now.millisecondsSinceEpoch);

    final seen = _loadSeen(p, now);
    final fresh = <ScanResult>[];
    for (final r in results.where(s.matches)) {
      final candles = candlesBySymbol[r.ticker.symbol];
      if (candles == null) continue;
      final key = setupKey(r, s.frame, candles);
      if (seen.containsKey(key)) continue;
      seen[key] = now.millisecondsSinceEpoch;
      fresh.add(r);
    }
    await p.setString(_seenKey, jsonEncode(seen));
    return fresh;
  }

  /// Seen keys from the last 3 days; older ones are dropped so the list stays small.
  static Map<String, int> _loadSeen(SharedPreferences p, DateTime now) {
    final raw = p.getString(_seenKey);
    final all = raw == null ? <String, dynamic>{} : jsonDecode(raw) as Map<String, dynamic>;
    final cutoff = now.subtract(const Duration(days: 3)).millisecondsSinceEpoch;
    return {
      for (final e in all.entries)
        if ((e.value as int) > cutoff) e.key: e.value as int,
    };
  }
}
