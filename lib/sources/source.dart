import 'package:flutter/foundation.dart';

import '../candles.dart';
import '../live.dart';
import 'binance.dart';
import 'polymarket_source.dart';

sealed class LiveUpdate {}

/// A whole candle, as streamed by sources with real OHLC (Binance).
class CandleUpdate extends LiveUpdate {
  CandleUpdate(this.candle);
  final Candle candle;
}

/// A single price, folded into candles by the chart (Polymarket).
class TickUpdate extends LiveUpdate {
  TickUpdate(this.time, this.price, {this.bid, this.ask});
  final DateTime time;
  final double price;
  final double? bid;
  final double? ask;
}

/// An open live stream for one instrument and timeframe.
abstract class LiveConnection {
  Stream<LiveUpdate> get updates;
  ValueListenable<LiveStatus> get status;
  void resume();
  Future<void> pause();
  Future<void> close();
}

/// Anything the chart and the Elliott Wave engine can run on.
abstract class CandleSource {
  /// Stable id for storage, e.g. `binance:BTCUSDT`.
  String get id;
  String get title;
  String get subtitle;

  List<Timeframe> get timeframes;
  Timeframe get defaultFrame;

  /// Price limits for bounded instruments (Polymarket's 0–1); null for open-ended.
  (double, double)? get bounds;

  String format(double price);

  Future<List<Candle>> history(Timeframe frame);

  /// Fine-grained candles from [from] until now, for checking which level was hit first.
  Future<List<Candle>> since(DateTime from);

  LiveConnection live(Timeframe frame);

  Map<String, dynamic> toJson();

  static CandleSource fromJson(Map<String, dynamic> j) => switch (j['venue']) {
        'binance' => BinanceSource.fromJson(j),
        'polymarket' => PolymarketSource.fromJson(j),
        _ => throw FormatException('Unknown venue ${j['venue']}'),
      };
}
