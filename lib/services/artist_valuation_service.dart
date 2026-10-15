import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ArtistValuationService {
  /// Must equal VALUATION_ENGINE_VERSION in src/utils/valuationCache.js.
  static const int engineVersion = 2;

  /// Cache to avoid redundant network roundtrips during session
  static final Map<String, double> _localMemoryCache = {};

  /// Platforms normalized to the website schema ('apple' -> 'itunes'), deduped and sorted.
  static List<String> normalizePlatforms(List<String> activePlatforms) {
    final mapped = activePlatforms
        .map((p) => p.toLowerCase() == 'apple' ? 'itunes' : p.toLowerCase())
        .toSet()
        .toList()
      ..sort();
    return mapped;
  }

  /// SHARED KEY RULE — must stay identical to LandingPage.jsx on the website:
  /// lowercase query, strip everything except a-z/0-9 (fallback: spaces -> '_'),
  /// then append the sorted platform list.
  static String buildCacheId(String query, List<String> activePlatforms) {
    final raw = query.trim().toLowerCase();
    var normalized = raw.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (normalized.isEmpty) normalized = raw.replaceAll(RegExp(r'\s+'), '_');
    return 'valuation_${normalized}_${normalizePlatforms(activePlatforms).join('_')}';
  }

  /// Fetches the preserved 100% baseline catalog valuation from Supabase `api_cache` table.
  static Future<double> fetchCatalogValuation({
    required String artistName,
    required List<String> activePlatforms, // e.g. ['itunes', 'spotify', 'youtube']
  }) async {
    final cacheId = buildCacheId(artistName, activePlatforms);

    if (_localMemoryCache.containsKey(cacheId)) {
      return _localMemoryCache[cacheId]!;
    }

    try {
      final res = await Supabase.instance.client
          .from('api_cache')
          .select('data')
          .eq('id', cacheId)
          .maybeSingle();

      if (res != null && res['data'] != null) {
        final dynamic rawVal = res['data']['baseCatalogValue'];
        if (rawVal is num && rawVal > 0) {
          final val = rawVal.toDouble();
          _localMemoryCache[cacheId] = val;
          return val;
        }
      }

    } catch (_) {
      // Return 0.0 on error to allow fallback
    }

    // Default fallback if not found in cache
    return 0.0;
  }

  /// Single source of truth for the headline catalog value. Dart twin of
  /// resolveSharedValuation() in src/utils/valuationCache.js — keep in lock-step.
  ///  1. Look up by typed query, then by the RESOLVED artist name.
  ///  2. First writer wins; a current-version value is never overwritten.
  ///  3. Rows from older engines (no engineVersion) are replaced.
  static Future<double> resolveSharedValuation({
    required String typedQuery,
    required List<String> activePlatforms,
    required Map<String, Map<String, dynamic>> artistsMap,
    required double computedVal,
  }) async {
    final typedId = buildCacheId(typedQuery, activePlatforms);
    final a = artistsMap['spotify'] ??
        artistsMap['spotify_proxy'] ??
        artistsMap['itunes'] ??
        artistsMap['youtube'] ??
        (artistsMap.values.isNotEmpty ? artistsMap.values.first : null);
    final resolvedName = (a?['name'] as String?)?.trim();
    final hasName = resolvedName != null && resolvedName.isNotEmpty;
    final canonId = hasName ? buildCacheId(resolvedName, activePlatforms) : typedId;
    final displayName = hasName ? resolvedName : typedQuery;

    try {
      final typed = await _readRow(typedId);
      if (typed.value != null) return typed.value!;

      final canon = canonId == typedId ? typed : await _readRow(canonId);
      if (canon.value != null) {
        if (canonId != typedId) {
          await _writeRow(typedId, displayName, activePlatforms, canon.value!, typed.exists);
        }
        _localMemoryCache[typedId] = canon.value!;
        return canon.value!;
      }

      // Nobody has a current value yet: publish ours, then read back the actual winner.
      await _writeRow(canonId, displayName, activePlatforms, computedVal, canon.exists);
      final winner = (await _readRow(canonId)).value ?? computedVal.roundToDouble();
      if (canonId != typedId) {
        await _writeRow(typedId, displayName, activePlatforms, winner, typed.exists);
      }
      _localMemoryCache[typedId] = winner;
      return winner;
    } catch (_) {
      return computedVal.roundToDouble();
    }
  }

  static Future<({bool exists, double? value})> _readRow(String id) async {
    final res = await Supabase.instance.client
        .from('api_cache')
        .select('data')
        .eq('id', id)
        .maybeSingle();
    final d = res?['data'];
    final raw = d is Map ? d['baseCatalogValue'] : null;
    final value = raw is num ? raw.toDouble() : 0.0;
    final exists = value > 0;
    final ver = d is Map && d['engineVersion'] is num ? (d['engineVersion'] as num).toInt() : 0;
    return (exists: exists, value: (exists && ver >= engineVersion) ? value : null);
  }

  static Future<void> _writeRow(
    String id,
    String artistName,
    List<String> activePlatforms,
    double value,
    bool replaceStale,
  ) async {
    await Supabase.instance.client.from('api_cache').upsert(
      {
        'id': id,
        'query': artistName.trim().toLowerCase(),
        'platform': 'valuation',
        'data': {
          'artistName': artistName,
          'baseCatalogValue': value.round(),
          'currency': 'USD',
          'platforms': normalizePlatforms(activePlatforms),
          'engineVersion': engineVersion,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
      },
      onConflict: 'id',
      // Absent row -> insert-if-missing (loses gracefully to a concurrent writer).
      ignoreDuplicates: !replaceStale,
    );
  }

  /// Retrieves the 100% baseline catalog valuation for ANY artist
  /// Checks api_cache first, and if missing calculates on-demand via edge function & persists to cache
  static Future<double> getCatalogValuation({
    required String artistName,
    required List<String> activePlatforms,
    Map<String, dynamic>? artistsMap,
  }) async {
    try {
      final sortedPlatforms = normalizePlatforms(activePlatforms);
      final cacheId = buildCacheId(artistName, activePlatforms);

      if (_localMemoryCache.containsKey(cacheId)) {
        return _localMemoryCache[cacheId]!;
      }

      // 1. Check api_cache first
      final cacheRes = await Supabase.instance.client
          .from('api_cache')
          .select('data')
          .eq('id', cacheId)
          .maybeSingle();

      if (cacheRes != null && cacheRes['data'] != null) {
        final dynamic rawVal = cacheRes['data']['baseCatalogValue'];
        if (rawVal is num && rawVal > 0) {
          final val = rawVal.toDouble();
          _localMemoryCache[cacheId] = val;
          return val;
        }
      }

      // 2. If not cached, invoke the backend Edge Function calculate-valuation
      if (artistsMap != null && artistsMap.isNotEmpty) {
        final edgeRes = await Supabase.instance.client.functions.invoke(
          'calculate-valuation',
          body: {'artistsMap': artistsMap},
        );

        if (edgeRes.data != null && edgeRes.data['midEstimate'] != null) {
          final double calculatedVal = (edgeRes.data['midEstimate'] as num).toDouble();
          _localMemoryCache[cacheId] = calculatedVal;

          // 3. Save into api_cache so future searches are instant
          await saveCatalogValuation(
            artistName: artistName,
            activePlatforms: sortedPlatforms,
            baseCatalogValue: calculatedVal,
          );

          return calculatedVal;
        }
      }

      return 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  /// Calculates dynamic valuation with royaltyShare and multiple scaling
  static double calculateCurrentValuation({
    required double baseCatalogValue,
    double royaltyShare = 100.0,
    double multiple = 14.0,
  }) {
    return baseCatalogValue * (royaltyShare / 100.0) * (multiple / 14.0);
  }

  /// Formats currency according to standard US locale without decimals ($242,445,913)
  static String formatValuation(double value) {
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 0,
    ).format(value);
  }

  /// Preserves the baseline value in `api_cache` for synchronization across app & web
  static Future<void> saveCatalogValuation({
    required String artistName,
    required List<String> activePlatforms,
    required double baseCatalogValue,
  }) async {
    if (baseCatalogValue <= 0) return;
    final sortedPlatforms = normalizePlatforms(activePlatforms);
    final cacheId = buildCacheId(artistName, activePlatforms);

    // Update in-memory cache
    _localMemoryCache[cacheId] = baseCatalogValue;

    try {
      await Supabase.instance.client.from('api_cache').upsert({
        'id': cacheId,
        'query': artistName.trim().toLowerCase(),
        'platform': 'valuation',
        'data': {
          'artistName': artistName,
          'baseCatalogValue': baseCatalogValue.round(),
          'platforms': sortedPlatforms,
          'engineVersion': engineVersion,
          'currency': 'USD',
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
      });
    } catch (_) {}
  }
}
