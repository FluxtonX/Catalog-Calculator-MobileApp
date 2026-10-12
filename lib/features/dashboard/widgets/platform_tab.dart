import 'package:flutter/material.dart';
import '../models/valuation_models.dart';
import 'platform_stat_card.dart';
import 'platform_valuation_card.dart';
import 'top_tracks_list.dart';

class PlatformTab extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Map<String, String> stats;
  final PlatformBreakdownModel? valuation;
  final List<TrackModel>? fallbackTracks;

  const PlatformTab({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.stats,
    this.valuation,
    this.fallbackTracks,
  });

  @override
  Widget build(BuildContext context) {
    final hasValuation = valuation != null;
    final hasTracks = (valuation?.trackDetails != null && valuation!.trackDetails.isNotEmpty) || (fallbackTracks != null && fallbackTracks!.isNotEmpty);
    final trackList = (valuation?.trackDetails != null && valuation!.trackDetails.isNotEmpty) ? valuation!.trackDetails : (fallbackTracks ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasValuation)
            PlatformValuationCard(
              title: '$title CFA Valuation',
              color: color,
              valuation: valuation!,
            ),
          if (hasValuation) const SizedBox(height: 24),
          PlatformStatCard(
            title: '$title Catalog Stats',
            icon: icon,
            color: color,
            stats: stats,
          ),
          if (hasTracks) ...[
            const SizedBox(height: 24),
            TopTracksList(
              title: '$title Top Tracks',
              tracks: trackList,
              color: color,
            ),
          ],
        ],
      ),
    );
  }
}
