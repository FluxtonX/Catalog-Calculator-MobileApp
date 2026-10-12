import '../../dashboard/models/valuation_models.dart';
import 'package:equatable/equatable.dart';

abstract class SearchArtistState extends Equatable {
  const SearchArtistState();

  @override
  List<Object?> get props => [];
}

class SearchArtistInitial extends SearchArtistState {}

class SearchArtistLoading extends SearchArtistState {}


class SearchArtistLoaded extends SearchArtistState {
  const SearchArtistLoaded({
    required this.valuationData,
    required this.artistData,
    this.youtubeData,
    this.appleData,
    this.selectedPlatforms = const {'spotify': true, 'youtube': true, 'apple': true},
  });

  final ValuationDataModel valuationData;
  final ArtistProfileModel artistData;
  final YouTubeProfileModel? youtubeData;
  final AppleProfileModel? appleData;
  final Map<String, bool> selectedPlatforms;

  @override
  List<Object?> get props => [valuationData, artistData, youtubeData, appleData, selectedPlatforms];
}

class SearchArtistError extends SearchArtistState {
  const SearchArtistError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
