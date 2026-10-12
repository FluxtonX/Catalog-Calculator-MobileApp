import 'package:flutter/material.dart';
import 'artist_valuation_screen.dart';

class ValuationDashboardScreen extends StatelessWidget {
  final String query;

  const ValuationDashboardScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return ArtistValuationScreen(query: query);
  }
}
