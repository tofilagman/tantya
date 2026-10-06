import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/elliott.dart';
import 'package:tantya/mtf.dart';
import 'package:tantya/scan_alerts.dart';
import 'package:tantya/scanner.dart';
import 'package:tantya/setup.dart';
import 'package:tantya/sources/binance.dart';

/// Textbook impulse ending at [end], one candle per hour.
List<Candle> series(DateTime end) {
  const path = <double>[20000, 30000, 25000, 41000, 35000, 45000, 44500];
  const bars = 8;
  final n = (path.length - 1) * bars;
  final out = <Candle>[];
  double prev = path.first;
  for (var leg = 1; leg < path.length; leg++) {
    for (var i = 1; i <= bars; i++) {
      final p = path[leg - 1] + (path[leg] - path[leg - 1]) * i / bars;
      final t = end.subtract(Duration(hours: n - out.length - 1));
      out.add(Candle(t, prev, (p > prev ? p : prev) + 100, (p < prev ? p : prev) - 100, p));
      prev = p;
    }
  }
  return out;
}

/// Like an exchange: history up to the first [end] stays fixed; later calls append
/// flat candles up to the new [end] instead of moving past swings in time.
class FakeBinance extends BinanceApi {
  FakeBinance(this.end) : _base = series(end);
  DateTime end;
  final List<Candle> _base;
  int klineCalls = 0;
  int tickerCalls = 0;

  @override
  Future<List<Ticker>> tickers() async {
    tickerCalls++;
    return [
      Ticker(symbol: 'BTCUSDT', last: 1, changePct: 0, quoteVolume: 100, trades: 1),
      Ticker(symbol: 'ETHUSDT', last: 1, changePct: 0, quoteVolume: 50, trades: 1),
      Ticker(symbol: 'USDCUSDT', last: 1, changePct: 0, quoteVolume: 999, trades: 1), // stable: skipped
    ];
  }

  @override
  Future<List<Candle>> klines(String symbol, Timeframe frame, {int limit = 300, DateTime? start}) async {
    klineCalls++;
    final out = [..._base];
    while (out.last.start.add(const Duration(hours: 1)).isBefore(end.add(const Duration(minutes: 1)))) {
      final c = out.last.close;
      out.add(Candle(out.last.start.add(const Duration(hours: 1)), c, c + 50, c - 50, c));
    }
    return out;
  }
}

/// Accept-everything criteria so the synthetic series always qualifies.
ScanAlertSettings loose() =>
    ScanAlertSettings(frame: Timeframe.h1, universe: 2, minRR: 0, minFit: 0, maxProgress: 1.01);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('off by default: no scan, no requests', () async {
    final api = FakeBinance(DateTime(2026, 10, 6, 10, 5));
    expect(await ScanAlertStore.runDue(api: api, now: DateTime(2026, 10, 6, 10, 5)), isEmpty);
    expect(api.klineCalls, 0);
  });

  test('notifies a setup once, scans once per candle, then stays quiet for the same wave', () async {
    await ScanAlertStore.enable(loose());
    final t1 = DateTime(2026, 10, 6, 10, 5);
    final api = FakeBinance(t1);

    final first = await ScanAlertStore.runDue(api: api, now: t1);
    expect(first.map((r) => r.ticker.symbol), unorderedEquals(['BTCUSDT', 'ETHUSDT']));
    expect(api.tickerCalls, 1);

    // Same 1h candle: skipped entirely.
    final calls = api.klineCalls;
    expect(await ScanAlertStore.runDue(api: api, now: t1.add(const Duration(minutes: 15))), isEmpty);
    expect(api.klineCalls, calls);

    // Next candle, same wave (just shifted one candle): already reported.
    final t2 = t1.add(const Duration(hours: 1));
    api.end = t2;
    expect(await ScanAlertStore.runDue(api: api, now: t2), isEmpty);
    expect(api.klineCalls, greaterThan(calls));
    expect(api.tickerCalls, 1, reason: 'pair list is cached for a day');
  });

  test('higher timeframe disagreeing blocks the alert; agreeing lets it through', () async {
    final t = DateTime(2026, 10, 6, 10, 5);
    // 1h: the impulse-up series (setup is SHORT, expecting wave A down).
    // 4h: a mirrored series whose primary count expects price to rise → conflict.
    final api = MirrorHigher(t);
    await ScanAlertStore.enable(ScanAlertSettings(
        frame: Timeframe.h1, universe: 2, minRR: 0, minFit: 0, maxProgress: 1.01, htfAgreeOnly: true));
    expect(await ScanAlertStore.runDue(api: api, now: t), isEmpty);
    expect(api.higherCalls, greaterThan(0));

    SharedPreferences.setMockInitialValues({});
    await ScanAlertStore.enable(ScanAlertSettings(
        frame: Timeframe.h1, universe: 2, minRR: 0, minFit: 0, maxProgress: 1.01, htfAgreeOnly: true));
    final same = FakeBinance(t);
    final fresh = await ScanAlertStore.runDue(api: same, now: t);
    expect(fresh, isNotEmpty);
    expect(fresh.every((r) => r.htf?.verdict == HtfVerdict.agree), isTrue);
  });

  test('filters apply', () async {
    await ScanAlertStore.enable(ScanAlertSettings(frame: Timeframe.h1, universe: 2, minFit: 0.999));
    final t = DateTime(2026, 10, 6, 10, 5);
    expect(await ScanAlertStore.runDue(api: FakeBinance(t), now: t), isEmpty);
  });

  test('turning off stops scans', () async {
    await ScanAlertStore.enable(loose());
    await ScanAlertStore.disable();
    final api = FakeBinance(DateTime(2026, 10, 6, 10, 5));
    expect(await ScanAlertStore.runDue(api: api, now: DateTime(2026, 10, 6, 10, 5)), isEmpty);
    expect(api.klineCalls, 0);
  });

  test('settings round-trip and data estimate', () async {
    final s = ScanAlertSettings(frame: Timeframe.h4, universe: 50, bias: Bias.short, agreeOnly: true);
    await ScanAlertStore.enable(s);
    final back = (await ScanAlertStore.settings())!;
    expect(back.toJson(), s.toJson());
    // 6 scans/day × 50 pairs × 15 KB × 2 (higher timeframe checked) + 2 MB ticker list
    expect(s.megabytesPerDay, closeTo(6 * 50 * 15 * 2 / 1024 + 2, 1e-9));
    final noHtf = ScanAlertSettings(frame: Timeframe.h4, universe: 50, htfAgreeOnly: false);
    expect(noHtf.megabytesPerDay, closeTo(6 * 50 * 15 / 1024 + 2, 1e-9));
    // 1D has no higher timeframe, so nothing extra to fetch.
    final daily = ScanAlertSettings(frame: Timeframe.d1, universe: 50);
    expect(daily.megabytesPerDay, closeTo(1 * 50 * 15 / 1024 + 2, 1e-9));
    // Alerts saved before the option existed keep the old behaviour.
    final legacy = Map.of(noHtf.toJson())..remove('htfAgreeOnly');
    expect(ScanAlertSettings.fromJson(legacy).htfAgreeOnly, isFalse);
    expect(ScanAlertSettings.frames, isNot(contains(Timeframe.m5)));
  });

  test('matches: bias, R:R, agreement, fit and freshness', () {
    final candles = series(DateTime(2026, 10, 6, 10));
    final r = evaluatePair(Ticker.bare('BTCUSDT'), candles)!;
    final side = r.setup.side == Side.long ? Bias.long : Bias.short;
    final other = side == Bias.long ? Bias.short : Bias.long;
    ScanAlertSettings s({Bias bias = Bias.all, double minRR = 0, double minFit = 0, double maxProgress = 1.01, bool htf = false}) =>
        ScanAlertSettings(frame: Timeframe.h1, universe: 1, bias: bias, minRR: minRR, minFit: minFit,
            maxProgress: maxProgress, htfAgreeOnly: htf);
    expect(s().matches(r), isTrue);
    expect(s(bias: side).matches(r), isTrue);
    expect(s(bias: other).matches(r), isFalse);
    expect(s(minRR: r.setup.rr1 + 0.01).matches(r), isFalse);
    expect(s(minFit: r.scenario.score + 0.01).matches(r), isFalse);
    expect(s(maxProgress: r.progress).matches(r), isFalse);
    expect(s(htf: true).matches(r), isFalse, reason: 'not checked yet');
    r.htf = const HtfCheck(Timeframe.h4, null, HtfVerdict.conflict);
    expect(s(htf: true).matches(r), isFalse);
    r.htf = const HtfCheck(Timeframe.h4, null, HtfVerdict.agree);
    expect(s(htf: true).matches(r), isTrue);
  });

  test('setup key survives candle-index shifts', () {
    final a = series(DateTime(2026, 10, 6, 10));
    final b = [Candle(a.first.start.subtract(const Duration(hours: 1)), 20000, 20000, 20000, 20000), ...a];
    final ra = evaluatePair(Ticker.bare('BTCUSDT'), a)!;
    final rb = evaluatePair(Ticker.bare('BTCUSDT'), b)!;
    expect(ra.scenario.points.last.pivot.index, isNot(rb.scenario.points.last.pivot.index));
    expect(setupKey(ra, Timeframe.h1, a), setupKey(rb, Timeframe.h1, b));
    expect(ra.scenario, isA<Scenario>());
  });
}

/// Same as [FakeBinance] on the scanned timeframe; one degree up, a mirror image
/// (price reflected), so the higher timeframe expects the opposite direction.
class MirrorHigher extends FakeBinance {
  MirrorHigher(super.end);
  int higherCalls = 0;

  @override
  Future<List<Candle>> klines(String symbol, Timeframe frame, {int limit = 300, DateTime? start}) async {
    final base = await super.klines(symbol, frame, limit: limit, start: start);
    if (frame == Timeframe.h1) return base;
    higherCalls++;
    const k = 70000.0; // reflect around a level so every swing flips
    return [for (final c in base) Candle(c.start, k - c.open, k - c.low, k - c.high, k - c.close)];
  }
}

