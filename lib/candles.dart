/// Candle timeframes shared by every data source.
enum Timeframe {
  m1('1m', Duration(minutes: 1)),
  m5('5m', Duration(minutes: 5)),
  m15('15m', Duration(minutes: 15)),
  h1('1h', Duration(hours: 1)),
  h4('4h', Duration(hours: 4)),
  d1('1D', Duration(days: 1));

  const Timeframe(this.label, this.size);
  final String label;
  final Duration size;

  /// The timeframe one degree up, for checking a setup against the bigger picture:
  /// roughly 4–12× larger. Null for the largest.
  Timeframe? get higher => switch (this) {
        Timeframe.m1 => Timeframe.m15,
        Timeframe.m5 => Timeframe.h1,
        Timeframe.m15 => Timeframe.h1,
        Timeframe.h1 => Timeframe.h4,
        Timeframe.h4 => Timeframe.d1,
        Timeframe.d1 => null,
      };

  /// Start of the candle containing [t], aligned to local time so daily candles
  /// start at local midnight rather than UTC midnight.
  DateTime bucketOf(DateTime t) {
    final ms = size.inMilliseconds;
    final offset = t.toLocal().timeZoneOffset.inMilliseconds;
    final local = t.millisecondsSinceEpoch + offset;
    return DateTime.fromMillisecondsSinceEpoch(local ~/ ms * ms - offset);
  }
}

class Candle {
  Candle(this.start, this.open, this.high, this.low, this.close, [this.volume = 0]);

  final DateTime start;
  final double open;
  double high;
  double low;
  double close;

  /// Base-asset volume where the source has it (Binance); 0 otherwise.
  double volume;

  void add(double price) {
    if (price > high) high = price;
    if (price < low) low = price;
    close = price;
  }

  bool get up => close >= open;

  @override
  String toString() => 'Candle($start O$open H$high L$low C$close V$volume)';
}

/// Groups price samples into candles. Each candle opens at the previous close, so
/// there are no false gaps between buckets. Used where the source has no OHLC (Polymarket).
List<Candle> buildCandles(List<({DateTime time, double price})> points, Timeframe frame) {
  final sorted = [...points]..sort((a, b) => a.time.compareTo(b.time));
  final candles = <Candle>[];
  for (final p in sorted) {
    final bucket = frame.bucketOf(p.time);
    final last = candles.isEmpty ? null : candles.last;
    if (last != null && last.start == bucket) {
      last.add(p.price);
    } else {
      final open = last?.close ?? p.price;
      candles.add(Candle(bucket, open, open, open, open)..add(p.price));
    }
  }
  return candles;
}

/// Folds a live price into the series: extends the current candle, or opens a new
/// one when the tick lands in a later bucket. Ticks older than the last candle are
/// ignored. Returns true if the series changed.
bool applyTick(List<Candle> candles, Timeframe frame, DateTime time, double price, {int? maxCandles}) {
  final bucket = frame.bucketOf(time);
  if (candles.isEmpty) {
    candles.add(Candle(bucket, price, price, price, price));
    return true;
  }
  final last = candles.last;
  if (bucket.isBefore(last.start)) return false;
  if (bucket == last.start) {
    last.add(price);
  } else {
    candles.add(Candle(bucket, last.close, last.close, last.close, last.close)..add(price));
    if (maxCandles != null && candles.length > maxCandles) candles.removeAt(0);
  }
  return true;
}

/// Merges a full candle from a source that streams OHLC (Binance): replaces the
/// candle with the same start, or appends a newer one.
bool mergeCandle(List<Candle> candles, Candle c, {int? maxCandles}) {
  if (candles.isNotEmpty) {
    final last = candles.last;
    if (c.start.isBefore(last.start)) return false;
    if (c.start == last.start) {
      candles[candles.length - 1] = c;
      return true;
    }
  }
  candles.add(c);
  if (maxCandles != null && candles.length > maxCandles) candles.removeAt(0);
  return true;
}
