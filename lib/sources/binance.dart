import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../candles.dart';
import '../live.dart';
import 'source.dart';

/// Binance public market data. Uses the market-data-only hosts, which need no key.
class BinanceApi {
  BinanceApi({http.Client? client}) : _client = client ?? http.Client();

  static const rest = 'https://data-api.binance.vision';
  static const stream = 'wss://data-stream.binance.vision/ws';

  final http.Client _client;

  Future<dynamic> _get(String path, Map<String, String> query) async {
    final uri = Uri.parse('$rest$path').replace(queryParameters: query);
    final res = await _client.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('Binance HTTP ${res.statusCode}');
    return jsonDecode(res.body);
  }

  /// Every symbol's 24h ticker. ~2 MB, so callers should cache it.
  Future<List<Ticker>> tickers() async {
    final data = await _get('/api/v3/ticker/24hr', const {}) as List;
    return data.map((t) => Ticker.fromJson(t as Map<String, dynamic>)).where((t) => t.trades > 0).toList();
  }

  Future<List<Candle>> klines(String symbol, Timeframe frame, {int limit = 300, DateTime? start}) async {
    final data = await _get('/api/v3/klines', {
      'symbol': symbol,
      'interval': intervalOf(frame),
      'limit': '$limit',
      if (start != null) 'startTime': '${start.millisecondsSinceEpoch}',
    }) as List;
    return data.map((k) => _kline(k as List)).toList();
  }

  static String intervalOf(Timeframe f) => switch (f) {
        Timeframe.m1 => '1m',
        Timeframe.m5 => '5m',
        Timeframe.m15 => '15m',
        Timeframe.h1 => '1h',
        Timeframe.h4 => '4h',
        Timeframe.d1 => '1d',
      };

  static Candle _kline(List k) => Candle(
        DateTime.fromMillisecondsSinceEpoch(k[0] as int),
        double.parse(k[1] as String),
        double.parse(k[2] as String),
        double.parse(k[3] as String),
        double.parse(k[4] as String),
        double.parse(k[5] as String),
      );
}

class Ticker {
  Ticker({
    required this.symbol,
    required this.last,
    required this.changePct,
    required this.quoteVolume,
    required this.trades,
  });

  final String symbol;
  final double last;
  final double changePct;
  final double quoteVolume;
  final int trades;

  static const _quotes = ['USDT', 'FDUSD', 'USDC', 'BTC', 'ETH', 'BNB', 'TRY', 'EUR', 'BRL', 'JPY'];
  static const _stables = {'USDC', 'FDUSD', 'TUSD', 'USDP', 'DAI', 'BUSD', 'EUR', 'USDE', 'XUSD', 'USD1', 'PYUSD', 'RLUSD', 'USDS', 'BFUSD', 'AEUR', 'EURI', 'FRAX'};

  /// Splits e.g. BTCUSDT into (BTC, USDT); null for an unrecognised quote asset.
  (String, String)? get pair {
    for (final q in _quotes) {
      if (symbol.endsWith(q) && symbol.length > q.length) {
        return (symbol.substring(0, symbol.length - q.length), q);
      }
    }
    return null;
  }

  /// A USDT pair of a real asset: not a stablecoin pair or a leveraged token.
  bool get mainstream {
    final p = pair;
    if (p == null || p.$2 != 'USDT') return false;
    final base = p.$1;
    return !_stables.contains(base) && !RegExp(r'(UP|DOWN|BULL|BEAR)$').hasMatch(base);
  }

  /// A ticker known only by symbol (from a cached pair list); prices unknown.
  factory Ticker.bare(String symbol) => Ticker(symbol: symbol, last: 0, changePct: 0, quoteVolume: 0, trades: 1);

  factory Ticker.fromJson(Map<String, dynamic> j) => Ticker(
        symbol: j['symbol'] as String,
        last: double.tryParse('${j['lastPrice']}') ?? 0,
        changePct: double.tryParse('${j['priceChangePercent']}') ?? 0,
        quoteVolume: double.tryParse('${j['quoteVolume']}') ?? 0,
        trades: (j['count'] as num?)?.toInt() ?? 0,
      );
}

/// Decimal places that read naturally at a given price.
int decimalsFor(double price) {
  final p = price.abs();
  if (p >= 1000) return 2;
  if (p >= 10) return 3;
  if (p >= 1) return 4;
  if (p >= 0.01) return 5;
  return 8;
}

class BinanceSource implements CandleSource {
  BinanceSource(this.symbol, {this.base, this.quote, BinanceApi? api}) : _api = api ?? BinanceApi();

  final String symbol;
  final String? base;
  final String? quote;
  final BinanceApi _api;

  @override
  String get id => 'binance:$symbol';
  @override
  String get title => base != null && quote != null ? '$base/$quote' : symbol;
  @override
  String get subtitle => 'Binance spot';
  @override
  List<Timeframe> get timeframes => Timeframe.values;
  @override
  Timeframe get defaultFrame => Timeframe.h1;
  @override
  (double, double)? get bounds => null;

  @override
  String format(double price) => price.toStringAsFixed(decimalsFor(price));

  @override
  Future<List<Candle>> history(Timeframe frame) => _api.klines(symbol, frame);

  @override
  Future<List<Candle>> since(DateTime from) {
    // Finest interval whose 1000-candle page still reaches back to [from].
    final age = DateTime.now().difference(from);
    final frame = Timeframe.values.firstWhere(
      (f) => f.size * 1000 >= age,
      orElse: () => Timeframe.d1,
    );
    return _api.klines(symbol, frame, limit: 1000, start: from);
  }

  @override
  LiveConnection live(Timeframe frame) => _BinanceLive(symbol, frame);

  @override
  Map<String, dynamic> toJson() => {'venue': 'binance', 'symbol': symbol, 'base': base, 'quote': quote};

  factory BinanceSource.fromJson(Map<String, dynamic> j) =>
      BinanceSource(j['symbol'] as String, base: j['base'] as String?, quote: j['quote'] as String?);
}

class _BinanceLive implements LiveConnection {
  _BinanceLive(String symbol, Timeframe frame) {
    _socket = ReconnectingSocket(
      '${BinanceApi.stream}/${symbol.toLowerCase()}@kline_${BinanceApi.intervalOf(frame)}',
      onMessage: _onMessage,
    )..start();
  }

  late final ReconnectingSocket _socket;
  final _updates = StreamController<LiveUpdate>.broadcast();

  void _onMessage(String data) {
    final Map<String, dynamic> j;
    try {
      j = jsonDecode(data) as Map<String, dynamic>;
    } on FormatException {
      return;
    }
    final k = j['k'];
    if (k is! Map) return;
    _updates.add(CandleUpdate(Candle(
      DateTime.fromMillisecondsSinceEpoch(k['t'] as int),
      double.parse(k['o'] as String),
      double.parse(k['h'] as String),
      double.parse(k['l'] as String),
      double.parse(k['c'] as String),
      double.parse(k['v'] as String),
    )));
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
