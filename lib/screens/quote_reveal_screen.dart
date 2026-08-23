import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quote_booking.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'booking_screen.dart';

class QuoteRevealScreen extends StatefulWidget {
  final SavedQuote savedQuote;
  final CustomerProfile customerProfile;

  const QuoteRevealScreen({
    Key? key,
    required this.savedQuote,
    required this.customerProfile,
  }) : super(key: key);

  @override
  State<QuoteRevealScreen> createState() => _QuoteRevealScreenState();
}

class _QuoteRevealScreenState extends State<QuoteRevealScreen> {
  final _couponController = TextEditingController();
  final _pincodeController = TextEditingController();

  int _couponBonus = 0;
  String _appliedCode = '';
  String _couponMsg = '';
  String _pincodeMsg = '';
  bool _isServiceable = false;

  final Map<String, int> _validCoupons = {
    'NEW300': 300,
    'REBUY500': 500,
    'WELCOME200': 200,
    'REBUY1000': 1000,
  };

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    if (_validCoupons.containsKey(code)) {
      setState(() {
        _couponBonus = _validCoupons[code]!;
        _appliedCode = code;
        _couponMsg = '✓ Coupon "$code" applied! +₹$_couponBonus extra bonus added to your quote.';
      });
    } else {
      setState(() {
        _couponBonus = 0;
        _appliedCode = '';
        _couponMsg = '✕ Invalid promo code "$code". Try code "NEW300" for +₹300 bonus.';
      });
    }
  }

  void _verifyPincode() {
    final pin = _pincodeController.text.trim();
    if (pin.length != 6) {
      setState(() {
        _pincodeMsg = 'Please enter a valid 6-digit pincode.';
        _isServiceable = false;
      });
      return;
    }

    final prefix = pin.substring(0, 3);
    final serviceable = ['226', '208', '209', '225', '227', '110', '400', '560', '500'].contains(prefix);

    setState(() {
      _isServiceable = serviceable;
      if (serviceable) {
        _pincodeMsg = '✓ Free Doorstep Pickup & Instant Online Payout available in $pin!';
      } else {
        _pincodeMsg = '✓ Serviceable for pickup in $pin!';
        _isServiceable = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final finalPrice = widget.savedQuote.finalPrice + _couponBonus;
    final breakdown = widget.savedQuote.breakdown;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Official Trade-In Quote'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Guaranteed Price Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E8761), Color(0xFF2BB584)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  blurRadius: 12,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'GUARANTEED VALUATION',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.white, letterSpacing: 0.5),
                      ),
                    ),
                    Text(
                      'Quote for ${widget.customerProfile.firstName}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  widget.savedQuote.deviceName,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white),
                ),
                Text(
                  'Variant: ${widget.savedQuote.variant}',
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹${finalPrice.toString().replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (Match m) => '${m[1]},')}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 32, color: Colors.white),
                    ),
                    if (_couponBonus > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(+₹$_couponBonus bonus)',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.accentOrange),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Includes ReBuySell +₹1,000 to +₹2,500 Best Price Guarantee Markup',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Condition Badges
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Evaluated Condition', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildBadge('Age: ${breakdown['age'] ?? 'Under 3m'}'),
                    _buildBadge('Screen: ${breakdown['screen'] ?? 'Flawless'}'),
                    _buildBadge('Body: ${breakdown['body'] ?? 'Flawless'}'),
                    if ((breakdown['accessories'] as List?)?.contains('box') == true) _buildBadge('Box: Yes', isPositive: true),
                    if ((breakdown['accessories'] as List?)?.contains('charger') == true) _buildBadge('Charger: Yes', isPositive: true),
                    if ((breakdown['accessories'] as List?)?.contains('bill') == true) _buildBadge('Bill: Yes', isPositive: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Promo Code Coupon Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Have a Promo Code?', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Enter code (e.g. NEW300)',
                          hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _applyCoupon,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Apply', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                if (_couponMsg.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _couponMsg,
                    style: GoogleFonts.outfit(
                      color: _appliedCode.isNotEmpty ? AppTheme.primaryGreen : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Pincode Check
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Check Doorstep Service Availability', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'Enter 6-digit Pincode',
                          hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _verifyPincode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Check', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                if (_pincodeMsg.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _pincodeMsg,
                    style: GoogleFonts.outfit(
                      color: _isServiceable ? AppTheme.primaryGreen : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5. Book Pickup Button
          ElevatedButton(
            onPressed: () {
              final updatedQuote = SavedQuote(
                id: widget.savedQuote.id,
                deviceName: widget.savedQuote.deviceName,
                brand: widget.savedQuote.brand,
                category: widget.savedQuote.category,
                variant: widget.savedQuote.variant,
                finalPrice: finalPrice,
                createdAt: widget.savedQuote.createdAt,
                breakdown: widget.savedQuote.breakdown,
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingScreen(
                    savedQuote: updatedQuote,
                    customerProfile: widget.customerProfile,
                    initialPincode: _pincodeController.text.trim(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              'Book Free Doorstep Pickup (₹${finalPrice.toString().replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (Match m) => '${m[1]},')})',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, {bool isPositive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPositive ? AppTheme.primaryGreen.withOpacity(0.08) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isPositive ? AppTheme.primaryGreen.withOpacity(0.3) : AppTheme.cardBorder),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isPositive ? AppTheme.primaryGreen : AppTheme.textMain,
        ),
      ),
    );
  }
}
