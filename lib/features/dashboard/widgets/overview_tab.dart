import 'package:catalog_calculator_flutter/core/theme/app_theme.dart';
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
    final totalFollowers = artistData.totalFollowers;
    final totalViews = youtubeData?.totalViews ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Valuation Hero Card (Mirroring website CfaMasterValuation)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B101A), Color(0xFF05080F)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.borderColor),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brandCyan.withValues(alpha: 0.1),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Combined Platforms Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up, size: 14, color: AppTheme.emeraldLight),
                          const SizedBox(width: 6),
                          Text(
                            'COMBINED PLATFORMS',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.brandCyan.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.brandCyan.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(Icons.show_chart, color: AppTheme.brandCyan, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Estimated Value',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Formatters.formatCurrency(valuationData.estimatedValue),
                      maxLines: 1,
                      softWrap: false,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estimated Market Value (8x)',
                  style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Annual Revenue',
                              style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.formatCurrency(valuationData.annualRevenue),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Return Rate',
                              style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '8.5%',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
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
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            ...valuationData.platformBreakdowns.entries.map((e) {
              final platform = e.key;
              final data = e.value;
              final label = platform == 'spotify' || platform == 'apify' ? 'Spotify' : platform == 'itunes' || platform == 'apple' ? 'Apple Music' : 'YouTube';
              final icon = platform == 'spotify' || platform == 'apify' ? Icons.graphic_eq : platform == 'itunes' || platform == 'apple' ? Icons.music_note : Icons.smart_display;
              final color = platform == 'spotify' || platform == 'apify' ? AppTheme.spotifyGreen : platform == 'itunes' || platform == 'apple' ? Colors.white : AppTheme.youtubeRed;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.25)),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Est. ${Formatters.formatCurrency(data.midEstimate)}',
                            style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(data.totalAnnualRevenue),
                      style: GoogleFonts.inter(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          
          const SizedBox(height: 32),
          Text(
            'Top Tracks Analysis',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          
          if (valuationData.platformBreakdowns.containsKey('spotify') || valuationData.platformBreakdowns.containsKey('apify')) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: TopTracksList(
                title: 'Spotify Top Tracks',
                tracks: valuationData.platformBreakdowns['spotify']?.trackDetails ?? valuationData.platformBreakdowns['apify']?.trackDetails ?? [],
                color: AppTheme.spotifyGreen,
              ),
            ),
          ],

          if (youtubeData != null && youtubeData!.videos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: TopTracksList(
                title: 'YouTube Top Videos',
                tracks: youtubeData!.videos,
                color: AppTheme.youtubeRed,
              ),
            ),
          ],
          
          if (appleData != null && appleData!.topTracks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: TopTracksList(
                title: 'Apple Music Top Tracks',
                tracks: appleData!.topTracks,
                color: AppTheme.appleRed,
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          
          Text(
            'Global Analytics',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
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

