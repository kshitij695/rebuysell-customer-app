import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quote_booking.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class BookingScreen extends StatefulWidget {
  final SavedQuote savedQuote;

  const BookingScreen({Key? key, required this.savedQuote}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _paymentDetailController = TextEditingController();

  String _paymentMode = 'UPI'; // STRICTLY ONLINE: 'UPI' or 'BANK_TRANSFER' (NO CASH)
  String _selectedDate = 'Tomorrow';
  String _selectedSlot = '10 AM - 1 PM';
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Doorstep Pickup'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildValuationSummary(),
            const SizedBox(height: 16),
            _buildCustomerDetails(),
            const SizedBox(height: 16),
            _buildSlotSelector(),
            const SizedBox(height: 16),
            _buildPaymentMethodSelector(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildValuationSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.savedQuote.deviceName,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  widget.savedQuote.variant,
                  style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Guaranteed Payout', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted)),
              Text(
                '₹${widget.savedQuote.finalPrice}',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pickup Address & Contact', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 14),
          TextFormField(
            controller: _nameController,
            decoration: _inputDeco('Full Name', Icons.person_rounded),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDeco('Phone Number (WhatsApp)', Icons.phone_rounded),
            validator: (v) => (v == null || v.trim().length < 10) ? 'Enter a valid 10-digit mobile' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            decoration: _inputDeco('Complete Doorstep Address', Icons.home_rounded),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your pickup address' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pincodeController,
            keyboardType: TextInputType.number,
            decoration: _inputDeco('Pincode', Icons.pin_drop_rounded),
            validator: (v) => (v == null || v.trim().length != 6) ? 'Enter a valid 6-digit pincode' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSlotSelector() {
    final dates = ['Today', 'Tomorrow', 'Day After'];
    final slots = ['10 AM - 1 PM', '1 PM - 4 PM', '4 PM - 7 PM'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Pickup Date & Time', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: dates.map((d) {
              final isSel = _selectedDate == d;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDate = d),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSel ? AppTheme.primaryGreen : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      d,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: isSel ? Colors.white : AppTheme.textMain,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: slots.map((s) {
              final isSel = _selectedSlot == s;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSlot = s),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSel ? AppTheme.primaryGreen : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      s,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: isSel ? Colors.white : AppTheme.textMain,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Instant Online Payout', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('100% CASHLESS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 9)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Money is transferred directly to your account upon inspection', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _paymentMode = 'UPI'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _paymentMode == 'UPI' ? AppTheme.primaryGreen.withOpacity(0.08) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _paymentMode == 'UPI' ? AppTheme.primaryGreen : AppTheme.cardBorder, width: _paymentMode == 'UPI' ? 2 : 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_rounded, size: 18, color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Text('Instant UPI ID', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _paymentMode = 'BANK_TRANSFER'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _paymentMode == 'BANK_TRANSFER' ? AppTheme.primaryGreen.withOpacity(0.08) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _paymentMode == 'BANK_TRANSFER' ? AppTheme.primaryGreen : AppTheme.cardBorder, width: _paymentMode == 'BANK_TRANSFER' ? 2 : 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_balance_rounded, size: 18, color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Text('Bank Transfer', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _paymentDetailController,
            decoration: _inputDeco(
              _paymentMode == 'UPI' ? 'Enter UPI ID (e.g. name@okhdfcbank)' : 'Bank Account No & IFSC Code',
              _paymentMode == 'UPI' ? Icons.alternate_email_rounded : Icons.credit_card_rounded,
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter payment destination' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitBooking,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            )
          : Text(
              'Confirm Doorstep Booking (₹${widget.savedQuote.finalPrice})',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 15),
            ),
    );
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final bookingId = 'RBS-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    final payload = {
      'bookingId': bookingId,
      'device': widget.savedQuote.deviceName,
      'variant': widget.savedQuote.variant,
      'category': widget.savedQuote.category,
      'price': widget.savedQuote.finalPrice,
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'slot': '$_selectedDate ($_selectedSlot)',
      'paymentMode': _paymentMode,
      'paymentDetail': _paymentDetailController.text.trim(),
      'breakdown': widget.savedQuote.breakdown,
    };

    // 1. Submit lead to Cloudflare Worker
    await ApiService.submitLead(payload);

    // 2. Save local booking record
    final record = BookingRecord(
      bookingId: bookingId,
      deviceName: widget.savedQuote.deviceName,
      quotePrice: widget.savedQuote.finalPrice,
      customerName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      slotDate: _selectedDate,
      slotTime: _selectedSlot,
      paymentMode: _paymentMode,
      paymentDetail: _paymentDetailController.text.trim(),
      timestamp: DateTime.now(),
    );
    await StorageService.saveBooking(record);

    setState(() => _isSubmitting = false);

    _showSuccessDialog(bookingId);
  }

  void _showSuccessDialog(String bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, size: 48, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 16),
            Text('Booking Confirmed!', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              'Your pickup is scheduled for $_selectedDate ($_selectedSlot).\n\nBooking Ref: $bookingId',
              style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textMuted),
      prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5)),
    );
  }
}
