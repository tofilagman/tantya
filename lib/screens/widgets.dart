import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../watchlist.dart';

/// Horizontal probability bar with the percentage at the end.
class ProbabilityBar extends StatelessWidget {
  const ProbabilityBar({super.key, required this.price});

  final double price;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: price.clamp(0, 1),
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            pct(price),
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()]),
          ),
        ),
      ],
    );
  }
}

/// Green/red signed points change; empty when there is no data.
class ChangeText extends StatelessWidget {
  const ChangeText(this.change, {super.key, this.style});

  final double? change;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = change;
    if (c == null || c.abs() < 0.0005) return const SizedBox.shrink();
    final up = c > 0;
    final v = (c * 100).abs().toStringAsFixed(1);
    return Text(
      '${up ? '▲' : '▼'} $v pts',
      style: (style ?? Theme.of(context).textTheme.labelMedium)
          ?.copyWith(color: up ? Colors.green.shade600 : Colors.red.shade400),
    );
  }
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40),
            const SizedBox(height: 12),
            Text('Couldn\'t load: $error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// A running total (e.g. R or P&L after each trade) as a line from zero, green when it
/// ends above zero and red below.
class EquityLine extends StatelessWidget {
  const EquityLine(this.values, {super.key});
  final List<double> values;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _EquityPainter(values, Theme.of(context).colorScheme), size: Size.infinite);
}

class _EquityPainter extends CustomPainter {
  _EquityPainter(this.equity, this.colors);
  final List<double> equity;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final values = [0.0, ...equity];
    final lo = math.min(0.0, values.reduce(math.min)), hi = math.max(0.0, values.reduce(math.max));
    final span = hi - lo == 0 ? 1.0 : hi - lo;
    double y(double v) => size.height - (v - lo) / span * size.height;
    double x(int i) => i / (values.length - 1) * size.width;
    canvas.drawLine(Offset(0, y(0)), Offset(size.width, y(0)),
        Paint()..color = colors.outlineVariant..strokeWidth = 1);
    final path = Path()..moveTo(0, y(0));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(x(i), y(values[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = values.last >= 0 ? Colors.green.shade600 : Colors.red.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_EquityPainter old) => old.equity != equity;
}

