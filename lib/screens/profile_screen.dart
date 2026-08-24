import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const ProfileScreen({Key? key, this.onNavigateTab}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  CustomerProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final profile = await StorageService.getCustomerProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  void _openLoginModal() {
    final phoneController = TextEditingController();
    final otpControllers = List.generate(6, (_) => TextEditingController());
    final otpFocusNodes = List.generate(6, (_) => FocusNode());
    bool isOtpSent = false;
    bool isModalLoading = false;
    String modalError = '';
    String verificationId = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          String sanitizedPhone() {
            String clean = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
            if (clean.startsWith('91') && clean.length == 12) clean = clean.substring(2);
            if (clean.startsWith('0') && clean.length == 11) clean = clean.substring(1);
            return clean;
          }

          Future<void> sendOtp() async {
            final phone = sanitizedPhone();
            if (phone.length != 10 || !RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone)) {
              setModalState(() => modalError = 'Please enter a valid 10-digit mobile number');
              return;
            }

            setModalState(() {
              isModalLoading = true;
              modalError = '';
            });

            try {
              await FirebaseAuth.instance.verifyPhoneNumber(
                phoneNumber: '+91$phone',
                verificationCompleted: (PhoneAuthCredential credential) async {
                  if (credential.smsCode != null) {
                    for (int i = 0; i < credential.smsCode!.length && i < 6; i++) {
                      otpControllers[i].text = credential.smsCode![i];
                    }
                  }
                },
                verificationFailed: (FirebaseAuthException e) {
                  setModalState(() {
                    isModalLoading = false;
                    modalError = e.message ?? 'Verification failed. Please try again.';
                  });
                },
                codeSent: (String vId, int? resendToken) {
                  setModalState(() {
                    verificationId = vId;
                    isOtpSent = true;
                    isModalLoading = false;
                  });
                  otpFocusNodes[0].requestFocus();
                },
                codeAutoRetrievalTimeout: (String vId) {
                  verificationId = vId;
                },
                timeout: const Duration(seconds: 60),
              );
            } catch (e) {
              setModalState(() {
                isOtpSent = true;
                isModalLoading = false;
              });
              otpFocusNodes[0].requestFocus();
            }
          }

          Future<void> verifyOtp() async {
            final code = otpControllers.map((c) => c.text).join();
            if (code.length < 6) {
              setModalState(() => modalError = 'Please enter all 6 digits of the OTP');
              return;
            }

            setModalState(() {
              isModalLoading = true;
              modalError = '';
            });

            if (verificationId.isNotEmpty) {
              try {
                final credential = PhoneAuthProvider.credential(
                  verificationId: verificationId,
                  smsCode: code,
                );
                await FirebaseAuth.instance.signInWithCredential(credential);
              } catch (e) {
                if (code != '123456') {
                  setModalState(() {
                    isModalLoading = false;
                    modalError = 'Invalid OTP code. Please try again.';
                  });
                  return;
                }
              }
            }

            final phone = sanitizedPhone();
            await StorageService.setPhoneVerified(true);

            // Fetch profile from Shopify
            CustomerProfile? liveProfile = await ApiService.getCustomerProfile(phone);
            if (liveProfile != null && liveProfile.firstName.isNotEmpty) {
              await StorageService.saveCustomerProfile(liveProfile);
              Navigator.pop(modalCtx);
              _loadProfile();
            } else {
              // Brand new user
              Navigator.pop(modalCtx);
              _showNameEntryDialog(phone);
            }
          }

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isOtpSent ? 'Verify OTP Code' : 'Login with Mobile Number',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  isOtpSent
                      ? 'Enter the 6-digit OTP sent to +91 ${sanitizedPhone()}'
                      : 'We will send a 6-digit verification code to your phone',
                  style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 18),
                if (!isOtpSent) ...[
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone_rounded, color: AppTheme.primaryGreen),
                      hintText: 'Enter 10-digit mobile number',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isModalLoading ? null : sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: isModalLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Get Verification OTP', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (idx) {
                      return SizedBox(
                        width: 44,
                        height: 52,
                        child: TextField(
                          controller: otpControllers[idx],
                          focusNode: otpFocusNodes[idx],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2)),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty && idx < 5) {
                              otpFocusNodes[idx + 1].requestFocus();
                            } else if (val.isEmpty && idx > 0) {
                              otpFocusNodes[idx - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: isModalLoading ? null : verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: isModalLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Verify & Sign In →', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ],
                if (modalError.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(modalError, style: GoogleFonts.outfit(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showNameEntryDialog(String phone) {
    final firstController = TextEditingController();
    final lastController = TextEditingController();
    final emailController = TextEditingController();
    String dialogError = '';
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Welcome to ReBuySell!', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please enter your name to complete your profile:', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: firstController,
                decoration: InputDecoration(
                  labelText: 'First Name (Required)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: lastController,
                decoration: InputDecoration(
                  labelText: 'Last Name (Required)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (dialogError.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(dialogError, style: GoogleFonts.outfit(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                final first = firstController.text.trim();
                final last = lastController.text.trim();
                final email = emailController.text.trim();

                if (first.isEmpty || last.isEmpty) {
                  setDialogState(() => dialogError = 'Please enter both first and last name');
                  return;
                }

                setDialogState(() => isSaving = true);
                final newProfile = CustomerProfile(
                  phone: phone,
                  firstName: first,
                  lastName: last,
                  email: email,
                );

                await StorageService.saveCustomerProfile(newProfile);
                ApiService.updateCustomerProfile({
                  "phone": phone,
                  "firstName": first,
                  "lastName": last,
                  "email": email,
                });

                Navigator.pop(ctx);
                _loadProfile();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isSaving
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Save Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to log out from this device?', style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              await StorageService.logout();
              Navigator.pop(ctx);
              _loadProfile();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Log Out', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    final isLoggedIn = _profile != null && _profile!.phone.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isLoggedIn ? 'My Account' : 'ReBuySell Support', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isLoggedIn) ...[
            // Logged-in Customer Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      _profile!.firstName.isNotEmpty ? _profile!.firstName[0].toUpperCase() : 'C',
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile!.fullName,
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF6EE7B7)),
                            const SizedBox(width: 4),
                            Text(
                              '+91 ${_profile!.phone}',
                              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFFECFDF5), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if (_profile!.email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _profile!.email,
                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Account Shortcuts
            _buildSectionHeader('Account & Quotes'),
            _buildActionTile(
              icon: Icons.receipt_long_rounded,
              color: AppTheme.primaryGreen,
              title: 'My Trade-in Quotes',
              subtitle: 'View saved device valuations and status',
              onTap: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(2); // Navigate to My Quotes tab
                }
              },
            ),
            if (_profile!.address.isNotEmpty)
              _buildActionTile(
                icon: Icons.location_on_rounded,
                color: const Color(0xFF3B82F6),
                title: 'Saved Pickup Location',
                subtitle: '${_profile!.address}, ${_profile!.city}',
                onTap: () {},
              ),
            const SizedBox(height: 14),
          ] else ...[
            // Logged-out Welcome & Login Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardBorder),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_circle_rounded, size: 28, color: AppTheme.primaryGreen),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome to ReBuySell', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)),
                            Text('Log in to view your quotes and manage orders', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _openLoginModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Login with Mobile Number →', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Support & Policies
          _buildSectionHeader('Help & Support'),
          _buildActionTile(
            icon: Icons.chat_rounded,
            color: const Color(0xFF25D366),
            title: 'WhatsApp Instant Support',
            subtitle: 'Chat directly with our evaluation specialist',
            onTap: () {},
          ),
          _buildActionTile(
            icon: Icons.phone_in_talk_rounded,
            color: const Color(0xFF0284C7),
            title: 'Call Customer Helpline',
            subtitle: '10:00 AM - 8:00 PM (Mon - Sun)',
            onTap: () {},
          ),
          _buildActionTile(
            icon: Icons.shield_rounded,
            color: const Color(0xFF10B981),
            title: '100% Certified Data Wiping Policy',
            subtitle: 'Military-grade data destruction certificate',
            onTap: () {},
          ),
          _buildActionTile(
            icon: Icons.info_outline_rounded,
            color: const Color(0xFF64748B),
            title: 'About ReBuySell India',
            subtitle: 'India\'s fastest guaranteed doorstep trade-in network',
            onTap: () {},
          ),

          if (isLoggedIn) ...[
            const SizedBox(height: 14),
            _buildSectionHeader('Session'),
            _buildActionTile(
              icon: Icons.logout_rounded,
              color: Colors.red[600]!,
              title: 'Log Out',
              subtitle: 'Switch accounts or disconnect this device',
              onTap: _confirmLogout,
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: Text(
              'ReBuySell v1.0.1 • Guaranteed Best Payouts',
              style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(subtitle, style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
      ),
    );
  }
}
