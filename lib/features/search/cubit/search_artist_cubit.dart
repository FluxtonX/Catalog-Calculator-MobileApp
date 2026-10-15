import 'package:bloc/bloc.dart';
import 'package:catalog_calculator_flutter/features/search/cubit/search_artist_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/artist_valuation_service.dart';
import '../../../services/platform_data_fetcher.dart';
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
      // Website parity (LandingPage.jsx handleCalculate): the app assembles `artistsMap`
      // through PlatformDataFetcher, a line-by-line port of the website's pipeline.
      // The valuation engine is a pure function of this map, so identical input
      // here is what guarantees identical output on web and mobile.
      final platformsToFetch = <String>[];
      if (platforms['spotify'] == true) platformsToFetch.add('spotify');
      if (platforms['apple'] == true) platformsToFetch.add('itunes');
      if (platforms['youtube'] == true) platformsToFetch.add('youtube');

      // Web proxy rule (LandingPage.jsx): Apple Music borrows streams from Spotify/YouTube proxies.
      if (platforms['apple'] == true) {
        if (platforms['spotify'] != true) platformsToFetch.add('spotify_proxy');
        if (platforms['youtube'] != true) platformsToFetch.add('youtube_proxy');
      }

      final artistsMap = <String, Map<String, dynamic>>{};

      final futures = platformsToFetch.map((key) async {
        try {
          Map<String, dynamic>? d;
          if (key == 'spotify' || key == 'spotify_proxy') {
            d = await PlatformDataFetcher.fetchSpotify(query, isProxy: key == 'spotify_proxy');
          } else if (key == 'youtube' || key == 'youtube_proxy') {
            d = await PlatformDataFetcher.fetchYouTube(query);
          } else if (key == 'itunes') {
            d = await PlatformDataFetcher.fetchApple(query);
          }
          if (d == null) return;

          // Website: name = value.name || channelTitle || artistName || title; skip if none.
          final name = PlatformDataFetcher.firstTruthy(
              [d['name'], d['channelTitle'], d['artistName'], d['title']]);
          if (name == null) return;

          final formatted = Map<String, dynamic>.from(d);
          formatted['name'] = name;
          formatted['platform'] = key;
          artistsMap[key] = formatted;
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

      // Single source of truth (same algorithm as the website's LandingPage.jsx):
      // whichever client stored a value for this artist first wins, and every
      // client displays that stored value.
      final finalEstimatedValue = await ArtistValuationService.resolveSharedValuation(
        typedQuery: query,
        activePlatforms: activeKeys,
        artistsMap: artistsMap,
        computedVal: calculatedValue,
      );

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
