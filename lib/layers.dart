/// Multi-timeframe overlays: every timeframe's wave count on one chart, one colour
/// per timeframe, plus where their targets coincide (confluence).
library;

import 'dart:math' as math;
import 'dart:ui' show Color;

import 'candles.dart';
import 'elliott.dart';

/// A fixed colour per timeframe, used everywhere (chart layers, chips, tables) so a
/// colour always means the same degree. 1h is a golden yellow: distinct from 15m's orange,
/// but dark enough to read on a white background.
const timeframeColors = <Timeframe, Color>{
  Timeframe.m1: Color(0xFF8E24AA), // purple
  Timeframe.m5: Color(0xFFE53935), // red
  Timeframe.m15: Color(0xFFFB8C00), // orange
  Timeframe.h1: Color(0xFFFBC02D), // yellow
  Timeframe.h4: Color(0xFF1E88E5), // blue
  Timeframe.d1: Color(0xFF00897B), // teal
};

Color colorOf(Timeframe f) => timeframeColors[f]!;

/// One wave point placed in time, so it can be drawn on a chart of any timeframe.
class TimedPoint {
  const TimedPoint(this.time, this.price, this.label, {required this.high});
  final DateTime time;
  final double price;
  final String label;
  final bool high;
}

/// A timeframe's primary count, detached from that timeframe's candle indexes.
class Layer {
  Layer({required this.frame, required this.scenario, required this.points, required this.projectTo});

  final Timeframe frame;
  final Scenario scenario;
  final List<TimedPoint> points;

  /// Where the projected next wave ends, in time (roughly [Scenario.legBars] candles ahead).
  final DateTime projectTo;

  Color get color => colorOf(frame);

  /// [candles] must be the series [scenario] was counted on.
  factory Layer.of(Timeframe frame, Scenario scenario, List<Candle> candles) {
    final pts = [
      for (final w in scenario.points)
        TimedPoint(candles[w.pivot.index].start.add(frame.size ~/ 2), w.pivot.price, w.label, high: w.pivot.high),
    ];
    final last = candles.last.start.add(frame.size ~/ 2);
    return Layer(
      frame: frame,
      scenario: scenario,
      points: pts,
      projectTo: last.add(frame.size * math.min(scenario.legBars, 40)),
    );
  }
}

/// Fractional candle index of [time] in [candles] (candle i spans i-0.5 .. i+0.5, centred
/// on i). Times outside the series are extrapolated by [frame], so points from a longer
/// timeframe can sit off-screen left and projections can run into the future.
double indexAt(List<Candle> candles, Timeframe frame, DateTime time) {
  if (candles.isEmpty) return 0;
  final ms = frame.size.inMilliseconds;
  final t = time.millisecondsSinceEpoch;
  final first = candles.first.start.millisecondsSinceEpoch;
  if (t < first) return (t - first) / ms - 0.5;
  // Binary search for the last candle starting at or before t.
  var lo = 0, hi = candles.length - 1;
  while (lo < hi) {
    final mid = (lo + hi + 1) >> 1;
    if (candles[mid].start.millisecondsSinceEpoch <= t) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }
  return lo + (t - candles[lo].start.millisecondsSinceEpoch) / ms - 0.5;
}

/// Two or more timeframes whose target zones overlap and point the same way.
class Confluence {
  const Confluence(this.frames, this.low, this.high, this.direction);
  final List<Timeframe> frames;
  final double low;
  final double high;
  final int direction;
}

/// Overlaps between same-direction target zones, one per pair of timeframes, widest
/// agreement first. Only real overlaps count: zones that merely touch don't.
List<Confluence> findConfluence(Map<Timeframe, Scenario> byFrame) {
  final entries = byFrame.entries.toList()..sort((a, b) => a.key.index.compareTo(b.key.index));
  final out = <Confluence>[];
  for (var i = 0; i < entries.length; i++) {
    for (var j = i + 1; j < entries.length; j++) {
      final a = entries[i].value, b = entries[j].value;
      if (a.direction != b.direction) continue;
      final low = math.max(a.targetLow, b.targetLow);
      final high = math.min(a.targetHigh, b.targetHigh);
      if (high <= low) continue;
      out.add(Confluence([entries[i].key, entries[j].key], low, high, a.direction));
    }
  }
  // Pairs that span more degrees (e.g. 5m + 4h) are more meaningful than neighbours.
  out.sort((x, y) => (y.frames.last.index - y.frames.first.index)
      .compareTo(x.frames.last.index - x.frames.first.index));
  return out;
}

/// How many timeframes expect up vs down.
({int up, int down}) alignment(Map<Timeframe, Scenario> byFrame) {
  var up = 0, down = 0;
  for (final s in byFrame.values) {
    s.direction > 0 ? up++ : down++;
  }
  return (up: up, down: down);
}
