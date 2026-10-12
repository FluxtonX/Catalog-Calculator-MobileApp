import '../../../core/utils/formatters.dart';

class ValuationDataModel {
  final double annualRevenue;
  final double estimatedValue;
  final Map<String, PlatformBreakdownModel> platformBreakdowns;

  ValuationDataModel({
    required this.annualRevenue,
    required this.estimatedValue,
    required this.platformBreakdowns,
  });

  factory ValuationDataModel.fromJson(Map<String, dynamic> json) {
    final breakdowns = <String, PlatformBreakdownModel>{};
    if (json['breakdown'] is Map) {
      (json['breakdown'] as Map).forEach((key, value) {
        if (value is Map<String, dynamic>) {
          breakdowns[key] = PlatformBreakdownModel.fromJson(value);
        }
      });
    }

    return ValuationDataModel(
      annualRevenue: Formatters.parseNum(json['annualRevenue']).toDouble(),
      estimatedValue: Formatters.parseNum(json['estimatedValue'] ?? json['midEstimate']).toDouble(),
      platformBreakdowns: breakdowns,
    );
  }

  ValuationDataModel copyWith({
    double? annualRevenue,
    double? estimatedValue,
    Map<String, PlatformBreakdownModel>? platformBreakdowns,
  }) {
    return ValuationDataModel(
      annualRevenue: annualRevenue ?? this.annualRevenue,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      platformBreakdowns: platformBreakdowns ?? this.platformBreakdowns,
    );
  }
}

class PlatformBreakdownModel {
  final double midEstimate;
  final double totalAnnualRevenue;
  final double averageDollarAge;
  final List<TrackModel> trackDetails;
  final String valuationMethod;

  PlatformBreakdownModel({
    required this.midEstimate,
    required this.totalAnnualRevenue,
    required this.averageDollarAge,
    required this.trackDetails,
    required this.valuationMethod,
  });

  PlatformBreakdownModel copyWith({
    double? midEstimate,
    double? totalAnnualRevenue,
    double? averageDollarAge,
    List<TrackModel>? trackDetails,
    String? valuationMethod,
  }) {
    return PlatformBreakdownModel(
      midEstimate: midEstimate ?? this.midEstimate,
      totalAnnualRevenue: totalAnnualRevenue ?? this.totalAnnualRevenue,
      averageDollarAge: averageDollarAge ?? this.averageDollarAge,
      trackDetails: trackDetails ?? this.trackDetails,
      valuationMethod: valuationMethod ?? this.valuationMethod,
    );
  }

  factory PlatformBreakdownModel.fromJson(Map<String, dynamic> json) {
    final tracks = <TrackModel>[];
    if (json['trackDetails'] is List) {
      for (var item in (json['trackDetails'] as List)) {
        if (item is Map<String, dynamic>) {
          tracks.add(TrackModel.fromJson(item));
        }
      }
    }

    return PlatformBreakdownModel(
      midEstimate: Formatters.parseNum(json['midEstimate']).toDouble(),
      totalAnnualRevenue: Formatters.parseNum(json['totalAnnualRevenue']).toDouble(),
      averageDollarAge: Formatters.parseNum(json['averageDollarAge']).toDouble(),
      trackDetails: tracks,
      valuationMethod: json['valuationMethod'] as String? ?? 'Discounted Cash Flow',
    );
  }
}

class TrackModel {
  final String title;
  final int rank;
  final String? album;
  final String? releaseYear;
  final String viewCountFormatted;
  final int streamCount;
  final String? imageUrl;
  final String platform;
  final double artistAttributedAnnualRev;
  final double ageInYears;
  final bool hasValuation;

  TrackModel({
    required this.title,
    this.rank = 0,
    this.album,
    this.releaseYear,
    required this.viewCountFormatted,
    this.streamCount = 0,
    this.imageUrl,
    this.platform = 'spotify',
    required this.artistAttributedAnnualRev,
    required this.ageInYears,
    required this.hasValuation,
  });

  factory TrackModel.fromJson(Map<String, dynamic> json, {int rank = 0, String platform = 'spotify'}) {
    final name = json['title'] ?? (json['snippet'] != null ? (json['snippet'] as Map)['title'] : null) ?? json['name'] ?? 'Unknown';
    final hasVal = json['artistAttributedAnnualRev'] != null;
    final viewCount = json['streamCountFormatted'] ?? json['viewCountFormatted'] ?? json['viewCount']?.toString() ?? 'N/A';
    final rawStreams = Formatters.parseNum(json['streamCount'] ?? json['playcount'] ?? json['playCount'] ?? json['streams'] ?? json['viewCount'] ?? 0).toInt();
    final rk = json['rank'] != null ? Formatters.parseNum(json['rank']).toInt() : rank;
    final alb = json['album'] is String ? json['album'] as String : (json['album'] is Map ? (json['album'] as Map)['name']?.toString() : null);
    final ry = json['releaseYear']?.toString() ?? (json['releaseDate'] != null ? json['releaseDate'].toString().split('-').first : null);
    String? img;
    if (json['albumImage'] != null) {
      img = json['albumImage']?.toString();
    } else if (json['image'] != null) {
      img = json['image']?.toString();
    } else if (json['snippet'] is Map && (json['snippet'] as Map)['thumbnails'] is Map) {
      final thumbs = (json['snippet'] as Map)['thumbnails'] as Map;
      if (thumbs['default'] is Map) {
        img = (thumbs['default'] as Map)['url']?.toString();
      }
    }
    final plat = json['platform']?.toString() ?? platform;

    return TrackModel(
      title: name.toString(),
      rank: rk,
      album: alb,
      releaseYear: ry,
      viewCountFormatted: viewCount,
      streamCount: rawStreams,
      imageUrl: img?.toString(),
      platform: plat,
      artistAttributedAnnualRev: Formatters.parseNum(json['artistAttributedAnnualRev']).toDouble(),
      ageInYears: Formatters.parseNum(json['ageInYears']).toDouble(),
      hasValuation: hasVal,
    );
  }
}

class ArtistProfileModel {
  final String? title;
  final int totalFollowers;
  final int popularity;
  final String imageUrl;
  final String? monthlyListeners;
  final String? biography;
  final String region;
  final List<String> genres;
  final String? spotifyUrl;
  final String? youtubeUrl;
  final String? appleUrl;
  final List<TrackModel> topTracks;
  final Map<String, dynamic>? rawJson;

  ArtistProfileModel({
    this.title,
    required this.totalFollowers,
    required this.popularity,
    required this.imageUrl,
    this.monthlyListeners,
    this.biography,
    this.region = 'Global Catalog',
    this.genres = const [],
    this.spotifyUrl,
    this.youtubeUrl,
    this.appleUrl,
    this.topTracks = const [],
    this.rawJson,
  });

  factory ArtistProfileModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ArtistProfileModel(totalFollowers: 0, popularity: 0, imageUrl: '');
    }
    
    int followers = 0;
    if (json['followers'] is Map) {
      followers = Formatters.parseNum(((json['followers'] as Map)['total'])).toInt();
    } else if (json['followersRaw'] != null) {
      followers = Formatters.parseNum(json['followersRaw']).toInt();
    } else if (json['followers'] != null) {
      followers = Formatters.parseNum(json['followers']).toInt();
    }
    
    String img = '';
    if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      img = (json['images'] as List)[0]['url'] as String? ?? '';
    } else if (json['image'] is String) {
      img = json['image'] as String;
    }

    final parsedTracks = <TrackModel>[];
    if (json['topTracks'] is List) {
      int idx = 1;
      for (var item in (json['topTracks'] as List)) {
        if (item is Map<String, dynamic>) {
          parsedTracks.add(TrackModel.fromJson(item, rank: idx, platform: 'spotify'));
          idx++;
        }
      }
    }

    final genresList = <String>[];
    if (json['genres'] is List) {
      for (var g in (json['genres'] as List)) {
        if (g != null) genresList.add(g.toString());
      }
    }

    String regionSubtitle = 'United States • Global Catalog';
    if (genresList.isNotEmpty) {
      regionSubtitle = '${genresList.take(2).join(', ')} • Global Catalog';
    }

    return ArtistProfileModel(
      title: json['name']?.toString() ?? json['title']?.toString(),
      totalFollowers: followers,
      popularity: Formatters.parseNum(json['popularity'] ?? 0).toInt(),
      imageUrl: img,
      monthlyListeners: json['monthlyListeners']?.toString(),
      biography: json['biography']?.toString(),
      region: regionSubtitle,
      genres: genresList,
      spotifyUrl: json['spotifyUrl']?.toString(),
      youtubeUrl: json['youtubeUrl']?.toString(),
      appleUrl: json['appleUrl']?.toString(),
      topTracks: parsedTracks,
      rawJson: json,
    );
  }
}

class YouTubeProfileModel {
  final int totalSubscribers;
  final int totalViews;
  final int totalVideos;
  final String? youtubeUrl;
  final List<TrackModel> videos;

  YouTubeProfileModel({
    required this.totalSubscribers,
    required this.totalViews,
    required this.totalVideos,
    this.youtubeUrl,
    required this.videos,
  });

  factory YouTubeProfileModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return YouTubeProfileModel(totalSubscribers: 0, totalViews: 0, totalVideos: 0, videos: []);
    }

    int subs = 0;
    int views = 0;
    int vids = 0;

    if (json['channels'] is List && (json['channels'] as List).isNotEmpty) {
      final stats = ((json['channels'] as List)[0] as Map)['statistics'] as Map?;
      if (stats != null) {
        subs = int.tryParse(stats['subscriberCount']?.toString() ?? '0') ?? 0;
        views = int.tryParse(stats['viewCount']?.toString() ?? '0') ?? 0;
        vids = int.tryParse(stats['videoCount']?.toString() ?? '0') ?? 0;
      }
    }

    if (subs == 0) {
      if (json['subscribers'] != null) {
        subs = Formatters.parseNum(json['subscribers']).toInt();
      } else if (json['followersRaw'] != null) {
        subs = Formatters.parseNum(json['followersRaw']).toInt();
      } else if (json['stats'] is Map && (json['stats'] as Map)['subscribers'] != null) {
        subs = Formatters.parseNum((json['stats'] as Map)['subscribers']).toInt();
      }
    }

    if (views == 0) {
      if (json['totalViews'] != null) {
        views = Formatters.parseNum(json['totalViews']).toInt();
      } else if (json['stats'] is Map && (json['stats'] as Map)['totalViews'] != null) {
        views = Formatters.parseNum((json['stats'] as Map)['totalViews']).toInt();
      }
    }

    if (vids == 0) {
      if (json['tracksCount'] != null) {
        vids = Formatters.parseNum(json['tracksCount']).toInt();
      } else if (json['stats'] is Map && (json['stats'] as Map)['totalVideos'] != null) {
        vids = Formatters.parseNum((json['stats'] as Map)['totalVideos']).toInt();
      }
    }

    final videos = <TrackModel>[];
    final trackList = (json['videos'] is List && (json['videos'] as List).isNotEmpty)
        ? (json['videos'] as List)
        : (json['topTracks'] is List ? (json['topTracks'] as List) : null);

    if (trackList != null && trackList.isNotEmpty) {
      for (var item in trackList) {
        if (item is Map<String, dynamic>) {
          videos.add(TrackModel.fromJson(item));
        }
      }
    } else if (subs > 0 || views > 0) {
      // Fallback pseudo-tracks
      videos.add(TrackModel(
        title: 'Total Channel Views',
        artistAttributedAnnualRev: 0,
        ageInYears: 0,
        viewCountFormatted: Formatters.formatNumber(views.toDouble()),
        hasValuation: false,
      ));
      videos.add(TrackModel(
        title: 'Total Subscribers',
        artistAttributedAnnualRev: 0,
        ageInYears: 0,
        viewCountFormatted: Formatters.formatNumber(subs.toDouble()),
        hasValuation: false,
      ));
      videos.add(TrackModel(
        title: 'Total Videos',
        artistAttributedAnnualRev: 0,
        ageInYears: 0,
        viewCountFormatted: Formatters.formatNumber(vids.toDouble()),
        hasValuation: false,
      ));
    }

    return YouTubeProfileModel(
      totalSubscribers: subs,
      totalViews: views,
      totalVideos: vids,
      youtubeUrl: json['youtubeUrl']?.toString(),
      videos: videos,
    );
  }
}

class AppleProfileModel {
  final String artistId;
  final String? appleUrl;
  final List<TrackModel> topTracks;

  AppleProfileModel({
    required this.artistId,
    this.appleUrl,
    required this.topTracks,
  });

  factory AppleProfileModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return AppleProfileModel(artistId: '', topTracks: []);
    }

    final tracks = <TrackModel>[];
    if (json['topTracks'] is List) {
      int idx = 1;
      for (var item in (json['topTracks'] as List)) {
        if (item is Map<String, dynamic>) {
          tracks.add(TrackModel.fromJson(item, rank: idx, platform: 'apple'));
          idx++;
        }
      }
    }

    return AppleProfileModel(
      artistId: json['id']?.toString() ?? 'N/A',
      appleUrl: json['appleUrl']?.toString() ?? json['url']?.toString(),
      topTracks: tracks,
    );
  }
}
