import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Line-by-line Dart port of the website's data-assembly pipeline
/// (`src/utils/api.js` + the platform loop in `src/pages/LandingPage.jsx`).
///
/// WHY THIS EXISTS: the valuation engine (`calculate-valuation` edge function)
/// is a byte-for-byte port of the website engine, so the final number is a pure
/// function of the `artistsMap` it receives. For web/app parity the app must
/// therefore assemble `artistsMap` EXACTLY like the website. Do not "improve"
/// these methods independently — change `api.js` and this file together.
class PlatformDataFetcher {
  static const String _youtubeApiKey = 'AIzaSyBvlzgXH5IKpLZFckQu-_KXv_rdMELAdNw';

  static SupabaseClient get _sb => Supabase.instance.client;

  // ───────────────────────────── helpers ─────────────────────────────

  /// Throws on non-2xx (same contract as the website's `invokeEdgeFunction`).
  static Future<Map<String, dynamic>?> _invoke(String fn, Map<String, dynamic> body) async {
    final res = await _sb.functions.invoke(fn, body: body);
    final d = res.data;
    return d is Map ? Map<String, dynamic>.from(d) : null;
  }

  /// Like [_invoke] but returns null on failure (website: `Promise.allSettled`).
  static Future<Map<String, dynamic>?> _tryInvoke(String fn, Map<String, dynamic> body) async {
    try {
      return await _invoke(fn, body);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _getJson(String url) async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) return null;
      final j = jsonDecode(body);
      return j is Map ? Map<String, dynamic>.from(j) : null;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  static int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

  /// JS `a || b || c` over strings/values (empty string and null are falsy).
  static dynamic firstTruthy(List<dynamic> values) {
    for (final v in values) {
      if (v == null) continue;
      if (v is String && v.isEmpty) continue;
      if (v is num && v == 0) continue;
      if (v == false) continue;
      return v;
    }
    return null;
  }

  // ───────────────────── Spotify (getNormalizedArtistData) ─────────────────────

  static Future<Map<String, dynamic>?> fetchSpotify(String query, {bool isProxy = false}) async {
    final apifyF = _tryInvoke('apify', {'query': query});
    // Chartmetric is skipped for proxy searches (Apple Music math streams).
    final Future<Map<String, dynamic>?> cmF =
        isProxy ? Future.value(null) : _tryInvoke('chartmetric', {'query': query});
    final apify = await apifyF;
    final cm = await cmF;

    var result = <String, dynamic>{};
    if (apify != null) {
      result = {...apify, 'platform': 'spotify'};
    } else {
      final fb = await _tryInvoke('spotify', {'query': query});
      if (fb != null && fb['error'] == null) result = {...fb};
    }

    if (cm != null) {
      final apifyStats = Map<String, dynamic>.from((result['stats'] as Map?) ?? {});
      // Website: { ...result, ...cm, stats: apifyStats, platform: 'spotify' }
      result = {...result, ...cm, 'stats': apifyStats, 'platform': 'spotify'};

      if (cm['monthlyListeners'] != null) result['monthlyListeners'] = cm['monthlyListeners'];
      if (cm['followers'] != null) result['followers'] = cm['followers'];

      final merged = Map<String, dynamic>.from(apifyStats);
      final cmStats = cm['stats'];
      if (cmStats is Map) {
        for (final e in cmStats.entries) {
          final k = e.key.toString();
          final v = e.value;
          if (v != null && v != 0) {
            merged[k] = v;
          } else if (!merged.containsKey(k)) {
            merged[k] = v;
          }
        }
      }
      result['stats'] = merged;
    }

    if (result.isEmpty) return null;

    final stats = Map<String, dynamic>.from((result['stats'] as Map?) ?? {});
    stats['radio_spins'] = 15420; // website parity (debug-forced value)
    result['stats'] = stats;
    return result;
  }

  // ───────────────────── YouTube (searchYouTube + getYouTubeChannelDetails) ─────────────────────

  static Future<Map<String, dynamic>?> fetchYouTube(String query) async {
    final channel = await _searchYouTubeChannel(query);
    if (channel == null) return null;
    return _getYouTubeChannelDetails(query, channel['id'].toString());
  }

  static Future<Map<String, dynamic>?> _searchYouTubeChannel(String query) async {
    var raw = <Map<String, dynamic>>[];

    // 1. Edge function first
    final edge = await _tryInvoke('youtube', {'query': query});
    final ch = edge?['channels'];
    if (ch is List && ch.isNotEmpty) {
      raw = ch.whereType<Map<dynamic, dynamic>>().map(Map<String, dynamic>.from).toList();
    }

    // 2. Direct API fallback
    if (raw.isEmpty) {
      final j = await _getJson(
          'https://www.googleapis.com/youtube/v3/search?part=snippet&type=channel&q=${Uri.encodeComponent(query)}&maxResults=5&key=$_youtubeApiKey');
      final items = j?['items'];
      if (items is List && items.isNotEmpty) {
        raw = items.whereType<Map<dynamic, dynamic>>().map((it) {
          final sn = (it['snippet'] as Map?) ?? {};
          final thumbs = (sn['thumbnails'] as Map?) ?? {};
          return <String, dynamic>{
            'id': (it['id'] as Map?)?['channelId'],
            'title': firstTruthy([sn['channelTitle'], sn['title']]),
            'thumbnail': (thumbs['default'] as Map?)?['url'],
          };
        }).toList();
      }
    }

    if (raw.isEmpty) return null; // website throws "Official channel not found"

    // 3. Real statistics for every candidate, then rank
    final ids = raw.map((c) => c['id']).join(',');
    final statsJson = await _getJson(
        'https://www.googleapis.com/youtube/v3/channels?part=statistics,snippet,topicDetails&id=$ids&key=$_youtubeApiKey');

    if (statsJson != null) {
      final items = ((statsJson['items'] as List?) ?? const []).whereType<Map<dynamic, dynamic>>().toList();
      final enriched = raw.map((rc) {
        Map<dynamic, dynamic>? stats;
        for (final i in items) {
          if (i['id'] == rc['id']) {
            stats = i;
            break;
          }
        }
        final topics = ((stats?['topicDetails'] as Map?)?['topicCategories'] as List?) ?? const [];
        return <String, dynamic>{
          ...rc,
          'title': firstTruthy([rc['title'], rc['name'], (stats?['snippet'] as Map?)?['title']]),
          'subscribers': _int((stats?['statistics'] as Map?)?['subscriberCount']),
          'videoCount': _int((stats?['statistics'] as Map?)?['videoCount']),
          'isOfficialMusicChannel': topics.any((tc) => tc.toString().contains('Music')),
        };
      }).toList();

      final cleanQuery = query.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      Map<String, dynamic>? best;
      num highest = -1;
      for (final c in enriched) {
        final subs = c['subscribers'] as int;
        if (subs == 0 && c['videoCount'] == 0 && enriched.length > 1) continue;

        num score = 0;
        final cleanTitle = (c['title'] ?? '').toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (cleanTitle == cleanQuery) {
          score += 1000000000;
        } else if (cleanTitle.contains(cleanQuery) || cleanQuery.contains(cleanTitle)) {
          score += 500000000;
        }
        score += subs;
        if (c['isOfficialMusicChannel'] == true) score += 100000;

        if (score > highest) {
          highest = score;
          best = c;
        }
      }
      if (best != null) {
        return {'id': best['id'], 'name': firstTruthy([best['title'], best['name']])};
      }
    }

    return {'id': raw.first['id'], 'name': firstTruthy([raw.first['title'], raw.first['name']])};
  }

  static Future<Map<String, dynamic>> _getYouTubeChannelDetails(String query, String channelId) async {
    var data = <String, dynamic>{'name': query};
    final edge = await _tryInvoke('youtube', {'query': query, 'channelId': channelId});
    if (edge != null) data = edge;

    final results = await Future.wait<Object?>([_ytChannelStats(channelId), _ytTopVideos(channelId)]);
    final real = results[0] as Map<String, dynamic>?;
    final videos = results[1] as List<Map<String, dynamic>>;

    if (real != null) {
      return {
        ...data,
        'videos': videos,
        'totalViews': real['totalViews'],
        'subscribers': real['subscribers'],
        'stats': {
          ...Map<String, dynamic>.from((data['stats'] as Map?) ?? {}),
          'totalViews': real['totalViews'],
          'totalSubscribers': real['subscribers'],
          'totalVideos': real['totalVideos'],
        },
      };
    }
    return data;
  }

  static Future<Map<String, dynamic>?> _ytChannelStats(String channelId) async {
    final j = await _getJson(
        'https://www.googleapis.com/youtube/v3/channels?part=statistics,snippet&id=$channelId&key=$_youtubeApiKey');
    final items = j?['items'];
    if (items is! List || items.isEmpty) return null;
    final st = ((items.first as Map)['statistics'] as Map?) ?? {};
    return {
      'totalViews': _int(st['viewCount']),
      'subscribers': _int(st['subscriberCount']),
      'totalVideos': _int(st['videoCount']),
    };
  }

  static Future<List<Map<String, dynamic>>> _ytTopVideos(String channelId) async {
    try {
      final uploads = channelId.replaceFirst(RegExp(r'^UC'), 'UU');
      final p = await _getJson(
          'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=$uploads&maxResults=10&key=$_youtubeApiKey');
      final pItems = p?['items'];
      if (pItems is! List || pItems.isEmpty) return [];

      final ids = pItems.map((it) => ((it as Map)['snippet'] as Map)['resourceId']['videoId']).join(',');
      final v = await _getJson(
          'https://www.googleapis.com/youtube/v3/videos?part=statistics,snippet&id=$ids&key=$_youtubeApiKey');
      final vItems = v?['items'];
      if (vItems is! List) return [];

      final out = vItems.map<Map<String, dynamic>>((it) {
        final m = it as Map;
        final sn = (m['snippet'] as Map?) ?? {};
        final views = _int((m['statistics'] as Map?)?['viewCount']);
        final published = sn['publishedAt']?.toString();
        return {
          'id': m['id'],
          'title': sn['title'],
          'viewCount': views,
          'releaseDate': published?.split('T').first,
        };
      }).toList()
        ..sort((a, b) => (b['viewCount'] as int).compareTo(a['viewCount'] as int));
      return out;
    } catch (_) {
      return [];
    }
  }

  // ───────────────────── Apple Music (searchAppleMusic / searchItunes) ─────────────────────

  static Future<Map<String, dynamic>?> fetchApple(String query) async {
    try {
      final data = await _invoke('apify-apple', {'query': query, 'useMusicKit': true});
      return _pickAppleArtist(data);
    } catch (_) {
      return _searchItunes(query);
    }
  }

  static Future<Map<String, dynamic>?> _searchItunes(String query) async {
    try {
      final data = await _invoke('itunes', {'query': query, 'useMusicKit': false});
      return _pickAppleArtist(data);
    } catch (_) {
      final j = await _getJson(
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&entity=musicArtist&limit=1');
      if (j == null) return null;
      final results = j['results'];
      if (results is List && results.isNotEmpty && results.first is Map) {
        return Map<String, dynamic>.from(results.first as Map);
      }
      return j;
    }
  }

  static Map<String, dynamic>? _pickAppleArtist(Map<String, dynamic>? data) {
    if (data == null) return null;
    final results = data['results'];
    if (results is List && results.isNotEmpty && results.first is Map) {
      return _processAppleArtist(Map<String, dynamic>.from(results.first as Map));
    }
    return data;
  }

  /// Port of `processAppleArtist`: albums with <= 3 tracks (or "- single"/"- ep") are singles.
  static Map<String, dynamic> _processAppleArtist(Map<String, dynamic> artist) {
    final albumsRaw = artist['albums'];
    if (albumsRaw is! List) return artist;

    final trueAlbums = <dynamic>[];
    final trueSingles = <dynamic>[];
    for (final album in albumsRaw) {
      final m = album is Map ? album : const <dynamic, dynamic>{};
      final tc1 = m['trackCount'];
      final tc2 = m['total_tracks'];
      final num trackCount = (tc1 is num && tc1 != 0) ? tc1 : (tc2 is num ? tc2 : 0);

      var isSingle = false;
      if (trackCount > 0 && trackCount <= 3) {
        isSingle = true;
      } else if (trackCount == 0) {
        final title = (firstTruthy([m['name'], m['title']]) ?? '').toString().toLowerCase();
        if (title.contains('- single') || title.contains('- ep')) isSingle = true;
      }
      (isSingle ? trueSingles : trueAlbums).add(album);
    }

    artist['albums'] = trueAlbums;
    final existing = artist['singles'];
    artist['singles'] = existing is List ? [...existing, ...trueSingles] : trueSingles;

    final stats = artist['stats'];
    if (stats is Map) {
      stats['totalAlbums'] = trueAlbums.length;
      stats['totalSingles'] = (artist['singles'] as List).length;
    }
    return artist;
  }
}
