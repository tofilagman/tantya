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
