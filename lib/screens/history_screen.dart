import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/formatters.dart';
import 'artist_valuation_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('user_reports')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _reports = List<Map<String, dynamic>>.from(res as List);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0F172A);
    const brandGreen = Color(0xFF10B981);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'Valuation History',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: user == null
          ? _buildLoginPrompt()
          : _isLoading
              ? const Center(child: CircularProgressIndicator(color: brandGreen))
              : _reports.isEmpty
                  ? _buildEmptyView(brandGreen)
                  : _buildReportsList(),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: Color(0xFF00E5FF), size: 54),
            const SizedBox(height: 16),
            Text(
              'Sign In to View History',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your computed valuations and bookmarked catalog reports will automatically sync across your devices.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(Color brandGreen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: brandGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history, size: 54, color: brandGreen),
            ),
            const SizedBox(height: 20),
            Text(
              'No Valuations Yet',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search an artist and calculate their catalog valuation to save reports here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white60,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsList() {
    return RefreshIndicator(
      onRefresh: _loadReports,
      color: const Color(0xFF10B981),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final r = _reports[index];
          final artistName = r['artist_name'] ?? 'Unknown Artist';
          final platform = r['platform'] ?? 'spotify';
          final value = Formatters.parseNum(r['estimated_value']).toDouble();

          Color platformColor = const Color(0xFF1DB954);
          if (platform == 'youtube') platformColor = const Color(0xFFFF0000);
          if (platform == 'apple' || platform == 'itunes') platformColor = const Color(0xFFFA243C);

          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ArtistValuationScreen(query: artistName),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: platformColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.bar_chart, color: platformColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artistName,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: platformColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                platform.toString().toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: platformColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.formatCurrency(value),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF00E5FF),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
