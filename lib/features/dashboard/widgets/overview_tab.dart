import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../models/valuation_models.dart';
import 'metric_card.dart';
import 'top_tracks_list.dart';

class OverviewTab extends StatelessWidget {
  final ValuationDataModel valuationData;
  final ArtistProfileModel artistData;
  final YouTubeProfileModel? youtubeData;
  final AppleProfileModel? appleData;

  const OverviewTab({
    super.key,
    required this.valuationData,
    required this.artistData,
    this.youtubeData,
    this.appleData,
  });

  @override
  Widget build(BuildContext context) {
    int totalFollowers = artistData.totalFollowers;
    int totalSubscribers = youtubeData?.totalSubscribers ?? 0;
    int totalViews = youtubeData?.totalViews ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF10b981), Color(0xFF047857)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10b981).withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Value',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Formatters.formatCurrency(valuationData.estimatedValue),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.show_chart, color: Colors.white, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Annual Revenue',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.formatCurrency(valuationData.annualRevenue),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Return Rate',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '8.5%', // Hardcoded in the original UI
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          if (valuationData.platformBreakdowns.isNotEmpty) ...[
            Text(
              'Platform Breakdown',
              style: GoogleFonts.outfit(
                color: const Color(0xFF10b981),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...valuationData.platformBreakdowns.entries.map((e) {
              final platform = e.key;
              final data = e.value;
              final label = platform == 'spotify' || platform == 'apify' ? 'Spotify' : platform == 'itunes' || platform == 'apple' ? 'Apple Music' : 'YouTube';
              final icon = platform == 'spotify' || platform == 'apify' ? Icons.graphic_eq : platform == 'itunes' || platform == 'apple' ? Icons.music_note : Icons.smart_display;
              final color = platform == 'spotify' || platform == 'apify' ? const Color(0xFF1DB954) : platform == 'itunes' || platform == 'apple' ? Colors.white : const Color(0xFFFF0000);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Est. ${Formatters.formatCurrency(data.midEstimate)}', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(data.totalAnnualRevenue),
                      style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              );
            }),
          ],
          
          const SizedBox(height: 32),
          Text(
            'Top Tracks Analysis',
            style: GoogleFonts.outfit(
              color: const Color(0xFF10b981),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (valuationData.platformBreakdowns.containsKey('spotify') || valuationData.platformBreakdowns.containsKey('apify')) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: TopTracksList(
                title: 'Spotify Top Tracks',
                tracks: valuationData.platformBreakdowns['spotify']?.trackDetails ?? valuationData.platformBreakdowns['apify']?.trackDetails ?? [],
                color: const Color(0xFF1DB954),
              ),
            ),
          ],

          if (youtubeData != null && youtubeData!.videos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: TopTracksList(
                title: 'YouTube Top Videos',
                tracks: youtubeData!.videos,
                color: const Color(0xFFFF0000),
              ),
            ),
          ],
          
          if (appleData != null && appleData!.topTracks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: TopTracksList(
                title: 'Apple Music Top Tracks',
                tracks: appleData!.topTracks,
                color: const Color(0xFFFA243C),
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          
          Text(
            'Global Analytics',
            style: GoogleFonts.outfit(
              color: const Color(0xFF10b981),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: MetricCard(title: 'Followers', value: Formatters.formatNumber(totalFollowers.toDouble()), icon: Icons.people)),
              const SizedBox(width: 12),
              Expanded(child: MetricCard(title: 'Popularity', value: '${artistData.popularity}/100', icon: Icons.star)),
              const SizedBox(width: 12),
              Expanded(child: MetricCard(title: 'YT Views', value: Formatters.formatNumber(totalViews.toDouble()), icon: Icons.smart_display)),
            ],
          ),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
