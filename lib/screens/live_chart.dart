import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../candles.dart';
import '../burst.dart';
import '../elliott.dart';
import '../indicators.dart';
import '../layers.dart';
import '../volume_profile.dart';
import '../setup.dart';

final _up = Colors.green.shade600;
final _down = Colors.red.shade400;

/// Exchange-style candlestick chart with the Elliott Wave count and trade setup
/// drawn on top, projected into empty space right of the last candle.
///
/// Drag to pan, pinch to zoom, long-press for a crosshair, double-tap to reset.
/// With a mouse: scroll wheel zooms, and the crosshair follows the pointer.
class LiveChart extends StatefulWidget {
  const LiveChart({
    super.key,
    required this.candles,
    required this.frame,
    required this.format,
    this.scenario,
    this.setup,
    this.revision = 0,
    this.primaryColor,
    this.layers = const [],
    this.confluence = const [],
    this.macd,
    this.oscillators = const [],
    this.emas = const [],
    this.buckets,
    this.bursts = const [],
    this.bounds,
  });

  final List<Candle> candles;
  final Timeframe frame;
  final String Function(double) format;
  final Scenario? scenario;
  final TradeSetup? setup;

  /// Colour of this chart's own count (its timeframe's colour); theme primary if null.
  final Color? primaryColor;

  /// Other timeframes' counts, drawn under this chart's own, each in its own colour.
  final List<Layer> layers;

  /// Overlapping same-direction targets, outlined on the chart.
  final List<Confluence> confluence;

  /// MACD for [candles], shown in a pane under the volume; null hides the pane.
  final Macd? macd;

  /// RSI / CCI panes, stacked under the MACD pane (any combination can be shown).
  final List<Oscillator> oscillators;

  /// EMA lines drawn over the candles (3/25/50/100/200, Binance colours).
  final List<EmaLine> emas;

  /// Volume by price per year, drawn as stacked horizontal bars from the left edge.
  final VolumeBuckets? buckets;

  /// Momentum bursts to mark on their candles.
  final List<BurstEvent> bursts;

  /// Price limits (Polymarket's 0–1) that projected prices are kept inside.
  final (double, double)? bounds;

  /// Bumped by the parent whenever [candles] changed in place, to force a repaint.
  final int revision;

  @override
  State<LiveChart> createState() => _LiveChartState();
}

class _LiveChartState extends State<LiveChart> {
  static const _defaultVisible = 60.0;
  double _visible = _defaultVisible;

  /// Candles scrolled back from the newest; 0 = following live.
  double _offset = 0;
  double _visibleAtScaleStart = _defaultVisible;
  int? _cross;

  @override
  void didUpdateWidget(LiveChart old) {
    super.didUpdateWidget(old);
    if (old.frame != widget.frame) {
      _visible = _defaultVisible;
      _offset = 0;
      _cross = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      final geo = _Geometry(size, widget.candles.length, _visible, _offset, future: _future);
      final n = widget.candles.length.toDouble();
      final maxVisible = math.max(15.0, math.min(300.0, n));
      final chart = GestureDetector(
        onScaleStart: (_) => _visibleAtScaleStart = _visible,
        onScaleUpdate: (d) => setState(() {
          if (d.pointerCount > 1 || d.scale != 1) {
            // Two fingers, or a trackpad pinch.
            _visible = (_visibleAtScaleStart / d.scale).clamp(15.0, maxVisible);
          }
          _offset = (_offset + d.focalPointDelta.dx / geo.slot).clamp(0.0, math.max(0.0, n - _visible));
        }),
        onDoubleTap: () => setState(() {
          _visible = _defaultVisible;
          _offset = 0;
        }),
        onLongPressStart: (d) => setState(() => _cross = geo.indexAt(d.localPosition.dx)),
        onLongPressMoveUpdate: (d) => setState(() => _cross = geo.indexAt(d.localPosition.dx)),
        onLongPressEnd: (_) => setState(() => _cross = null),
        child: CustomPaint(
          size: size,
          painter: _ChartPainter(
            candles: widget.candles,
            frame: widget.frame,
            format: widget.format,
            scenario: widget.scenario,
            setup: widget.setup,
            primaryColor: widget.primaryColor ?? theme.colorScheme.primary,
            layers: widget.layers,
            confluence: widget.confluence,
            macd: widget.macd,
            oscillators: widget.oscillators,
            emas: widget.emas,
            buckets: widget.buckets,
            bursts: widget.bursts,
            bounds: widget.bounds,
            geo: geo,
            cross: _cross,
            revision: widget.revision,
            scheme: theme.colorScheme,
            text: theme.textTheme.labelSmall!,
          ),
        ),
      );
      return Listener(
        // Mouse wheel zooms around the latest candles; claim the event so the page
        // around the chart doesn't scroll at the same time.
        onPointerSignal: (e) {
          if (e is! PointerScrollEvent) return;
          GestureBinding.instance.pointerSignalResolver.register(e, (_) {
            setState(() {
              _visible = (_visible * math.exp(e.scrollDelta.dy / 500)).clamp(15.0, maxVisible);
              _offset = _offset.clamp(0.0, math.max(0.0, n - _visible));
            });
          });
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.precise,
          onHover: (e) {
            final i = geo.indexAt(e.localPosition.dx);
            if (i != _cross) setState(() => _cross = i);
          },
          onExit: (_) => setState(() => _cross = null),
          child: chart,
        ),
      );
    });
  }

  /// Empty candle slots on the right: room for the projection when there is one.
  /// Empty candle slots on the right: room for the projected path when there is one.
  int get _future => widget.scenario != null ? 24 : (widget.layers.isNotEmpty ? 16 : 3);
}

/// Maps candle indexes and prices to pixels.
class _Geometry {
  _Geometry(this.size, this.n, this.visible, this.offset, {required this.future}) {
    plot = Rect.fromLTWH(0, 0, size.width - axisW, size.height - timeH);
    slot = plot.width / (visible + future);
    first = n - visible - offset;
  }

  static const axisW = 64.0;
  static const timeH = 18.0;

  final Size size;
  final int n;
  final double visible;
  final double offset;
  final int future;
  late final Rect plot;
  late final double slot;

  /// Fractional index of the leftmost slot.
  late final double first;

  double x(num index) => plot.left + (index - first + 0.5) * slot;
  int? indexAt(double px) {
    final i = (px / slot + first - 0.5).round();
    return i >= 0 && i < n ? i : null;
  }

  int get firstVisible => math.max(0, first.floor());
  int get lastVisible => math.min(n - 1, (first + visible + future).ceil());
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.candles,
    required this.frame,
    required this.format,
    required this.scenario,
    required this.setup,
    required this.primaryColor,
    required this.layers,
    required this.confluence,
    required this.macd,
    required this.oscillators,
    required this.emas,
    required this.buckets,
    required this.bursts,
    required this.bounds,
    required this.geo,
    required this.cross,
    required this.revision,
    required this.scheme,
    required this.text,
  });

  final List<Candle> candles;
  final Timeframe frame;
  final String Function(double) format;
  final Scenario? scenario;
  final TradeSetup? setup;
  final Color primaryColor;
  final List<Layer> layers;
  final List<Confluence> confluence;
  final Macd? macd;
  final List<Oscillator> oscillators;
  final List<EmaLine> emas;
  final VolumeBuckets? buckets;
  final List<BurstEvent> bursts;
  final (double, double)? bounds;
  final _Geometry geo;
  final int? cross;
  final int revision;
  final ColorScheme scheme;
  final TextStyle text;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;
    final plot = geo.plot;
    final from = geo.firstVisible, to = geo.lastVisible;
    final hasVolume = candles.any((c) => c.volume > 0);
    // Indicator panes stack upward from the bottom: MACD (if shown), then RSI / CCI.
    final paneCount = (macd != null ? 1 : 0) + oscillators.length;
    final hasPane = paneCount > 0;
    final paneH = (plot.height * (paneCount <= 1 ? 0.2 : 0.15)).clamp(56.0, 140.0);
    const paneGap = 10.0;
    Rect paneRect(int k) {
      final bottom = plot.bottom - k * (paneH + paneGap);
      return Rect.fromLTRB(plot.left, bottom - paneH, plot.right, bottom);
    }
    final panesTop = hasPane ? paneRect(paneCount - 1).top : plot.bottom;
    final volBase = Rect.fromLTRB(plot.left, plot.top, plot.right, panesTop - (hasPane ? 8 : 0));
    final volH = hasVolume ? plot.height * (hasPane ? 0.12 : 0.16) : 0.0;
    // With EMAs on, a strip at the top holds their legend (two lines on phones) so it
    // never covers candles or wave labels.
    final legendH = emas.isEmpty ? 0.0 : _emaLegendHeight(plot.width);
    final priceRect = Rect.fromLTRB(plot.left, plot.top + 8 + legendH, plot.right, volBase.bottom - volH - 6);

    // Price range: visible candles plus the levels we draw, so targets and stops stay on screen.
    var lo = double.infinity, hi = -double.infinity;
    for (var i = from; i <= to; i++) {
      lo = math.min(lo, candles[i].low);
      hi = math.max(hi, candles[i].high);
    }
    final projected = scenario == null ? const <ProjectedWave>[] : projectPath(scenario!);
    final levels = <double>[
      if (setup != null) ...[setup!.stop, setup!.tp1, setup!.tp2],
      if (setup == null && scenario != null) ...[scenario!.targetLow, scenario!.targetHigh],
      // The whole projected path stays in the price area, not over the volume/MACD panes.
      for (final w in projected) _bounded(w.price),
    ];
    if (geo.offset < 1) {
      for (final l in levels) {
        lo = math.min(lo, l);
        hi = math.max(hi, l);
      }
    }
    if (hi <= lo) {
      hi = lo + (lo.abs() * 0.01 + 1e-6);
    }
    final pad = (hi - lo) * 0.06;
    lo -= pad;
    hi += pad;
    double y(double p) => priceRect.bottom - (p - lo) / (hi - lo) * priceRect.height;

    canvas.save();
    canvas.clipRect(plot);
    _grid(canvas, priceRect, lo, hi, y);
    if (hasVolume) _volume(canvas, volBase, volH, from, to);
    if (buckets != null) _buckets(canvas, priceRect, y);
    // Bottom-up order matches the menu: MACD, RSI, CCI from top to bottom.
    var k = paneCount - 1;
    if (macd != null) _macd(canvas, paneRect(k--), from, to);
    for (final o in oscillators) {
      _oscillator(canvas, paneRect(k--), o, from, to);
    }
    if (scenario != null) _zone(canvas, priceRect, y);
    _candles(canvas, from, to, y);
    for (final e in emas) {
      _ema(canvas, e, from, to, y);
    }
    if (emas.isNotEmpty) _emaLegend(canvas, Rect.fromLTRB(plot.left, plot.top + 2, plot.right, priceRect.top));
    for (final b in bursts) {
      if (b.index >= from && b.index <= to) _burstMark(canvas, b, y);
    }
    // Other timeframes' points can sit outside this chart's price range; keep their
    // lines and labels out of the volume and indicator panes.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(plot.left, plot.top, plot.right, priceRect.bottom + 6));
    for (final l in layers) {
      _layer(canvas, priceRect, l, y);
    }
    canvas.restore();
    if (scenario != null) _waves(canvas, y, projected);
    for (final c in confluence) {
      _confluence(canvas, priceRect, c, y);
    }
    canvas.restore();

    _axis(canvas, size, priceRect, lo, hi, y);
    _times(canvas, size, from, to);
    if (cross != null) _crosshair(canvas, cross!, y);
  }

  void _grid(Canvas canvas, Rect r, double lo, double hi, double Function(double) y) {
    final paint = Paint()
      ..color = scheme.outlineVariant.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (final p in _ticks(lo, hi)) {
      canvas.drawLine(Offset(r.left, y(p)), Offset(r.right, y(p)), paint);
    }
  }

  static List<double> _ticks(double lo, double hi) {
    final raw = (hi - lo) / 5;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final step = [1, 2, 2.5, 5, 10].map((m) => m * mag).firstWhere((s) => s >= raw);
    return [for (var p = (lo / step).ceil() * step; p <= hi; p += step) p];
  }

  void _candles(Canvas canvas, int from, int to, double Function(double) y) {
    final body = math.max(1.0, geo.slot * 0.68);
    final wick = Paint()..strokeWidth = math.max(1.0, geo.slot * 0.1);
    final fill = Paint();
    for (var i = from; i <= to; i++) {
      final c = candles[i];
      final color = c.up ? _up : _down;
      final x = geo.x(i);
      wick.color = color;
      fill.color = color;
      canvas.drawLine(Offset(x, y(c.high)), Offset(x, y(c.low)), wick);
      final top = y(math.max(c.open, c.close));
      final bottom = math.max(top + 1, y(math.min(c.open, c.close)));
      canvas.drawRect(Rect.fromLTRB(x - body / 2, top, x + body / 2, bottom), fill);
    }
  }

  void _volume(Canvas canvas, Rect plot, double h, int from, int to) {
    var maxV = 0.0;
    for (var i = from; i <= to; i++) {
      maxV = math.max(maxV, candles[i].volume);
    }
    if (maxV == 0) return;
    final body = math.max(1.0, geo.slot * 0.68);
    final paint = Paint();
    for (var i = from; i <= to; i++) {
      final c = candles[i];
      final bh = c.volume / maxV * h;
      paint.color = (c.up ? _up : _down).withValues(alpha: 0.3);
      final x = geo.x(i);
      canvas.drawRect(Rect.fromLTRB(x - body / 2, plot.bottom - bh, x + body / 2, plot.bottom), paint);
    }
  }

  /// Target band in the future area plus stop/target lines across the chart.
  void _zone(Canvas canvas, Rect r, double Function(double) y) {
    final s = scenario!;
    final color = s.direction > 0 ? _up : _down;
    final startX = geo.x(candles.length - 1);
    canvas.drawRect(
      Rect.fromLTRB(startX, y(s.targetHigh), r.right, y(s.targetLow)),
      Paint()..color = color.withValues(alpha: 0.12),
    );
    final st = setup;
    if (st != null) {
      _dashed(canvas, Offset(r.left, y(st.stop)), Offset(r.right, y(st.stop)), _down, 1.2);
      _dashed(canvas, Offset(startX, y(st.tp1)), Offset(r.right, y(st.tp1)), _up.withValues(alpha: 0.9), 1);
      _dashed(canvas, Offset(startX, y(st.tp2)), Offset(r.right, y(st.tp2)), _up.withValues(alpha: 0.6), 1);
    } else {
      _dashed(canvas, Offset(r.left, y(s.invalidation)), Offset(r.right, y(s.invalidation)), _down, 1.2);
    }
  }

  /// The count's zigzag with wave labels, and the projected next wave.
  void _waves(Canvas canvas, double Function(double) y, List<ProjectedWave> projected) {
    final s = scenario!;
    final pc = primaryColor;
    final line = Paint()
      ..color = pc
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i < s.points.length; i++) {
      final p = s.points[i].pivot;
      final o = Offset(geo.x(p.index), y(p.price));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(path, line);

    // Projected path: the next few waves the count implies, each with its price. Later
    // steps are fainter and thinner: each one rests on the guesses before it.
    if (projected.isNotEmpty) {
      final base = candles.length - 1;
      final room = (geo.future - 3).toDouble();
      final squeeze = math.min(1.0, room / projected.last.barsAhead); // keep the path in the empty space
      var from = Offset(geo.x(s.points.last.pivot.index), y(s.points.last.pivot.price));
      final bubbles = <(Offset, String, Color)>[];
      for (var k = 0; k < projected.length; k++) {
        final w = projected[k];
        final price = _bounded(w.price);
        final to = Offset(geo.x(base + w.barsAhead * squeeze), y(price));
        final c = pc.withValues(alpha: k == 0 ? 1.0 : (k == 1 ? 0.7 : 0.5));
        _dashed(canvas, from, to, c, k == 0 ? 1.8 : 1.3);
        _arrowHead(canvas, from, to, c);
        final up = to.dy < from.dy;
        final bubbleAt = to + Offset(0, up ? -14 : 14);
        _bubble(canvas, bubbleAt, w.label, c, dashed: true);
        bubbles.add((bubbleAt, format(price), c));
        from = to;
      }
      // Tags after all bubbles, so each can steer clear of every bubble and earlier tag.
      final taken = [for (final (b, _, _) in bubbles) Rect.fromCircle(center: b, radius: 11)];
      for (final (b, label, c) in bubbles) {
        taken.add(_priceTag(canvas, b, label, c, avoid: taken));
      }
    }

    for (final w in s.points) {
      if (w.label.isEmpty) continue;
      final o = Offset(geo.x(w.pivot.index), y(w.pivot.price));
      _bubble(canvas, o + Offset(0, w.pivot.high ? -14 : 14), w.label, pc);
    }
  }

  /// Another timeframe's count, placed by time: its swings, labels, projected next wave
  /// and target band, thinner than this chart's own count so the two read apart.
  void _layer(Canvas canvas, Rect r, Layer l, double Function(double) y) {
    final c = l.color;
    double x(DateTime t) => geo.x(indexAt(candles, frame, t));
    final line = Paint()
      ..color = c.withValues(alpha: 0.9)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i < l.points.length; i++) {
      final o = Offset(x(l.points[i].time), y(l.points[i].price));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(path, line);

    final s = l.scenario;
    final startX = geo.x(candles.length - 1);
    final band = Rect.fromLTRB(startX, y(s.targetHigh), r.right, y(s.targetLow));
    canvas.drawRect(band, Paint()..color = c.withValues(alpha: 0.10));
    _dashed(canvas, band.topLeft, band.topRight, c.withValues(alpha: 0.7), 1);
    _dashed(canvas, band.bottomLeft, band.bottomRight, c.withValues(alpha: 0.7), 1);

    final last = l.points.last;
    final from = Offset(x(last.time), y(last.price));
    final to = Offset(math.min(x(l.projectTo), r.right - 14), y(s.targetMid));
    _dashed(canvas, from, to, c, 1.3);
    _arrowHead(canvas, from, to, c);
    final lb = to + Offset(0, s.direction > 0 ? -12 : 12);
    _bubble(canvas, lb, s.next == 'new trend' ? '1' : s.next, c, dashed: true, small: true);
    _priceTag(canvas, lb, format(_bounded(s.targetMid)), c, small: true);
    // Further out than this chart's own labels (14px), so when both counts mark the same
    // swing the two bubbles stack instead of covering each other.
    for (final p in l.points) {
      if (p.label.isEmpty) continue;
      _bubble(canvas, Offset(x(p.time), y(p.price)) + Offset(0, p.high ? -30 : 30), p.label, c, small: true);
    }
    _offscreenTarget(canvas, r, l, y);
  }

  /// A longer timeframe's target is often far outside a short chart's price range;
  /// pin a marker to the top or bottom edge so it's clear where that count points.
  void _offscreenTarget(Canvas canvas, Rect r, Layer l, double Function(double) y) {
    final s = l.scenario;
    final above = y(s.targetLow) < r.top; // whole zone above the view
    final below = y(s.targetHigh) > r.bottom; // whole zone below
    if (!above && !below) return;
    final edge = above ? r.top + 2 : r.bottom - 2;
    final near = above ? s.targetLow : s.targetHigh;
    final label = '${l.frame.label} ${above ? '↑' : '↓'} ${format(near)}';
    final tp = _tp(label, text.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 9));
    // Stack markers by timeframe so several off-screen targets don't overlap.
    final row = layers.where((o) {
      final oa = y(o.scenario.targetLow) < r.top, ob = y(o.scenario.targetHigh) > r.bottom;
      return (above ? oa : ob) && o.frame.index < l.frame.index;
    }).length;
    final top = above ? edge + row * (tp.height + 6) : edge - (row + 1) * (tp.height + 6);
    final box = Rect.fromLTWH(r.right - tp.width - 12, top, tp.width + 8, tp.height + 4);
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(3)), Paint()..color = l.color);
    tp.paint(canvas, Offset(box.left + 4, box.top + 2));
  }

  /// Where two timeframes' targets overlap: an outlined band with the timeframes named.
  void _confluence(Canvas canvas, Rect r, Confluence cf, double Function(double) y) {
    final startX = geo.x(candles.length - 1);
    final band = Rect.fromLTRB(startX, y(cf.high), r.right, y(cf.low));
    canvas.drawRect(band, Paint()..color = scheme.onSurface.withValues(alpha: 0.08));
    canvas.drawRect(
      band,
      Paint()
        ..color = scheme.onSurface.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final tp = _tp(
      '${cf.frames.map((f) => f.label).join('+')} ${cf.direction > 0 ? '↑' : '↓'}',
      text.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w700, fontSize: 9),
    );
    tp.paint(canvas, Offset(band.left + 3, band.top + 2));
  }

  double _bounded(double p) => bounds == null ? p : p.clamp(bounds!.$1, bounds!.$2);

  double _inside(double left, double width) =>
      left.clamp(geo.plot.left, math.max(geo.plot.left, geo.plot.right - 2 - width));

  /// The projected price beside a wave bubble ("where it will hit"). Tries right of the
  /// bubble, then left, then above and below, skipping spots that overlap [avoid] or
  /// leave the chart. Returns where it went.
  Rect _priceTag(Canvas canvas, Offset bubble, String label, Color color,
      {bool small = false, List<Rect> avoid = const []}) {
    final tp = _tp(label, text.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: small ? 8.5 : 9.5));
    final w = tp.width + 6, h = tp.height + 2;
    final gap = small ? 10.0 : 13.0;
    final candidates = [
      Rect.fromLTWH(bubble.dx + gap, bubble.dy - h / 2, w, h), // right
      Rect.fromLTWH(bubble.dx - gap - w, bubble.dy - h / 2, w, h), // left
      // Above/below are centred on the bubble, nudged back inside the chart near its edge.
      Rect.fromLTWH(_inside(bubble.dx - w / 2, w), bubble.dy - gap - h, w, h), // above
      Rect.fromLTWH(_inside(bubble.dx - w / 2, w), bubble.dy + gap, w, h), // below
    ];
    bool fits(Rect r) => r.left >= geo.plot.left && r.right <= geo.plot.right - 2 && r.top >= geo.plot.top;
    final box = candidates.firstWhere(
      (r) => fits(r) && !avoid.any((a) => a.overlaps(r)),
      orElse: () => candidates.firstWhere(fits, orElse: () => candidates[1]),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(3)), Paint()..color = scheme.surface.withValues(alpha: 0.9));
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(3)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    tp.paint(canvas, Offset(box.left + 3, box.center.dy - tp.height / 2));
    return box;
  }

  void _bubble(Canvas canvas, Offset c, String label, Color color, {bool dashed = false, bool small = false}) {
    // Dark text on light fills (amber, yellow) so labels stay readable.
    final onColor = color.computeLuminance() > 0.45 ? Colors.black : Colors.white;
    final tp = _tp(label, text.copyWith(
      color: dashed ? color : onColor,
      fontWeight: FontWeight.w700,
      fontSize: small ? 9 : null,
    ));
    final r = math.max(tp.width, tp.height) / 2 + (small ? 2 : 3);
    canvas.drawCircle(c, r, Paint()..color = dashed ? scheme.surface : color);
    if (dashed) {
      canvas.drawCircle(c, r, Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
    }
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  void _arrowHead(Canvas canvas, Offset from, Offset to, Color color) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const len = 8.0;
    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(to.dx - len * math.cos(angle - 0.45), to.dy - len * math.sin(angle - 0.45))
      ..lineTo(to.dx - len * math.cos(angle + 0.45), to.dy - len * math.sin(angle + 0.45))
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _axis(Canvas canvas, Size size, Rect r, double lo, double hi, double Function(double) y) {
    final x = geo.plot.right + 4;
    final muted = text.copyWith(color: scheme.onSurfaceVariant);
    final st = setup;
    final tagYs = [
      y(candles.last.close),
      if (st != null) ...[y(st.stop), y(st.tp1), y(st.tp2)],
    ];
    for (final p in _ticks(lo, hi)) {
      final tp = _tp(format(p), muted);
      final ty = y(p) - tp.height / 2;
      // Skip grid labels a tag would cover.
      if (tagYs.any((t) => (t - y(p)).abs() < tp.height + 2)) continue;
      if (ty > r.top - 4 && ty + tp.height < r.bottom + 4) tp.paint(canvas, Offset(x, ty));
    }
    // Tags, drawn last so they sit above the tick labels.
    if (st != null) {
      _tag(canvas, size, x, y(st.stop), 'SL ${format(st.stop)}', _down, r);
      _tag(canvas, size, x, y(st.tp1), 'TP1 ${format(st.tp1)}', _up, r);
      _tag(canvas, size, x, y(st.tp2), 'TP2 ${format(st.tp2)}', _up.withValues(alpha: 0.75), r);
    }
    final last = candles.last;
    final ly = y(last.close);
    _dashed(canvas, Offset(geo.plot.left, ly), Offset(geo.plot.right, ly), (last.up ? _up : _down).withValues(alpha: 0.6), 1);
    _tag(canvas, size, x, ly, format(last.close), last.up ? _up : _down, r);
  }

  /// A price tag on the axis. Wider labels ("TP2 88239.74", or larger system fonts)
  /// grow leftwards over the plot instead of running off the screen.
  void _tag(Canvas canvas, Size size, double x, double yPos, String label, Color color, Rect r) {
    final cy = yPos.clamp(r.top, r.bottom);
    final tp = _tp(label, text.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10));
    final width = math.max(tp.width + 6, _Geometry.axisW - 2);
    final left = math.min(x - 3, size.width - width);
    final box = Rect.fromLTWH(left, cy - tp.height / 2 - 2, width, tp.height + 4);
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(3)), Paint()..color = color);
    tp.paint(canvas, Offset(left + 3, cy - tp.height / 2));
  }

  void _times(Canvas canvas, Size size, int from, int to) {
    final fmt = frame.size >= const Duration(hours: 4)
        ? DateFormat.MMMd()
        : frame.size >= const Duration(hours: 1)
            ? DateFormat('E HH:mm')
            : DateFormat.Hm();
    final muted = text.copyWith(color: scheme.onSurfaceVariant);
    final every = math.max(1, (geo.visible / 4).round());
    var lastRight = double.negativeInfinity;
    for (var i = from; i <= to; i++) {
      if (i % every != 0) continue;
      final tp = _tp(fmt.format(candles[i].start), muted);
      final x = geo.x(i) - tp.width / 2;
      if (x < 0 || x + tp.width > geo.plot.right) continue;
      // Skip a label that would touch the previous one (long formats, big fonts, zoomed out).
      if (x < lastRight + 8) continue;
      tp.paint(canvas, Offset(x, geo.plot.bottom + 3));
      lastRight = x + tp.width;
    }
  }

  /// A burst marker: an amber bolt tag above the candle (up burst) or below (down).
  void _burstMark(Canvas canvas, BurstEvent b, double Function(double) y) {
    final c = candles[b.index];
    final x = geo.x(b.index);
    const amber = Color(0xFFFFA000);
    final tp = _tp('⚡${b.dir > 0 ? '↑' : '↓'}', text.copyWith(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w800));
    final w = tp.width + 6, h = tp.height + 2;
    final top = b.dir > 0 ? y(c.high) - h - 4 : y(c.low) + 4;
    final box = Rect.fromLTWH(x - w / 2, top, w, h);
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(3)), Paint()..color = amber);
    tp.paint(canvas, Offset(box.left + 3, box.top + 1));
  }

  /// Volume buckets: per price level, one stacked bar segment per year (oldest first),
  /// growing from the left edge over the oldest candles. Each year's POC is marked.
  void _buckets(Canvas canvas, Rect r, double Function(double) y) {
    final b = buckets!;
    final all = b.combined;
    if (all.isEmpty) return;
    final maxV = all.reduce(math.max);
    if (maxV <= 0) return;
    final width = r.width * 0.28;
    for (var i = 0; i < b.bins; i++) {
      final top = y(b.priceHigh(i)), bottom = y(b.priceLow(i));
      if (bottom < r.top || top > r.bottom) continue; // outside the visible price range
      var x = r.left;
      for (var k = 0; k < b.years.length; k++) {
        final w = b.years[k].volume[i] / maxV * width;
        if (w <= 0) continue;
        canvas.drawRect(Rect.fromLTRB(x, top + 0.5, x + w, bottom - 0.5),
            Paint()..color = yearColor(k, b.years.length).withValues(alpha: 0.33));
        x += w;
      }
    }
    for (var k = 0; k < b.years.length; k++) {
      final py = y(b.priceMid(b.years[k].pocBin));
      if (py < r.top || py > r.bottom) continue;
      final c = yearColor(k, b.years.length);
      canvas.drawLine(Offset(r.left, py), Offset(r.left + width, py), Paint()
        ..color = c
        ..strokeWidth = 1.5);
      final tp = _tp('${b.years[k].year} POC', text.copyWith(color: c, fontSize: 8, fontWeight: FontWeight.w700));
      tp.paint(canvas, Offset(r.left + width + 3, py - tp.height / 2));
    }
  }

  /// An EMA line through the candles, labelled with its period at the right end.
  void _ema(Canvas canvas, EmaLine e, int from, int to, double Function(double) y) {
    final path = Path();
    var started = false;
    Offset? last;
    for (var i = from; i <= to; i++) {
      final v = e.values[i];
      if (v == null) continue;
      final o = Offset(geo.x(i), y(v));
      started ? path.lineTo(o.dx, o.dy) : path.moveTo(o.dx, o.dy);
      started = true;
      last = o;
    }
    if (last == null) return;
    canvas.drawPath(path, Paint()
      ..color = e.color
      ..strokeWidth = e.width
      ..style = PaintingStyle.stroke);
  }

  /// Binance-style EMA legend across the top of the price area: "EMA(3) 70,703.40 …",
  /// each in its line's colour. Values at the crosshair candle, else the latest.
  /// Height the legend needs at [width]: one line per row of labels that fits.
  double _emaLegendHeight(double width) {
    var x = 4.0, lines = 1;
    double h = 0;
    for (final e in emas) {
      final tp = _tp('EMA(${e.period}) ${format(e.values.lastWhere((v) => v != null, orElse: () => 0) ?? 0)}',
          text.copyWith(fontSize: 9, fontWeight: FontWeight.w600));
      h = tp.height;
      if (x + tp.width > width - 4 && x > 4) {
        lines++;
        x = 4;
      }
      x += tp.width + 10;
    }
    return lines * (h + 1) + 4;
  }

  void _emaLegend(Canvas canvas, Rect r) {
    if (emas.isEmpty) return;
    final i = cross ?? candles.length - 1;
    var x = r.left + 4;
    var y = r.top;
    for (final e in emas) {
      final v = i < e.values.length ? e.values[i] : null;
      final tp = _tp('EMA(${e.period}) ${v == null ? '—' : format(v)}',
          text.copyWith(color: e.color, fontSize: 9, fontWeight: FontWeight.w600));
      if (x + tp.width > r.right - 4 && x > r.left + 4) {
        x = r.left + 4; // wrap onto a second line on narrow charts
        y += tp.height + 1;
      }
      final bg = Rect.fromLTWH(x - 2, y, tp.width + 4, tp.height);
      canvas.drawRect(bg, Paint()..color = scheme.surface.withValues(alpha: 0.75));
      tp.paint(canvas, Offset(x, y));
      x += tp.width + 10;
    }
  }

  /// RSI / CCI pane: one line with guide levels (e.g. 30/70, ±100), shaded beyond them.
  void _oscillator(Canvas canvas, Rect r, Oscillator o, int from, int to) {
    var lo = o.min ?? double.infinity, hi = o.max ?? -double.infinity;
    if (o.min == null || o.max == null) {
      for (final g in o.guides) {
        lo = math.min(lo, g);
        hi = math.max(hi, g);
      }
      for (var i = from; i <= to; i++) {
        final v = o.values[i];
        if (v == null) continue;
        lo = math.min(lo, v);
        hi = math.max(hi, v);
      }
      final pad = (hi - lo) * 0.08;
      lo -= pad;
      hi += pad;
    }
    if (hi <= lo) return;
    double y(double v) => r.bottom - (v - lo) / (hi - lo) * r.height;

    canvas.drawLine(Offset(r.left, r.top - 4), Offset(r.right, r.top - 4),
        Paint()..color = scheme.outlineVariant.withValues(alpha: 0.5));
    final outer = o.guides.isEmpty ? null : (o.guides.reduce(math.min), o.guides.reduce(math.max));
    if (outer != null) {
      // Shade the band between the outer guides, where the indicator usually lives.
      canvas.drawRect(Rect.fromLTRB(r.left, y(outer.$2), r.right, y(outer.$1)),
          Paint()..color = scheme.primary.withValues(alpha: 0.05));
    }
    for (final g in o.guides) {
      _dashed(canvas, Offset(r.left, y(g)), Offset(r.right, y(g)), scheme.outlineVariant, 1);
    }

    final path = Path();
    var started = false;
    for (var i = from; i <= to; i++) {
      final v = o.values[i];
      if (v == null) continue;
      final p = Offset(geo.x(i), y(v));
      started ? path.lineTo(p.dx, p.dy) : path.moveTo(p.dx, p.dy);
      started = true;
    }
    canvas.drawPath(path, Paint()
      ..color = scheme.onSurface
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke);

    final last = o.values.lastWhere((v) => v != null, orElse: () => null);
    final tp = _tp('${o.name}${last == null ? '' : '  ${last.toStringAsFixed(0)}'}',
        text.copyWith(color: scheme.onSurfaceVariant, fontSize: 9));
    tp.paint(canvas, Offset(r.left + 4, r.top - 2));
  }

  /// MACD pane: histogram bars (paler while shrinking), MACD line, signal line, zero line.
  void _macd(Canvas canvas, Rect r, int from, int to) {
    final m = macd!;
    var lo = 0.0, hi = 0.0; // always include zero
    for (var i = from; i <= to; i++) {
      for (final v in [m.line[i], m.signal[i], m.histogram[i]]) {
        if (v == null) continue;
        lo = math.min(lo, v);
        hi = math.max(hi, v);
      }
    }
    if (hi - lo == 0) return;
    final pad = (hi - lo) * 0.1;
    lo -= pad;
    hi += pad;
    double y(double v) => r.bottom - (v - lo) / (hi - lo) * r.height;

    canvas.drawLine(Offset(r.left, r.top - 4), Offset(r.right, r.top - 4),
        Paint()..color = scheme.outlineVariant.withValues(alpha: 0.5));
    canvas.drawLine(Offset(r.left, y(0)), Offset(r.right, y(0)),
        Paint()
          ..color = scheme.outlineVariant
          ..strokeWidth = 1);

    final body = math.max(1.0, geo.slot * 0.6);
    final bar = Paint();
    for (var i = from; i <= to; i++) {
      final h = m.histogram[i];
      if (h == null) continue;
      final prev = i > 0 ? m.histogram[i - 1] : null;
      final growing = prev == null || h.abs() >= prev.abs();
      bar.color = (h >= 0 ? _up : _down).withValues(alpha: growing ? 0.75 : 0.35);
      final x = geo.x(i);
      canvas.drawRect(Rect.fromLTRB(x - body / 2, math.min(y(0), y(h)), x + body / 2, math.max(y(0), y(h))), bar);
    }

    void line(List<double?> vs, Color c) {
      final path = Path();
      var started = false;
      for (var i = from; i <= to; i++) {
        final v = vs[i];
        if (v == null) continue;
        final o = Offset(geo.x(i), y(v));
        started ? path.lineTo(o.dx, o.dy) : path.moveTo(o.dx, o.dy);
        started = true;
      }
      canvas.drawPath(path, Paint()
        ..color = c
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke);
    }

    line(m.line, _macdLine);
    line(m.signal, _signalLine);

    final last = m.histogram.lastWhere((v) => v != null, orElse: () => null);
    final tp = _tp(
      'MACD ${Macd.fast},${Macd.slow},${Macd.smooth}${last == null ? '' : '  hist ${_fmtMacd(last)}'}',
      text.copyWith(color: scheme.onSurfaceVariant, fontSize: 9),
    );
    tp.paint(canvas, Offset(r.left + 4, r.top - 2));
  }

  // Neutral on purpose: blue, orange, red and yellow are taken by the timeframe overlays.
  Color get _macdLine => scheme.onSurface;
  Color get _signalLine => scheme.onSurfaceVariant.withValues(alpha: 0.6);

  /// MACD values are price differences: tiny for cheap coins, large for BTC.
  String _fmtMacd(double v) {
    final a = v.abs();
    final digits = a >= 100 ? 1 : a >= 1 ? 2 : a >= 0.01 ? 4 : 6;
    return v.toStringAsFixed(digits);
  }

  void _crosshair(Canvas canvas, int i, double Function(double) y) {
    final c = candles[i];
    final x = geo.x(i);
    final paint = Paint()
      ..color = scheme.onSurface.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(x, geo.plot.top), Offset(x, geo.plot.bottom), paint);
    canvas.drawLine(Offset(geo.plot.left, y(c.close)), Offset(geo.plot.right, y(c.close)), paint);
    final change = c.open == 0 ? 0 : (c.close - c.open) / c.open * 100;
    final label = '${DateFormat('MMM d HH:mm').format(c.start)}\n'
        'O ${format(c.open)}  H ${format(c.high)}\n'
        'L ${format(c.low)}  C ${format(c.close)}\n'
        '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%'
        '${c.volume > 0 ? '  Vol ${NumberFormat.compact().format(c.volume)}' : ''}'
        '${macd?.histogram[i] != null ? '\nMACD ${_fmtMacd(macd!.line[i]!)}  sig ${_fmtMacd(macd!.signal[i]!)}' : ''}'
        '${[for (final o in oscillators) if (o.values[i] != null) '${o.name.split(' ').first} ${o.values[i]!.toStringAsFixed(1)}'].map((t) => '\n$t').join()}';
    final tp = _tp(label, text.copyWith(color: scheme.onInverseSurface, height: 1.3));
    final left = x < geo.plot.width / 2 ? geo.plot.right - tp.width - 16 : 8.0;
    final box = Rect.fromLTWH(left, 8, tp.width + 12, tp.height + 10);
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(6)), Paint()..color = scheme.inverseSurface.withValues(alpha: 0.92));
    tp.paint(canvas, Offset(left + 6, 13));
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Color color, double width) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width;
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    for (var d = 0.0; d < total; d += 9) {
      canvas.drawLine(a + dir * d, a + dir * math.min(d + 5, total), paint);
    }
  }

  TextPainter _tp(String s, TextStyle style) =>
      TextPainter(text: TextSpan(text: s, style: style), textDirection: ui.TextDirection.ltr)..layout();

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.revision != revision ||
      old.candles != candles ||
      old.scenario != scenario ||
      old.setup != setup ||
      old.primaryColor != primaryColor ||
      old.layers != layers ||
      old.confluence != confluence ||
      old.macd != macd ||
      old.oscillators != oscillators ||
      old.emas != emas ||
      old.buckets != buckets ||
      old.bursts != bursts ||
      old.bounds != bounds ||
      old.cross != cross ||
      old.geo.visible != geo.visible ||
      old.geo.offset != geo.offset ||
      old.geo.size != geo.size ||
      old.scheme != scheme;
}

/// A line-type indicator for the lower pane (RSI, CCI).
class Oscillator {
  const Oscillator(this.name, this.values, {this.guides = const [], this.min, this.max});

  /// Shown in the pane's corner, e.g. "RSI 14".
  final String name;
  final List<double?> values;

  /// Reference levels, e.g. [30, 50, 70] for RSI or [-100, 0, 100] for CCI.
  final List<double> guides;

  /// Fixed scale (RSI is always 0–100); null autoscales.
  final double? min, max;
}

/// An EMA over the candles, in its own colour (Binance's palette).
class EmaLine {
  const EmaLine(this.period, this.values, {required this.color, this.width = 1.2});
  final int period;
  final List<double?> values;
  final Color color;
  final double width;
}

/// EMA colours as on Binance's chart, so the app reads the same as the exchange.
const emaColors = <int, Color>{
  3: Color(0xFFF0B90B), // yellow
  25: Color(0xFFE84393), // pink
  50: Color(0xFFB39DDB), // purple
  100: Color(0xFFFF6B6B), // red
  200: Color(0xFF4CAF50), // green
};

/// Year colours for the volume buckets, oldest → newest: earthy brown, slate, teal.
/// Muted on purpose: the buckets sit behind the candles.
Color yearColor(int index, int count) {
  const palette = [Color(0xFF8D6E63), Color(0xFF78909C), Color(0xFF26A69A)];
  return palette[(palette.length - count + index).clamp(0, palette.length - 1)];
}

