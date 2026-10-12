import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:catalog_calculator_flutter/features/search/cubit/search_artist_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/artist_valuation_service.dart';
import '../../dashboard/models/valuation_models.dart';

class SearchArtistCubit extends Cubit<SearchArtistState> {
  SearchArtistCubit() : super(SearchArtistInitial());

  Future<void> searchArtist({
    required String query,
    required Map<String, bool> platforms,
  }) async {
    if (query.trim().isEmpty) return;

    if (!platforms.values.any((isSelected) => isSelected)) {
      emit(const SearchArtistError('Please select at least one data source.'));
      return;
    }

    emit(SearchArtistLoading());

    try {
      final platformsToFetch = <String>[];
      if (platforms['spotify'] == true) platformsToFetch.add('apify');
      if (platforms['apple'] == true) platformsToFetch.add('itunes');
      if (platforms['youtube'] == true) platformsToFetch.add('youtube');
      
      // CRITICAL - Web App Proxy Rule (LandingPage.jsx lines 137-140)
      if (platforms['apple'] == true) {
        if (platforms['spotify'] != true) platformsToFetch.add('apify_proxy');
        if (platforms['youtube'] != true) platformsToFetch.add('youtube_proxy');
      }

      final artistsMap = <String, Map<String, dynamic>>{};

      final futures = platformsToFetch.map((fetchKey) async {
        try {
          final isProxy = fetchKey.contains('_proxy');
          final functionName = fetchKey.startsWith('apify') ? 'apify' : (fetchKey.startsWith('youtube') ? 'youtube' : fetchKey);
          
          final requestBody = <String, dynamic>{'query': query};
          if (fetchKey == 'itunes') {
            // Free mode matches the website's searchItunes API and avoids token error
            requestBody['useMusicKit'] = false;
          }

          var data;
          if (fetchKey == 'itunes') {
            try {
              final response = await Supabase.instance.client.functions.invoke(
                'apify-apple',
                body: {'query': query, 'useMusicKit': true},
              );
              if (response.data != null && response.data is Map && (response.data['results'] as List?)?.isNotEmpty == true) {
                data = response.data['results'][0];
              } else if (response.data != null && response.data is Map) {
                data = response.data;
              }
            } catch (_) {}

            if (data == null) {
              try {
                final httpClient = HttpClient();
                final req = await httpClient.getUrl(Uri.parse(
                    'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&entity=musicArtist&limit=1'));
                final res = await req.close();
                final body = await res.transform(utf8.decoder).join();
                final json = jsonDecode(body) as Map<String, dynamic>;
                if (json['results'] != null && (json['results'] as List).isNotEmpty) {
                  data = json['results'][0];
                }
              } catch (_) {}
            }

            if (data == null) {
              data = {
                'platform': 'itunes',
                'name': query,
                'artistName': query,
              };
            }
          } else {
            try {
              final response = await Supabase.instance.client.functions.invoke(
                functionName,
                body: requestBody,
              );
              data = response.data;
            } catch (_) {}
          }

          // SPOTIFY: Data Normalization Layer (Merge Chartmetric stats if not proxy)
          if ((fetchKey == 'apify' || fetchKey == 'apify_proxy') && data != null && data is Map) {
            final dataMap = Map<String, dynamic>.from(data);
            if (!isProxy) {
              try {
                final cmResponse = await Supabase.instance.client.functions.invoke(
                  'chartmetric',
                  body: {'query': query},
                );
                final cmData = cmResponse.data;
                if (cmData != null && cmData is Map && cmData['error'] == null) {
                  if (cmData['monthlyListeners'] != null) {
                    dataMap['monthlyListeners'] = cmData['monthlyListeners'];
                  }
                  if (cmData['followers'] != null) {
                    dataMap['followers'] = cmData['followers'];
                  }
                  final mergedStats = Map<String, dynamic>.from(dataMap['stats'] as Map? ?? {});
                  if (cmData['stats'] != null && cmData['stats'] is Map) {
                    for (final entry in (cmData['stats'] as Map).entries) {
                      if (entry.value != null && entry.value != 0) {
                        mergedStats[entry.key.toString()] = entry.value;
                      }
                    }
                  }
                  dataMap['stats'] = mergedStats;
                }
              } catch (_) {}
            }
            final stats = Map<String, dynamic>.from(dataMap['stats'] as Map? ?? {});
            stats['radio_spins'] = 15420;
            dataMap['stats'] = stats;
            data = dataMap;
          }

          // YOUTUBE: Website's Channel Ranking Algorithm
          if ((fetchKey == 'youtube' || fetchKey == 'youtube_proxy') && data != null && data is Map) {
            String? bestChannelId;
            Map<String, dynamic>? bestChannel;

            if (data['channels'] != null && (data['channels'] as List).isNotEmpty) {
              final rawChannels = (data['channels'] as List)
                  .whereType<Map>()
                  .map((c) => Map<String, dynamic>.from(c))
                  .toList();

              if (rawChannels.isNotEmpty) {
                final cleanQuery = query.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
                num highestScore = -1;
                bestChannel = rawChannels.first;

                for (final ch in rawChannels) {
                  final subs = (ch['subscribers'] as num?)?.toInt() ?? 0;
                  final vCount = (ch['videoCount'] as num?)?.toInt() ?? 0;
                  if (subs == 0 && vCount == 0 && rawChannels.length > 1) {
                    continue;
                  }

                  num score = 0;
                  final title = (ch['title'] ?? ch['name'] ?? '').toString();
                  final cleanTitle = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
                  if (cleanTitle == cleanQuery) {
                    score += 1000000000;
                  } else if (cleanTitle.contains(cleanQuery) || cleanQuery.contains(cleanTitle)) {
                    score += 500000000;
                  }
                  score += subs;
                  if (ch['isOfficialMusicChannel'] == true) {
                    score += 100000;
                  }

                  if (score > highestScore) {
                    highestScore = score;
                    bestChannel = ch;
                  }
                }
                bestChannelId = bestChannel?['id'] as String?;
              }
            } else if (data['channel'] != null && data['channel'] is Map) {
              bestChannel = Map<String, dynamic>.from(data['channel'] as Map);
              bestChannelId = bestChannel['id'] as String?;
            }

            if (bestChannelId != null) {
              try {
                final detailsResponse = await Supabase.instance.client.functions.invoke(
                  'youtube',
                  body: {'query': query, 'channelId': bestChannelId},
                );
                if (detailsResponse.data != null && detailsResponse.data is Map) {
                  final details = Map<String, dynamic>.from(detailsResponse.data as Map);
                  if (bestChannel != null) {
                    details['totalViews'] ??= bestChannel['totalViews'];
                    details['subscribers'] ??= bestChannel['subscribers'];
                    details['title'] ??= bestChannel['title'] ?? bestChannel['name'];
                  }
                  data = details;
                }
              } catch (_) {}
            }
          }

          // YOUTUBE: Public API Direct Fallback
          if ((fetchKey == 'youtube' || fetchKey == 'youtube_proxy') &&
              (data == null ||
                  (data is Map &&
                      (data['error'] != null ||
                          (!data.containsKey('stats') &&
                              !data.containsKey('totalViews') &&
                              !data.containsKey('title')))))) {
            try {
              const apiKey = 'AIzaSyBvlzgXH5IKpLZFckQu-_KXv_rdMELAdNw';
              final httpClient = HttpClient();
              final req1 = await httpClient.getUrl(Uri.parse(
                  'https://www.googleapis.com/youtube/v3/search?part=snippet&type=channel&q=${Uri.encodeComponent(query)}&maxResults=5&key=$apiKey'));
              final res1 = await req1.close();
              final body1 = await res1.transform(utf8.decoder).join();
              final json1 = jsonDecode(body1);

              if (json1['items'] != null && (json1['items'] as List).isNotEmpty) {
                final channelId = json1['items'][0]['id']['channelId'] ?? json1['items'][0]['id'];
                final req2 = await httpClient.getUrl(Uri.parse(
                    'https://www.googleapis.com/youtube/v3/channels?part=statistics,snippet&id=$channelId&key=$apiKey'));
                final res2 = await req2.close();
                final body2 = await res2.transform(utf8.decoder).join();
                final json2 = jsonDecode(body2);

                if (json2['items'] != null && (json2['items'] as List).isNotEmpty) {
                  final item = json2['items'][0];
                  final channelName = item['snippet']?['title'] ?? query;
                  final subs = int.tryParse(item['statistics']?['subscriberCount']?.toString() ?? '0') ?? 0;
                  final views = int.tryParse(item['statistics']?['viewCount']?.toString() ?? '0') ?? 0;
                  final videos = int.tryParse(item['statistics']?['videoCount']?.toString() ?? '0') ?? 0;

                  // Fetch authentic top videos to match website's YouTube valuation engine
                  final topVideosList = <Map<String, dynamic>>[];
                  try {
                    final uploadsPlaylistId = channelId.toString().replaceFirst(RegExp(r'^UC'), 'UU');
                    final pReq = await httpClient.getUrl(Uri.parse(
                        'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=$uploadsPlaylistId&maxResults=10&key=$apiKey'));
                    final pRes = await pReq.close();
                    final pBody = await pRes.transform(utf8.decoder).join();
                    final pJson = jsonDecode(pBody);
                    if (pJson['items'] is List && (pJson['items'] as List).isNotEmpty) {
                      final videoIds = (pJson['items'] as List)
                          .map((it) => (it as Map)['snippet']?['resourceId']?['videoId'])
                          .where((id) => id != null)
                          .join(',');
                      if (videoIds.isNotEmpty) {
                        final vReq = await httpClient.getUrl(Uri.parse(
                            'https://www.googleapis.com/youtube/v3/videos?part=statistics,snippet&id=$videoIds&key=$apiKey'));
                        final vRes = await vReq.close();
                        final vBody = await vRes.transform(utf8.decoder).join();
                        final vJson = jsonDecode(vBody);
                        if (vJson['items'] is List) {
                          for (final vItem in (vJson['items'] as List)) {
                            final vMap = vItem as Map;
                            final vViews = int.tryParse(vMap['statistics']?['viewCount']?.toString() ?? '0') ?? 0;
                            topVideosList.add({
                              'id': vMap['id'],
                              'title': vMap['snippet']?['title'],
                              'viewCount': vViews,
                              'releaseDate': vMap['snippet']?['publishedAt']?.toString().split('T').first,
                            });
                          }
                        }
                      }
                    }
                  } catch (_) {}

                  data = {
                    'platform': 'youtube',
                    'name': channelName,
                    'title': channelName,
                    'channelTitle': channelName,
                    'subscribers': subs,
                    'totalViews': views,
                    'tracksCount': videos,
                    'videos': topVideosList,
                    'stats': {
                      'totalViews': views,
                      'totalSubscribers': subs,
                      'totalVideos': videos,
                    }
                  };
                }
              }
            } catch (_) {}
          }

          Map<String, dynamic>? artistData;
          if (data != null &&
              data is Map &&
              (data.containsKey('name') ||
                  data.containsKey('artistName') ||
                  data.containsKey('title') ||
                  data.containsKey('channelTitle') ||
                  data.containsKey('platform') ||
                  data.containsKey('channels') ||
                  data.containsKey('videos'))) {
            artistData = Map<String, dynamic>.from(data);
          } else if (data != null && data['artists'] != null) {
            final artistsData = data['artists'];
            if (artistsData is Map &&
                artistsData['items'] != null &&
                (artistsData['items'] as List).isNotEmpty) {
              artistData = artistsData['items'][0] as Map<String, dynamic>?;
            }
          } else if (data != null && data['results'] != null && (data['results'] as List).isNotEmpty) {
            artistData = data['results'][0] as Map<String, dynamic>?;
          } else if (data != null && data is Map<String, dynamic>) {
            artistData = data;
          }

          if (artistData != null) {
            final mapKey = fetchKey == 'apify'
                ? 'spotify'
                : (fetchKey == 'apify_proxy'
                    ? 'spotify_proxy'
                    : (fetchKey == 'youtube_proxy' ? 'youtube_proxy' : fetchKey));
            final formatted = Map<String, dynamic>.from(artistData);
            formatted['platform'] = mapKey;
            formatted['name'] ??= formatted['artistName'] ?? formatted['title'] ?? formatted['channelTitle'] ?? query;
            artistsMap[mapKey] = formatted;
          }
        } catch (_) {}
      }).toList();

      await Future.wait(futures);

      if (artistsMap.isEmpty) {
        throw Exception('Could not find catalog data for this artist on any selected platform.');
      }

      // Guarantee every artist in artistsMap has 'name' defined
      for (final entry in artistsMap.entries) {
        entry.value['name'] ??= entry.value['title'] ?? entry.value['channelTitle'] ?? query;
      }

      final artistData = artistsMap['spotify'] ??
          artistsMap['spotify_proxy'] ??
          artistsMap['itunes'] ??
          artistsMap['youtube'] ??
          artistsMap.values.first;

      final activeKeys = platforms.entries.where((e) => e.value).map((e) => e.key).toList();
      final artistName = (artistData['name'] as String?) ?? query;

      // 1. Shared cache lookup. Key is built from the TYPED query + platforms,
      //    exactly like LandingPage.jsx on the website, so both read the same row.
      final baselineFromService = await ArtistValuationService.getCatalogValuation(
        artistName: query,
        activePlatforms: activeKeys,
        artistsMap: artistsMap,
      );

      final calculateResponse = await Supabase.instance.client.functions.invoke(
        'calculate-valuation',
        body: {'artistsMap': artistsMap},
      );

      final finalData = calculateResponse.data;
      if (finalData == null || finalData['midEstimate'] == null) {
        throw Exception('Valuation engine returned invalid data.');
      }

      var valuationDataModel = ValuationDataModel.fromJson(finalData as Map<String, dynamic>);
      final calculatedValue = (finalData['midEstimate'] as num).toDouble();
      final finalEstimatedValue = baselineFromService > 0 ? baselineFromService : calculatedValue;

      if (finalEstimatedValue > 0) {
        valuationDataModel = valuationDataModel.copyWith(estimatedValue: finalEstimatedValue);
      }

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        try {
          await Supabase.instance.client.from('user_reports').insert({
            'user_id': session.user.id,
            'artist_name': artistName,
            'platform': platforms.keys.firstWhere((k) => platforms[k] == true, orElse: () => 'spotify'),
            'estimated_value': finalEstimatedValue,
          });
        } catch (e) {
          print('Failed to save report: $e');
        }
      }

      emit(SearchArtistLoaded(
        valuationData: valuationDataModel,
        artistData: ArtistProfileModel.fromJson(artistData),
        youtubeData: artistsMap['youtube'] != null ? YouTubeProfileModel.fromJson(artistsMap['youtube']) : null,
        appleData: artistsMap['itunes'] != null ? AppleProfileModel.fromJson(artistsMap['itunes']) : null,
        selectedPlatforms: Map<String, bool>.from(platforms),
      ));
    } catch (e) {
      emit(SearchArtistError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void reset() {
    emit(SearchArtistInitial());
  }
}
