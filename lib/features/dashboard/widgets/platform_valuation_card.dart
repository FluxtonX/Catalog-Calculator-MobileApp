import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/formatters.dart';
import '../models/valuation_models.dart';

class PlatformValuationCard extends StatelessWidget {
  final String title;
  final Color color;
  final PlatformBreakdownModel valuation;

  const PlatformValuationCard({
    super.key,
    required this.title,
    required this.color,
    required this.valuation,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Container(
                width: 8,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Platform Valuation', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(Formatters.formatCurrency(valuation.midEstimate), style: GoogleFonts.outfit(color: color, fontSize: 36, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Annual Revenue', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(Formatters.formatCurrency(valuation.totalAnnualRevenue), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Avg. Catalog Age', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${valuation.averageDollarAge.toStringAsFixed(1)} Yrs', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: color, size: 16),
                const SizedBox(width: 8),
                Text('Methodology: ${valuation.valuationMethod}', style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
