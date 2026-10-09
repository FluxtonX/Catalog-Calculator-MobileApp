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
    required this.estimatedValue,
    required this.artistData,
    this.youtubeData,
    this.appleData,
  });

  final double estimatedValue;
  final Map<String, dynamic> artistData;
  final Map<String, dynamic>? youtubeData;
  final Map<String, dynamic>? appleData;

  @override
  List<Object?> get props => [estimatedValue, artistData, youtubeData, appleData];
}

class SearchArtistError extends SearchArtistState {
  const SearchArtistError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
