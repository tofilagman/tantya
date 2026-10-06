import 'package:intl/intl.dart';

final _compact = NumberFormat.compactSimpleCurrency(locale: 'en_US', decimalDigits: 1);

/// $1.2M style — Polymarket volumes are in USDC.
String money(double v) => _compact.format(v);

String shortDate(DateTime? d) => d == null ? '—' : DateFormat.yMMMd().format(d.toLocal());

/// Signed percentage-point change, e.g. "+3.2 pts".
String points(double change) {
  final v = change * 100;
  final sign = v > 0 ? '+' : (v < 0 ? '−' : '');
  return '$sign${v.abs().toStringAsFixed(1)} pts';
}
