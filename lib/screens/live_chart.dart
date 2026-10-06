import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../candles.dart';
import '../elliott.dart';
import '../setup.dart';

final _up = Colors.green.shade600;
final _down = Colors.red.shade400;

/// Exchange-style candlestick chart with the Elliott Wave count and trade setup
/// drawn on top, projected into empty space right of the last candle.
///
/// Drag to pan, pinch to zoom, long-press for a crosshair, double-tap to reset.
class LiveChart extends StatefulWidget {
  const LiveChart({
    super.key,
    required this.candles,
    required this.frame,
    required this.format,
    this.scenario,
    this.setup,
    this.revision = 0,
  });

  final List<Candle> candles;
  final Timeframe frame;
  final String Function(double) format;
  final Scenario? scenario;
  final TradeSetup? setup;

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
      return GestureDetector(
        onScaleStart: (_) => _visibleAtScaleStart = _visible,
        onScaleUpdate: (d) => setState(() {
          final n = widget.candles.length.toDouble();
          if (d.pointerCount > 1) {
            _visible = (_visibleAtScaleStart / d.scale).clamp(15.0, math.max(15.0, math.min(300.0, n)));
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
            geo: geo,
            cross: _cross,
            revision: widget.revision,
            scheme: theme.colorScheme,
            text: theme.textTheme.labelSmall!,
          ),
        ),
      );
    });
  }

  /// Empty candle slots on the right: room for the projection when there is one.
  int get _future => widget.scenario != null ? 16 : 3;
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
    final volH = hasVolume ? plot.height * 0.16 : 0.0;
    final priceRect = Rect.fromLTRB(plot.left, plot.top + 8, plot.right, plot.bottom - volH - 6);

    // Price range: visible candles plus the levels we draw, so targets and stops stay on screen.
    var lo = double.infinity, hi = -double.infinity;
    for (var i = from; i <= to; i++) {
      lo = math.min(lo, candles[i].low);
      hi = math.max(hi, candles[i].high);
    }
    final levels = <double>[
      if (setup != null) ...[setup!.stop, setup!.tp1, setup!.tp2],
      if (setup == null && scenario != null) ...[scenario!.targetLow, scenario!.targetHigh],
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
    if (hasVolume) _volume(canvas, plot, volH, from, to);
    if (scenario != null) _zone(canvas, priceRect, y);
    _candles(canvas, from, to, y);
    if (scenario != null) _waves(canvas, y);
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
  void _waves(Canvas canvas, double Function(double) y) {
    final s = scenario!;
    final line = Paint()
      ..color = scheme.primary
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i < s.points.length; i++) {
      final p = s.points[i].pivot;
      final o = Offset(geo.x(p.index), y(p.price));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(path, line);

    // Projection: from the wave's start to the middle of the target zone, ~legBars ahead.
    final last = s.points.last.pivot;
    final aheadIdx = math.min(candles.length - 1 + s.legBars, candles.length - 1 + 14);
    final from = Offset(geo.x(last.index), y(last.price));
    final to = Offset(geo.x(aheadIdx), y(s.targetMid));
    _dashed(canvas, from, to, scheme.primary, 1.6);
    _arrowHead(canvas, from, to, scheme.primary);
    // After a finished ABC the prior trend resumes: the next impulse's wave 1.
    _bubble(canvas, to + Offset(0, s.direction > 0 ? -14 : 14), s.next == 'new trend' ? '1' : s.next, dashed: true);

    for (final w in s.points) {
      if (w.label.isEmpty) continue;
      final o = Offset(geo.x(w.pivot.index), y(w.pivot.price));
      _bubble(canvas, o + Offset(0, w.pivot.high ? -14 : 14), w.label);
    }
  }

  void _bubble(Canvas canvas, Offset c, String label, {bool dashed = false}) {
    final tp = _tp(label, text.copyWith(color: dashed ? scheme.primary : scheme.onPrimary, fontWeight: FontWeight.w700));
    final r = math.max(tp.width, tp.height) / 2 + 3;
    canvas.drawCircle(c, r, Paint()..color = dashed ? scheme.surface : scheme.primary);
    if (dashed) {
      canvas.drawCircle(c, r, Paint()
        ..color = scheme.primary
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
      _tag(canvas, x, y(st.stop), 'SL ${format(st.stop)}', _down, r);
      _tag(canvas, x, y(st.tp1), 'TP1 ${format(st.tp1)}', _up, r);
      _tag(canvas, x, y(st.tp2), 'TP2 ${format(st.tp2)}', _up.withValues(alpha: 0.75), r);
    }
    final last = candles.last;
    final ly = y(last.close);
    _dashed(canvas, Offset(geo.plot.left, ly), Offset(geo.plot.right, ly), (last.up ? _up : _down).withValues(alpha: 0.6), 1);
    _tag(canvas, x, ly, format(last.close), last.up ? _up : _down, r);
  }

  void _tag(Canvas canvas, double x, double yPos, String label, Color color, Rect r) {
    final cy = yPos.clamp(r.top, r.bottom);
    final tp = _tp(label, text.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10));
    final box = Rect.fromLTWH(x - 3, cy - tp.height / 2 - 2, math.max(tp.width + 6, _Geometry.axisW - 2), tp.height + 4);
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(3)), Paint()..color = color);
    tp.paint(canvas, Offset(x, cy - tp.height / 2));
  }

  void _times(Canvas canvas, Size size, int from, int to) {
    final fmt = frame.size >= const Duration(hours: 4)
        ? DateFormat.MMMd()
        : frame.size >= const Duration(hours: 1)
            ? DateFormat('E HH:mm')
            : DateFormat.Hm();
    final muted = text.copyWith(color: scheme.onSurfaceVariant);
    final every = math.max(1, (geo.visible / 4).round());
    for (var i = from; i <= to; i++) {
      if (i % every != 0) continue;
      final tp = _tp(fmt.format(candles[i].start), muted);
      final x = geo.x(i) - tp.width / 2;
      if (x < 0 || x + tp.width > geo.plot.right) continue;
      tp.paint(canvas, Offset(x, geo.plot.bottom + 3));
    }
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
        '${c.volume > 0 ? '  Vol ${NumberFormat.compact().format(c.volume)}' : ''}';
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
      old.cross != cross ||
      old.geo.visible != geo.visible ||
      old.geo.offset != geo.offset ||
      old.geo.size != geo.size ||
      old.scheme != scheme;
}
