import 'package:catalog_calculator_flutter/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../models/valuation_models.dart';

class TopTracksList extends StatelessWidget {
  final String title;
  final List<TrackModel> tracks;
  final Color color;

  const TopTracksList({
    super.key,
    required this.title,
    required this.tracks,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Text(
                  'Top ${tracks.length.clamp(0, 10)}',
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tracks.take(10).map((track) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildLeftSide(track),
                    ),
                    if (track.hasValuation || track.viewCountFormatted != 'N/A') const SizedBox(width: 16),
                    _buildRightSide(track),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLeftSide(TrackModel track) {
    if (track.hasValuation) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Age: ${track.ageInYears.toStringAsFixed(1)} yrs',
            style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      );
    }
    return Text(
      track.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }

  Widget _buildRightSide(TrackModel track) {
    if (track.hasValuation) {
      return Text(
        Formatters.formatCurrency(track.artistAttributedAnnualRev),
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      );
    }
    if (track.viewCountFormatted != 'N/A') {
      return Text(
        track.viewCountFormatted,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

