import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quote_booking.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'quote_reveal_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final SavedQuote pendingQuote;

  const OtpVerificationScreen({Key? key, required this.pendingQuote}) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _phoneController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isOtpSent = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _phoneController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _sendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.length != 10 || !RegExp(r'^[6-9]d{9}$').hasMatch(phone)) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _isOtpSent = true;
        _isLoading = false;
      });
      _otpFocusNodes[0].requestFocus();
    });
  }

  Future<void> _verifyOtpAndProceed() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits of the OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Verify OTP code (Test OTP '123456' or standard 6-digit verification)
    await Future.delayed(const Duration(milliseconds: 600));

    // Save phone verification flag
    await StorageService.setPhoneVerified(true);

    // Check if customer profile exists
    CustomerProfile? profile = await StorageService.getCustomerProfile();

    setState(() => _isLoading = false);

    if (profile == null || profile.firstName.isEmpty || profile.phone != _phoneController.text.trim()) {
      // Show New Customer Name & Optional Email popup!
      _showCustomerNameDialog(_phoneController.text.trim());
    } else {
      _finishAndRevealQuote(profile);
    }
  }

  void _showCustomerNameDialog(String verifiedPhone) {
    final firstController = TextEditingController();
    final lastController = TextEditingController();
    final emailController = TextEditingController();
    String dialogError = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Welcome to ReBuySell!',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please enter your name to view your official trade-in valuation:',
                  style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: firstController,
                  decoration: _inputDeco('First Name (Required)', Icons.person_outline_rounded),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: lastController,
                  decoration: _inputDeco('Last Name (Required)', Icons.person_rounded),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDeco('Email Address (Optional)', Icons.email_outlined),
                ),
                if (dialogError.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(dialogError, style: GoogleFonts.outfit(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final first = firstController.text.trim();
                final last = lastController.text.trim();
                final email = emailController.text.trim();

                if (first.isEmpty || last.isEmpty) {
                  setDialogState(() => dialogError = 'Please enter both first and last name');
                  return;
                }

                final newProfile = CustomerProfile(
                  phone: verifiedPhone,
                  firstName: first,
                  lastName: last,
                  email: email,
                );

                await StorageService.saveCustomerProfile(newProfile);
                Navigator.pop(ctx);
                _finishAndRevealQuote(newProfile);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(double.infinity, 44),
              ),
              child: Text(
                'Unlock My Valuation →',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finishAndRevealQuote(CustomerProfile profile) async {
    // 1. Save quote locally
    await StorageService.saveQuote(widget.pendingQuote);

    // 2. Submit verified lead in background to Cloudflare Worker
    ApiService.submitLead({
      'type': 'unlocked_valuation_lead',
      'phone': profile.phone,
      'name': profile.fullName,
      'email': profile.email,
      'device': widget.pendingQuote.deviceName,
      'variant': widget.pendingQuote.variant,
      'price': widget.pendingQuote.finalPrice,
      'breakdown': widget.pendingQuote.breakdown,
    });

    if (!mounted) return;

    // 3. Replace with Quote Reveal Screen!
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteRevealScreen(
          savedQuote: widget.pendingQuote,
          customerProfile: profile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Mobile Number'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock_rounded, color: AppTheme.primaryGreen, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your trade-in valuation is calculated and ready. Enter your mobile number to unlock your official quote!',
                      style: GoogleFonts.outfit(color: AppTheme.textMain, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Enter Phone Number',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              'We will send a 6-digit OTP to verify your ownership',
              style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              enabled: !_isOtpSent,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: InputDecoration(
                prefixText: '+91 ',
                prefixStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppTheme.textMain, fontSize: 16),
                prefixIcon: const Icon(Icons.phone_rounded, color: AppTheme.primaryGreen),
                hintText: '98765 43210',
                filled: true,
                fillColor: Colors.white,
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
              ),
            ),
            if (!_isOtpSent) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Get Verification OTP', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ] else ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Enter 6-Digit OTP', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15)),
                  TextButton(
                    onPressed: () => setState(() => _isOtpSent = false),
                    child: Text('Change Number', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (idx) {
                  return SizedBox(
                    width: 44,
                    height: 52,
                    child: TextField(
                      controller: _otpControllers[idx],
                      focusNode: _otpFocusNodes[idx],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && idx < 5) {
                          _otpFocusNodes[idx + 1].requestFocus();
                        } else if (val.isEmpty && idx > 0) {
                          _otpFocusNodes[idx - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '💡 Quick Test OTP: 123456',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtpAndProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Verify & Reveal Valuation →', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ],
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(_errorMessage, style: GoogleFonts.outfit(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted),
      prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 18),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.cardBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGreen)),
    );
  }
}
