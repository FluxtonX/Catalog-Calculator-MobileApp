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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF13201e),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
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
          Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 2),
          Text('Age: ${track.ageInYears.toStringAsFixed(1)} yrs', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
        ],
      );
    }
    return Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14));
  }

  Widget _buildRightSide(TrackModel track) {
    if (track.hasValuation) {
      return Text(Formatters.formatCurrency(track.artistAttributedAnnualRev), style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold, fontSize: 14));
    }
    if (track.viewCountFormatted != 'N/A') {
      return Text(track.viewCountFormatted, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold, fontSize: 14));
    }
    return const SizedBox.shrink();
  }
}
