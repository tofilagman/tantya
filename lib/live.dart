import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

enum LiveStatus { connecting, live, offline }

/// A WebSocket that reconnects with exponential backoff until [close] is called.
class ReconnectingSocket {
  ReconnectingSocket(
    this.url, {
    required this.onMessage,
    this.onOpen,
    this.keepAliveText,
  });

  final String url;
  final void Function(String message) onMessage;

  /// Called after each (re)connect, e.g. to send a subscription.
  final void Function(WebSocket socket)? onOpen;

  /// Some servers drop sockets that stay silent; this text is sent every 10s.
  final String? keepAliveText;

  final status = ValueNotifier(LiveStatus.connecting);
  WebSocket? _socket;
  Timer? _ping;
  Timer? _retry;
  int _attempt = 0;
  bool _stopped = false;

  void start() {
    if (_socket != null) return;
    _stopped = false;
    _connect();
  }

  Future<void> _connect() async {
    if (_stopped) return;
    status.value = LiveStatus.connecting;
    try {
      final ws = await WebSocket.connect(url).timeout(const Duration(seconds: 15));
      if (_stopped) {
        await ws.close();
        return;
      }
      _socket = ws;
      // Answers server-initiated ping frames (Binance) and detects dead links.
      ws.pingInterval = const Duration(seconds: 20);
      onOpen?.call(ws);
      if (keepAliveText != null) {
        _ping = Timer.periodic(const Duration(seconds: 10), (_) => ws.add(keepAliveText));
      }
      ws.listen(
        (data) {
          if (data is! String) return;
          _attempt = 0;
          status.value = LiveStatus.live;
          onMessage(data);
        },
        onDone: _onDrop,
        onError: (_) => _onDrop(),
        cancelOnError: true,
      );
    } catch (_) {
      _onDrop();
    }
  }

  void _onDrop() {
    _ping?.cancel();
    _socket = null;
    if (_stopped) return;
    status.value = LiveStatus.offline;
    final delay = Duration(seconds: min(30, 1 << min(_attempt++, 5)));
    _retry = Timer(delay, _connect);
  }

  /// Disconnects; [start] may be called again later (e.g. on app resume).
  Future<void> pause() async {
    _stopped = true;
    _retry?.cancel();
    _ping?.cancel();
    final s = _socket;
    _socket = null;
    await s?.close();
    status.value = LiveStatus.offline;
  }

  Future<void> close() async {
    await pause();
    status.dispose();
  }
}

/// Top of book + last trade for one Polymarket outcome token, and the price
/// Polymarket displays from them.
class QuoteState {
  double? bid;
  double? ask;
  double? lastTrade;

  /// The bid/ask midpoint, or the last trade when the spread is wider than 10¢.
  double? get price {
    final b = bid, a = ask, t = lastTrade;
    if (b != null && a != null && a - b <= 0.10 + 1e-9) return (a + b) / 2;
    return t ?? (b != null && a != null ? (a + b) / 2 : null);
  }

  /// Applies one decoded market-channel event. Returns the new price and its time if
  /// the event moved the price or was a trade.
  ({DateTime time, double price, bool trade})? apply(Map<String, dynamic> e, String tokenId, DateTime now) {
    final before = price;
    var trade = false;
    switch (e['event_type']) {
      case 'book':
        if (e['asset_id'] != tokenId) return null;
        final bids = _levels(e['bids'] ?? e['buys']);
        final asks = _levels(e['asks'] ?? e['sells']);
        bid = bids.isEmpty ? null : bids.reduce(max);
        ask = asks.isEmpty ? null : asks.reduce(min);
      case 'price_change':
        final changes = (e['price_changes'] as List?) ?? const [];
        final mine = changes.cast<Map<String, dynamic>>().where((c) => c['asset_id'] == tokenId);
        if (mine.isEmpty) return null;
        bid = _d(mine.last['best_bid']) ?? bid;
        ask = _d(mine.last['best_ask']) ?? ask;
      case 'last_trade_price':
        if (e['asset_id'] != tokenId) return null;
        final p = _d(e['price']);
        if (p == null) return null;
        lastTrade = p;
        trade = true;
      default:
        return null;
    }
    final after = price;
    if (after == null || (!trade && after == before)) return null;
    final ts = int.tryParse('${e['timestamp']}');
    return (time: ts == null ? now : DateTime.fromMillisecondsSinceEpoch(ts), price: after, trade: trade);
  }

  static List<double> _levels(Object? v) =>
      ((v as List?) ?? const []).map((l) => _d((l as Map)['price'])).whereType<double>().toList();

  static double? _d(Object? v) => v == null ? null : double.tryParse('$v');
}
