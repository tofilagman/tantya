import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/burst.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/indicators.dart';

final t0 = DateTime(2026, 1, 1);

/// Quiet random drift, then (optionally) a sudden heavy move at [at].
List<Candle> series({int n = 300, int? at, int dir = 1, double size = 0.08, int seed = 3}) {
  final rnd = math.Random(seed);
  final out = <Candle>[];
  var p = 100.0;
  for (var i = 0; i < n; i++) {
    var next = p * (1 + (rnd.nextDouble() - 0.5) * 0.004);
    var vol = 100 + rnd.nextDouble() * 20;
    if (at != null && i >= at && i < at + 4) {
      next = p * (1 + dir * size / 4);
      vol = 900;
    }
    out.add(Candle(t0.add(Duration(hours: i)), p, math.max(p, next) * 1.0005, math.min(p, next) * 0.9995, next, vol));
    p = next;
  }
  return out;
}

void main() {
  test('quiet market: no bursts', () {
    final c = series();
    expect(detectBursts(c, Indicators.of(c)), isEmpty);
  });

  test('a heavy fast move up is one burst, up, with volume and momentum', () {
    final c = series(at: 200);
    final b = detectBursts(c, Indicators.of(c));
    expect(b, hasLength(1));
    final e = b.single;
    expect(e.dir, 1);
    expect(e.index, inInclusiveRange(200, 206));
    expect(e.volumeRatio, greaterThan(3));
    expect(e.strength, greaterThanOrEqualTo(3));
    expect(e.origin, lessThan(c[e.index].close));
  });

  test('down burst mirrors', () {
    final c = series(at: 200, dir: -1);
    final e = detectBursts(c, Indicators.of(c)).single;
    expect(e.dir, -1);
    expect(e.origin, greaterThan(c[e.index].close));
  });

  test('volume alone is not enough: a heavy but flat stretch does not fire', () {
    final c = series(at: 200, size: 0.0);
    expect(detectBursts(c, Indicators.of(c)), isEmpty);
  });

  test('no look-ahead: later candles never change earlier bursts', () {
    final full = series(n: 400, at: 200);
    final cut = full.sublist(0, 260);
    final a = detectBursts(cut, Indicators.of(cut));
    final b = detectBursts(full, Indicators.of(full)).where((e) => e.index < 260).toList();
    expect(b.map((e) => (e.index, e.dir)), a.map((e) => (e.index, e.dir)));
  });

  test('stats: continuation, forward returns and the ride-the-burst trade', () {
    // Burst up, then keeps climbing: target hit.
    final c = series(n: 300, at: 200);
    for (var i = 210; i < 300; i++) {
      final p = c[i - 1].close * 1.004;
      c[i] = Candle(c[i].start, c[i - 1].close, p * 1.0005, c[i - 1].close * 0.9995, p, 100);
    }
    final ev = detectBursts(c, Indicators.of(c));
    final s = burstStats(c, ev);
    expect(s.count, ev.length);
    expect(s.continuation(24), 1);
    expect(s.avgForward(24), greaterThan(0));
    expect(s.trades.single, BurstStats.targetR);
    expect(s.tradeWinRate, 1);
  });

  test('a burst that reverses through its origin is stopped out', () {
    final c = series(n: 300, at: 200);
    final e = detectBursts(c, Indicators.of(c)).single;
    final crash = e.origin * 0.98;
    for (var i = e.index + 1; i < 300; i++) {
      c[i] = Candle(c[i].start, crash, crash * 1.001, crash * 0.999, crash, 100);
    }
    final s = burstStats(c, [e]);
    expect(s.trades.single, -1);
    expect(s.continuation(3), 0);
  });
}
