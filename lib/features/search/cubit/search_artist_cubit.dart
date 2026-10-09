import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'search_artist_state.dart';

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
      
      // CRITICAL - The Proxy Rule
      if (platforms['apple'] == true && platforms['spotify'] != true) {
        platformsToFetch.add('apify_proxy'); 
      }

      final artistsMap = <String, Map<String, dynamic>>{};

      final futures = platformsToFetch.map((fetchKey) async {
        try {
          final functionName = fetchKey == 'apify_proxy' ? 'apify' : fetchKey;
          final requestBody = <String, dynamic>{'query': query};
          if (fetchKey == 'itunes') {
            requestBody['useMusicKit'] = true;
          }

          var response = await Supabase.instance.client.functions.invoke(
            functionName,
            body: requestBody,
          );

          if (fetchKey == 'itunes' && (response.data == null || (response.data is Map && response.data['error'] != null))) {
            requestBody['useMusicKit'] = false;
            response = await Supabase.instance.client.functions.invoke(
              functionName,
              body: requestBody,
            );
          }

          var data = response.data;
          
          if (fetchKey == 'youtube' && (data == null || data['error'] != null || (data is Map && !data.containsKey('channels')))) {
            try {
              // Client-side fallback identical to web app's api.js
              const apiKey = 'AIzaSyBvlzgXH5IKpLZFckQu-_KXv_rdMELAdNw';
              final httpClient = HttpClient();
              final req1 = await httpClient.getUrl(Uri.parse('https://www.googleapis.com/youtube/v3/search?part=snippet&type=channel&q=${Uri.encodeComponent(query)}&maxResults=1&key=$apiKey'));
              final res1 = await req1.close();
              final body1 = await res1.transform(utf8.decoder).join();
              final json1 = jsonDecode(body1);
              
              if (json1['items'] != null && (json1['items'] as List).isNotEmpty) {
                final String channelId = json1['items'][0]['id']['channelId'] ?? json1['items'][0]['id'];
                
                final req2 = await httpClient.getUrl(Uri.parse('https://www.googleapis.com/youtube/v3/channels?part=statistics,snippet&id=$channelId&key=$apiKey'));
                final res2 = await req2.close();
                final body2 = await res2.transform(utf8.decoder).join();
                final json2 = jsonDecode(body2);
                
                if (json2['items'] != null && (json2['items'] as List).isNotEmpty) {
                  final item = json2['items'][0];
                  data = {
                    'platform': 'youtube',
                    'title': item['snippet']['title'],
                    'channelTitle': item['snippet']['title'],
                    'subscribers': int.tryParse(item['statistics']['subscriberCount']?.toString() ?? '0') ?? 0,
                    'totalViews': int.tryParse(item['statistics']['viewCount']?.toString() ?? '0') ?? 0,
                    'tracksCount': int.tryParse(item['statistics']['videoCount']?.toString() ?? '0') ?? 0,
                  };
                }
              }
            } catch (fallbackErr) {
              // Ignore fallback errors
            }
          } else if (fetchKey == 'youtube' && data != null && data is Map) {
            String? channelId;
            if (data['channels'] != null && (data['channels'] as List).isNotEmpty) {
              channelId = data['channels'][0]['id'] as String?;
            } else if (data['channel'] != null) {
              channelId = data['channel']['id'] as String?;
            }
            
            if (channelId != null) {
              final detailsResponse = await Supabase.instance.client.functions.invoke(
                'youtube',
                body: {'query': query, 'channelId': channelId},
              );
              data = detailsResponse.data;
            }
          }

          Map<String, dynamic>? artistData;
          if (data != null && data is Map<String, dynamic> && (data.containsKey('name') || data.containsKey('title') || data.containsKey('channelTitle') || data.containsKey('platform'))) {
            artistData = data;
          } else if (data != null && data['artists'] != null) {
             final artistsData = data['artists'];
             if (artistsData is Map && artistsData['items'] != null && (artistsData['items'] as List).isNotEmpty) {
                artistData = artistsData['items'][0] as Map<String, dynamic>?;
             }
          } else if (data != null && data['results'] != null && (data['results'] as List).isNotEmpty) {
             artistData = data['results'][0] as Map<String, dynamic>?;
          } else if (data != null && data is Map<String, dynamic>) {
             artistData = data;
          }

          if (artistData != null) {
            final mapKey = fetchKey == 'apify' ? 'spotify' : (fetchKey == 'apify_proxy' ? 'spotify_proxy' : fetchKey);
            artistsMap[mapKey] = Map<String, dynamic>.from(artistData)..['platform'] = mapKey;
          }
        } catch (e) {
          if (fetchKey == 'itunes') {
            try {
              final fallbackResponse = await Supabase.instance.client.functions.invoke(
                'itunes',
                body: {'query': query, 'useMusicKit': false},
              );
              final data = fallbackResponse.data;
              Map<String, dynamic>? artistData;
              if (data != null && data is Map<String, dynamic> && (data.containsKey('name') || data.containsKey('title') || data.containsKey('channelTitle') || data.containsKey('platform'))) {
                artistData = data;
              } else if (data != null && data['artists'] != null) {
                 final artistsData = data['artists'];
                 if (artistsData is Map && artistsData['items'] != null && (artistsData['items'] as List).isNotEmpty) {
                    artistData = artistsData['items'][0] as Map<String, dynamic>?;
                 }
              } else if (data != null && data['results'] != null && (data['results'] as List).isNotEmpty) {
                 artistData = data['results'][0] as Map<String, dynamic>?;
              } else if (data != null && data is Map<String, dynamic>) {
                 artistData = data;
              }
              if (artistData != null) {
                artistsMap['itunes'] = Map<String, dynamic>.from(artistData)..['platform'] = 'itunes';
              }
            } catch (_) {}
          }
        }
      }).toList();

      await Future.wait(futures);

      if (artistsMap.isEmpty) {
        throw Exception('Could not find catalog data for this artist on any selected platform.');
      }
      
      final artistData = artistsMap['spotify'] ?? artistsMap['spotify_proxy'] ?? artistsMap['itunes'] ?? artistsMap['youtube'] ?? artistsMap.values.first;

      final calculateResponse = await Supabase.instance.client.functions.invoke(
        'calculate-valuation',
        body: {'artistsMap': artistsMap},
      );

      final finalData = calculateResponse.data;
      if (finalData == null || finalData['midEstimate'] == null) {
        throw Exception('Valuation engine returned invalid data.');
      }

      final estimatedValue = (finalData['midEstimate'] as num).toDouble();

      emit(SearchArtistLoaded(
        estimatedValue: estimatedValue,
        artistData: artistData,
        youtubeData: artistsMap['youtube'],
        appleData: artistsMap['itunes'],
      ));
    } catch (e) {
      emit(SearchArtistError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void reset() {
    emit(SearchArtistInitial());
  }
}
