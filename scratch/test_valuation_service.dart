import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:catalog_calculator_flutter/services/artist_valuation_service.dart';

void main() async {
  final envFile = File('.env');
  if (envFile.existsSync()) {
    dotenv.testLoad(fileInput: envFile.readAsStringSync());
  }

  final supabaseUrl = dotenv.env['EXPO_PUBLIC_SUPABASE_URL'] ?? 'https://ubenhhgxamprkamptpoz.supabase.co';
  final supabaseKey = dotenv.env['EXPO_PUBLIC_SUPABASE_ANON_KEY'] ?? '';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  print('Testing ArtistValuationService:');

  // Test 1 Platform (spotify)
  final val1 = await ArtistValuationService.fetchCatalogValuation(
    artistName: 'Bad Bunny',
    activePlatforms: ['spotify'],
  );
  print('1 Platform [spotify]: \$val1 -> ${ArtistValuationService.formatValuation(val1)}');

  // Test 2 Platforms (spotify, youtube)
  final val2 = await ArtistValuationService.fetchCatalogValuation(
    artistName: 'Bad Bunny',
    activePlatforms: ['spotify', 'youtube'],
  );
  print('2 Platforms [spotify, youtube]: \$val2 -> ${ArtistValuationService.formatValuation(val2)}');

  // Test 3 Platforms (apple/itunes, spotify, youtube)
  final val3 = await ArtistValuationService.fetchCatalogValuation(
    artistName: 'Bad Bunny',
    activePlatforms: ['apple', 'spotify', 'youtube'],
  );
  print('3 Platforms [apple, spotify, youtube]: \$val3 -> ${ArtistValuationService.formatValuation(val3)}');

  // Test scaling with 50% royalty share
  final scaled = ArtistValuationService.calculateCurrentValuation(
    baseCatalogValue: val3,
    royaltyShare: 50.0,
    multiple: 14.0,
  );
  print('Scaled (50% Royalty Share): \$scaled -> ${ArtistValuationService.formatValuation(scaled)}');
}
