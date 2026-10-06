import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../api.dart';
import '../candles.dart';
import '../live.dart';
import 'source.dart';

/// One outcome of a Polymarket market as a candle source. Polymarket has no OHLC,
/// so candles are built from sampled price history.
class PolymarketSource implements CandleSource {
  PolymarketSource({
    required this.marketId,
    required this.tokenId,
    required this.question,
    required this.outcome,
    PolymarketApi? api,
  }) : _api = api ?? PolymarketApi();

  final String marketId;
  final String tokenId;
  final String question;
  final String outcome;
  final PolymarketApi _api;

  @override
  String get id => 'polymarket:$tokenId';
  @override
  String get title => question;
  @override
  String get subtitle => 'Polymarket · $outcome';

  @override
  List<Timeframe> get timeframes => const [Timeframe.m5, Timeframe.m15, Timeframe.h1, Timeframe.h4, Timeframe.d1];
  @override
  Timeframe get defaultFrame => Timeframe.h1;
  @override
  (double, double)? get bounds => (0.005, 0.995);

  @override
  String format(double price) => '${(price * 100).toStringAsFixed(1)}%';

  /// Sample spacing giving ≥5 samples per candle, and a window of ~72 candles.
  /// startTs/endTs windows are capped at ~15 days by the API, hence `interval=1m` for daily.
  static (int fidelity, Duration lookback) _plan(Timeframe f) => switch (f) {
        Timeframe.m1 || Timeframe.m5 => (1, const Duration(hours: 6)),
        Timeframe.m15 => (1, const Duration(hours: 18)),
        Timeframe.h1 => (5, const Duration(days: 3)),
        Timeframe.h4 => (15, const Duration(days: 12)),
        Timeframe.d1 => (60, const Duration(days: 30)),
      };

  @override
  Future<List<Candle>> history(Timeframe frame) async {
    final (fidelity, lookback) = _plan(frame);
    final now = DateTime.now();
    final points = await _api.pricePoints(tokenId, {
      if (lookback > const Duration(days: 14))
        'interval': '1m'
      else ...{
        'startTs': '${now.subtract(lookback).millisecondsSinceEpoch ~/ 1000}',
        'endTs': '${now.millisecondsSinceEpoch ~/ 1000}',
      },
      'fidelity': '$fidelity',
    });
    return buildCandles(points, frame);
  }

  @override
  Future<List<Candle>> since(DateTime from) async {
    final now = DateTime.now();
    final start = now.difference(from) > const Duration(days: 14) ? now.subtract(const Duration(days: 14)) : from;
    final points = await _api.pricePoints(tokenId, {
      'startTs': '${start.millisecondsSinceEpoch ~/ 1000}',
      'endTs': '${now.millisecondsSinceEpoch ~/ 1000}',
      'fidelity': now.difference(start) > const Duration(days: 2) ? '15' : '1',
    });
    return buildCandles(points, Timeframe.m1);
  }

  @override
  LiveConnection live(Timeframe frame) => _PolymarketLive(tokenId);

  @override
  Map<String, dynamic> toJson() => {
        'venue': 'polymarket',
        'marketId': marketId,
        'tokenId': tokenId,
        'question': question,
        'outcome': outcome,
      };

  factory PolymarketSource.fromJson(Map<String, dynamic> j) => PolymarketSource(
        marketId: j['marketId'] as String,
        tokenId: j['tokenId'] as String,
        question: j['question'] as String,
        outcome: j['outcome'] as String,
      );
}

class _PolymarketLive implements LiveConnection {
  _PolymarketLive(this.tokenId) {
    _socket = ReconnectingSocket(
      'wss://ws-subscriptions-clob.polymarket.com/ws/market',
      onOpen: (WebSocket ws) => ws.add(jsonEncode({'assets_ids': [tokenId], 'type': 'market'})),
      keepAliveText: 'PING',
      onMessage: _onMessage,
    )..start();
  }

  final String tokenId;
  late final ReconnectingSocket _socket;
  final _state = QuoteState();
  final _updates = StreamController<LiveUpdate>.broadcast();

  void _onMessage(String data) {
    if (data == 'PONG') return;
    final Object? decoded;
    try {
      decoded = jsonDecode(data);
    } on FormatException {
      return;
    }
    for (final e in (decoded is List ? decoded : [decoded]).whereType<Map<String, dynamic>>()) {
      final q = _state.apply(e, tokenId, DateTime.now());
      if (q != null) _updates.add(TickUpdate(q.time, q.price, bid: _state.bid, ask: _state.ask));
    }
  }

  @override
  Stream<LiveUpdate> get updates => _updates.stream;
  @override
  ValueListenable<LiveStatus> get status => _socket.status;
  @override
  void resume() => _socket.start();
  @override
  Future<void> pause() => _socket.pause();
  @override
  Future<void> close() async {
    await _socket.close();
    await _updates.close();
  }
}
