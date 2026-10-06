import 'dart:convert';
import 'dart:io' show HandshakeException;

import 'package:http/http.dart' as http;

/// Read-only client for Polymarket's public APIs. No account or keys needed.
class PolymarketApi {
  PolymarketApi({http.Client? client}) : _client = client ?? http.Client();

  static const gamma = 'https://gamma-api.polymarket.com';
  static const clob = 'https://clob.polymarket.com';

  final http.Client _client;

  Future<dynamic> _get(String base, String path, Map<String, String> query) async {
    final uri = Uri.parse('$base$path').replace(queryParameters: query.isEmpty ? null : query);
    final http.Response res;
    try {
      res = await _client.get(uri).timeout(const Duration(seconds: 20));
    } on HandshakeException {
      // Seen in practice: an ISP answering Polymarket's DNS with its own block server,
      // whose certificate can't match. Say so instead of surfacing a TLS error.
      throw ApiException('Couldn\'t reach Polymarket securely. Your network or internet provider '
          'may be blocking it.');
    }
    if (res.statusCode != 200) {
      throw ApiException('HTTP ${res.statusCode} from ${uri.host}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  /// Open events ordered by 24h volume. [tag] is a Gamma tag slug such as `politics`.
  Future<List<Event>> trendingEvents({int offset = 0, int limit = 20, String? tag}) async {
    final data = await _get(gamma, '/events', {
      'active': 'true',
      'closed': 'false',
      'order': 'volume24hr',
      'ascending': 'false',
      'limit': '$limit',
      'offset': '$offset',
      'tag_slug': ?tag,
    }) as List;
    return data.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Event>> search(String query) async {
    final data = await _get(gamma, '/public-search', {
      'q': query,
      'limit_per_type': '20',
      'events_status': 'active',
    }) as Map<String, dynamic>;
    final events = (data['events'] as List?) ?? const [];
    return events.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Event> event(String id) async =>
      Event.fromJson(await _get(gamma, '/events/$id', const {}) as Map<String, dynamic>);

  Future<Market> market(String id) async =>
      Market.fromJson(await _get(gamma, '/markets/$id', const {}) as Map<String, dynamic>);

  /// Raw `(time, price)` samples from CLOB price history; [query] picks the window and spacing.
  Future<List<({DateTime time, double price})>> pricePoints(String tokenId, Map<String, String> query) async {
    final data = await _get(clob, '/prices-history', {'market': tokenId, ...query}) as Map<String, dynamic>;
    return ((data['history'] as List?) ?? const [])
        .map((p) => (
              time: DateTime.fromMillisecondsSinceEpoch(((p['t'] as num) * 1000).toInt()),
              price: (p['p'] as num).toDouble(),
            ))
        .toList();
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class Event {
  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.volume,
    required this.volume24hr,
    required this.endDate,
    required this.markets,
  });

  final String id;
  final String title;
  final String description;
  final double volume;
  final double volume24hr;
  final DateTime? endDate;

  /// Only real markets that are still trading; live ones first, by probability.
  final List<Market> markets;

  factory Event.fromJson(Map<String, dynamic> j) {
    final markets = ((j['markets'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        // Inactive markets are pre-made placeholder slots ("Person AQ") parked at 50%.
        .where((m) => m['active'] != false)
        .map(Market.fromJson)
        .where((m) => !m.closed && m.prices.isNotEmpty)
        .toList()
      // Live markets first, then by probability.
      ..sort((a, b) => a.decided != b.decided
          ? (a.decided ? 1 : -1)
          : b.prices.first.compareTo(a.prices.first));
    return Event(
      id: '${j['id']}',
      title: (j['title'] as String?) ?? '',
      description: (j['description'] as String?) ?? '',
      volume: _num(j['volume']),
      volume24hr: _num(j['volume24hr']),
      endDate: DateTime.tryParse((j['endDate'] as String?) ?? ''),
      markets: markets,
    );
  }
}

class Market {
  Market({
    required this.id,
    required this.question,
    required this.groupTitle,
    required this.description,
    required this.outcomes,
    required this.prices,
    required this.tokenIds,
    required this.volume,
    required this.volume24hr,
    required this.dayChange,
    required this.endDate,
    required this.closed,
  });

  final String id;
  final String question;

  /// Short label inside a multi-market event, e.g. "Game 1 Winner" or "$120k".
  final String groupTitle;
  final String description;
  final List<String> outcomes;
  final List<double> prices;
  final List<String> tokenIds;
  final double volume;
  final double volume24hr;

  /// 24h change of the first outcome's price, in price units (0.05 = +5 points).
  final double? dayChange;
  final DateTime? endDate;
  final bool closed;

  String get label => groupTitle.isNotEmpty ? groupTitle : question;

  /// Still open but effectively settled: one outcome at ≥99.5%, or past its end date.
  /// Such markets linger for hours awaiting formal resolution.
  bool get decided =>
      prices.any((p) => p >= 0.995) || (endDate != null && endDate!.isBefore(DateTime.now()));

  factory Market.fromJson(Map<String, dynamic> j) => Market(
        id: '${j['id']}',
        question: (j['question'] as String?) ?? '',
        groupTitle: (j['groupItemTitle'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        // Gamma returns these three arrays as JSON-encoded strings.
        outcomes: _stringList(j['outcomes']),
        prices: _stringList(j['outcomePrices']).map((s) => double.tryParse(s) ?? 0).toList(),
        tokenIds: _stringList(j['clobTokenIds']),
        volume: _num(j['volumeNum'] ?? j['volume']),
        volume24hr: _num(j['volume24hr']),
        dayChange: j['oneDayPriceChange'] == null ? null : _num(j['oneDayPriceChange']),
        endDate: DateTime.tryParse((j['endDate'] as String?) ?? ''),
        closed: j['closed'] == true,
      );
}

double _num(Object? v) => switch (v) {
      num n => n.toDouble(),
      String s => double.tryParse(s) ?? 0,
      _ => 0,
    };

List<String> _stringList(Object? v) {
  if (v is List) return v.map((e) => '$e').toList();
  if (v is String && v.isNotEmpty) {
    try {
      return (jsonDecode(v) as List).map((e) => '$e').toList();
    } on FormatException {
      return const [];
    }
  }
  return const [];
}
