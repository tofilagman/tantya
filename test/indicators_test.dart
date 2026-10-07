import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/elliott.dart';
import 'package:tantya/indicators.dart';
import 'package:tantya/setup.dart';

final t0 = DateTime(2026, 10, 7);
List<Candle> closes(List<double> xs) =>
    [for (var i = 0; i < xs.length; i++) Candle(t0.add(Duration(hours: i)), xs[i], xs[i], xs[i], xs[i])];

/// 30 flat candles (so MACD is defined), then straight legs through [path], [bars] each.
List<Candle> impulse(List<double> path, {int bars = 12}) {
  final xs = <double>[for (var i = 0; i < 30; i++) path.first];
  for (var leg = 1; leg < path.length; leg++) {
    for (var i = 1; i <= bars; i++) {
      xs.add(path[leg - 1] + (path[leg] - path[leg - 1]) * i / bars);
    }
  }
  return closes(xs);
}

/// Scenario with pivots at the leg boundaries [impulse] produced.
Scenario scenarioOn(List<double> path, ScenarioKind kind, {int bars = 12}) {
  const labels = ['', '1', '2', '3', '4', '5', 'A', 'B'];
  final pts = [
    for (var i = 0; i < path.length; i++)
      WavePoint(Pivot(29 + i * bars, path[i], high: i > 0 && path[i] > path[i - 1]),
          kind == ScenarioKind.impulse ? labels[i] : ['', 'A', 'B', 'C'][i]),
  ];
  return Scenario(
    kind: kind,
    trend: path[1] > path[0] ? 1 : -1,
    points: pts,
    next: 'x',
    direction: 1,
    targetLow: 0,
    targetHigh: 1,
    invalidation: 0,
    score: 0.7,
    notes: [],
    legBars: 5,
  );
}

void main() {
  test('ema: SMA seed, then 2/(n+1) smoothing', () {
    final e = ema([1, 2, 3, 4, 5, 6], 3);
    expect(e.take(2), [null, null]);
    expect(e.skip(2).toList(), [2, 3, 4, 5]);
    expect(ema([1, 2], 3), [null, null]);
  });

  test('MACD on a steady trend settles at the EMA lag gap: 7, with zero histogram', () {
    final m = Macd.of(closes([for (var i = 1; i <= 80; i++) i.toDouble()]));
    expect(m.line[24], isNull);
    expect(m.line[25], closeTo(7, 1e-9));
    expect(m.line.last, closeTo(7, 1e-9));
    expect(m.signal.last, closeTo(7, 1e-9));
    expect(m.histogram.last, closeTo(0, 1e-9));
    expect(m.signal[32], isNull, reason: 'needs 9 MACD values');
    expect(m.signal[33], isNotNull);
  });

  group('MacdState', () {
    // On a steady linear trend MACD settles onto its signal (histogram → 0), so these
    // fixtures accelerate or decelerate to give the histogram a clear direction.
    test('accelerating rally after a decline: bullish cross, rising, agrees with long', () {
      final xs = [for (var i = 0; i < 60; i++) 100.0 - i] + [for (var i = 1; i <= 25; i++) 41.0 + 0.1 * i * i];
      final st = MacdState.of(Macd.of(closes(xs)))!;
      expect(st.bullish, isTrue);
      expect(st.rising, isTrue);
      expect(st.crossAgo, isNotNull);
      expect(st.verdictFor(Side.long), MacdVerdict.agree);
      expect(st.verdictFor(Side.short), MacdVerdict.against);
    });
    test('decline that is slowing down: negative but rising, "turning" for a long', () {
      // Accelerating fall, then still falling but more slowly.
      final xs = [for (var i = 0; i < 60; i++) 100.0 - 0.01 * i * i] + [for (var i = 1; i <= 4; i++) 64.0 - 0.1 * i];
      final st = MacdState.of(Macd.of(closes(xs)))!;
      expect(st.histogram, lessThan(0));
      expect(st.rising, isTrue);
      expect(st.verdictFor(Side.long), MacdVerdict.turning);
      expect(st.verdictFor(Side.short), MacdVerdict.agree);
    });
    test('not enough candles', () {
      expect(MacdState.of(Macd.of(closes([1, 2, 3]))), isNull);
    });
  });

  group('macdNotes', () {
    test('textbook impulse: wave 3 peaks, wave 5 diverges', () {
      // W3 is the steepest leg; W5 makes a new high on a gentler slope.
      const path = [0.20, 0.30, 0.25, 0.41, 0.35, 0.45];
      final c = impulse(path);
      final notes = macdNotes(scenarioOn(path, ScenarioKind.impulse), Macd.of(c), c);
      expect(notes.any((n) => n.good == true && n.text.contains('peaks in wave 3')), isTrue);
      expect(notes.any((n) => n.good == true && n.text.startsWith('Divergence')), isTrue);
    });

    test('a weak wave 3 is flagged', () {
      // W3 barely beats W1 while W5 is the steep one.
      const path = [0.20, 0.30, 0.26, 0.33, 0.31, 0.50];
      final c = impulse(path);
      final notes = macdNotes(scenarioOn(path, ScenarioKind.impulse), Macd.of(c), c);
      expect(notes.any((n) => n.good == false && n.text.contains('Wave 3')), isTrue);
      expect(notes.any((n) => n.text.startsWith('Divergence')), isFalse);
    });

    test('correction: C weaker than A past A\'s end supports the count', () {
      const path = [0.50, 0.40, 0.45, 0.38];
      final c = impulse(path);
      final note = macdNotes(scenarioOn(path, ScenarioKind.correction), Macd.of(c), c).single;
      expect(note.text, contains('weaker MACD than wave A'));
      expect(note.good, isTrue);
    });

    test('correction: a C stronger than A warns the correction may not be done', () {
      const path = [0.50, 0.45, 0.47, 0.30];
      final c = impulse(path);
      final note = macdNotes(scenarioOn(path, ScenarioKind.correction), Macd.of(c), c).single;
      expect(note.text, contains('stronger MACD than wave A'));
      expect(note.good, isFalse);
    });

    test('wave 5 as strong as wave 3: no divergence, may extend', () {
      const path = [0.20, 0.30, 0.25, 0.41, 0.35, 0.55];
      final c = impulse(path);
      final notes = macdNotes(scenarioOn(path, ScenarioKind.impulse), Macd.of(c), c);
      expect(notes.any((n) => n.good == false && n.text.startsWith('No divergence')), isTrue);
    });
  });
}
