import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class BookingScreen extends StatefulWidget {
  final String deviceName;
  final int finalQuote;
  final String conditionStr;

  const BookingScreen({
    Key? key,
    required this.deviceName,
    required this.finalQuote,
    required this.conditionStr,
  }) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _upiController = TextEditingController();

  String _selectedPayoutMode = 'UPI';
  DateTime? _selectedDate;
  String _selectedTimeSlot = '10:00 AM - 1:00 PM';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date slot for doorstep pickup.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final dateStr = "${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}";
    final payoutStr = _selectedPayoutMode == 'UPI' ? 'UPI ID: ${_upiController.text.trim()}' : 'Cash/Bank Transfer';

    final payoutDetails = "Address: ${_addressController.text.trim()}, ${_cityController.text.trim()} - ${_zipController.text.trim()} | Phone: ${_phoneController.text.trim()} | Payout: ${_selectedPayoutMode} | Details: $payoutStr | Slot: $dateStr | $_selectedTimeSlot";

    final payload = {
      "deviceName": widget.deviceName,
      "estimateQuote": widget.finalQuote,
      "condition": widget.conditionStr,
      "payoutDetails": payoutDetails,
      "custPhone": _phoneController.text.trim(),
      "custName": _nameController.text.trim(),
      "custEmail": _emailController.text.trim(),
    };

    try {
      final success = await ApiService.submitLead(payload);
      setState(() => _isSubmitting = false);

      if (success) {
        // Show success screen
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to book trade-in request. Please try again.")),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network error: failed to connect to servers.")),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.check_circle_rounded, size: 72, color: Color(0xFF2BB584)),
              const SizedBox(height: 16),
              Text(
                "Pickup Booked!",
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 22, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Text(
                "Your trade-in lead has been successfully registered. Our doorstep agent will contact you shortly.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // pop dialog
                    Navigator.of(context).pop(); // pop booking
                    Navigator.of(context).pop(); // pop wizard
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2BB584),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text("Return Home", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Details', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF2BB584),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selected Device', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF047857), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.deviceName, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF064E3B))),
                    const SizedBox(height: 12),
                    Text('Guaranteed Estimate Payout', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF047857), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('₹${widget.finalQuote.toLocaleString()}', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 24, color: const Color(0xFF059669))),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Contact Information', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A))),
              const SizedBox(height: 12),
              _buildTextField('Full Name', _nameController, true),
              const SizedBox(height: 12),
              _buildTextField('Phone Number', _phoneController, true, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildTextField('Email Address', _emailController, true, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 24),

              Text('Doorstep Pickup Address', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A))),
              const SizedBox(height: 12),
              _buildTextField('Street Address / Locality', _addressController, true),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('City', _cityController, true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Pincode', _zipController, true, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 24),

              Text('Schedule Slot', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A))),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 14)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Select Date Slot'
                            : '${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: _selectedDate == null ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.calendar_month_rounded, color: Color(0xFF2BB584)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildConditionDropdown('Preferred Time Window', _selectedTimeSlot, {
                '10:00 AM - 1:00 PM': 'Morning (10 AM - 1 PM)',
                '1:00 PM - 4:00 PM': 'Afternoon (1 PM - 4 PM)',
                '4:00 PM - 7:00 PM': 'Evening (4 PM - 7 PM)',
              }, (val) => setState(() => _selectedTimeSlot = val!)),
              const SizedBox(height: 24),

              Text('Preferred Payout Method', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF0F172A))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildPayoutRadio('UPI', 'Receive via UPI'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPayoutRadio('Cash', 'Cash / Bank Transfer'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_selectedPayoutMode == 'UPI')
                _buildTextField('Enter UPI ID (e.g. name@upi)', _upiController, true),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2BB584),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Confirm & Schedule Pickup',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool required, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (val) {
        if (required && (val == null || val.trim().isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  Widget _buildConditionDropdown(String label, String value, Map<String, String> items, void Function(String?) onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              onChanged: onChange,
              items: items.entries.map((e) {
                return DropdownMenuItem(value: e.key, child: Text(e.value, style: GoogleFonts.outfit(fontSize: 14)));
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutRadio(String mode, String label) {
    final isSelected = _selectedPayoutMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayoutMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2BB584) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? const Color(0xFF047857) : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}

extension BookingNumberFormatting on int {
  String toLocaleString() {
    final str = toString();
    if (str.length <= 3) return str;
    return str.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
