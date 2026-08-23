import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quote_booking.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class QuoteHistoryScreen extends StatefulWidget {
  const QuoteHistoryScreen({Key? key}) : super(key: key);

  @override
  State<QuoteHistoryScreen> createState() => _QuoteHistoryScreenState();
}

class _QuoteHistoryScreenState extends State<QuoteHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SavedQuote> _quotes = [];
  List<BookingRecord> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final q = await StorageService.getSavedQuotes();
    final b = await StorageService.getBookings();
    if (mounted) {
      setState(() {
        _quotes = q;
        _bookings = b;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Quotes & Pickups'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Active Bookings'),
            Tab(text: 'Saved Valuations'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsTab(),
                _buildQuotesTab(),
              ],
            ),
    );
  }

  Widget _buildBookingsTab() {
    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_rounded, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text('No active bookings yet', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Valuate your device and schedule a doorstep pickup!', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final b = _bookings[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    b.deviceName,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '₹${b.quotePrice}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppTheme.primaryGreen, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text('${b.slotDate} • ${b.slotTime}', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text('Payout via ${b.paymentMode} (${b.paymentDetail})', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuotesTab() {
    if (_quotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border_rounded, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text('No saved valuations', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Quotes calculated will automatically be saved here.', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _quotes.length,
      itemBuilder: (context, index) {
        final q = _quotes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.deviceName, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text('${q.variant} • ${q.brand.toUpperCase()}', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              Text(
                '₹${q.finalPrice}',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryGreen),
              ),
            ],
          ),
        );
      },
    );
  }
}
