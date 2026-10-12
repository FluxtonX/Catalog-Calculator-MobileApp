import 'package:flutter_test/flutter_test.dart';
import 'package:catalog_calculator_flutter/services/artist_valuation_service.dart';

void main() {
  group('ArtistValuationService Unit Tests', () {
    test('100% royalty share returns exact baseline', () {
      const baseline = 242445913.0;
      final current = ArtistValuationService.calculateCurrentValuation(
        baseCatalogValue: baseline,
        royaltyShare: 100.0,
        multiple: 14.0,
      );
      expect(current, equals(242445913.0));
      expect(ArtistValuationService.formatValuation(current), equals(r'$242,445,913'));
    });

    test('50% royalty share scales dynamically', () {
      const baseline = 242445913.0;
      final current = ArtistValuationService.calculateCurrentValuation(
        baseCatalogValue: baseline,
        royaltyShare: 50.0,
        multiple: 14.0,
      );
      expect(current, equals(121222956.5));
      expect(ArtistValuationService.formatValuation(current), equals(r'$121,222,957'));
    });

    test('1, 2, and 3 platform valuations format accurately', () {
      // 1 Platform (Spotify)
      expect(ArtistValuationService.formatValuation(160000000), equals(r'$160,000,000'));
      // 2 Platforms (Spotify + YouTube)
      expect(ArtistValuationService.formatValuation(210000000), equals(r'$210,000,000'));
      // 3 Platforms (Apple + Spotify + YouTube)
      expect(ArtistValuationService.formatValuation(242445913), equals(r'$242,445,913'));
    });
  });
}
