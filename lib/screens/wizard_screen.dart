import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'booking_screen.dart';

class WizardScreen extends StatefulWidget {
  final String category;
  final String brand;
  final Map<String, dynamic> modelData;
  final Map<String, dynamic> pricingConfig;

  const WizardScreen({
    Key? key,
    required this.category,
    required this.brand,
    required this.modelData,
    required this.pricingConfig,
  }) : super(key: key);

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  int _currentStep = 1;
  String _selectedVariant = '';

  // Form selections
  String _selectedAge = 'under-3m';
  String _selectedScreen = 'flawless';
  String _selectedBody = 'flawless';

  // Defects checklist
  final Map<String, bool> _defects = {
    'frontcam': false,
    'backcam': false,
    'cameraglass': false,
    'buttons': false,
    'faceid': false,
    'touchid': false,
    'sound': false,
    'mic': false,
    'network': false,
    'chargeport': false,
    'vibrator': false,
    'proximity': false,
    'appleservice': false,
    'androidbattery': false,
  };

  // Accessories checklist
  bool _hasBox = true;
  bool _hasCharger = true;
  bool _hasBill = true;

  @override
  void initState() {
    super.initState();
    // Default to first variant
    final pricesMap = widget.modelData['prices'] as Map<String, dynamic>? ?? {};
    if (pricesMap.isNotEmpty) {
      _selectedVariant = pricesMap.keys.first;
    }
  }

  int _calculateFinalPrice() {
    final pricesMap = widget.modelData['prices'] as Map<String, dynamic>? ?? {};
    final basePrice = double.tryParse(pricesMap[_selectedVariant]?.toString() ?? '0') ?? 0.0;

    final config = widget.pricingConfig;
    final deductionsMap = config['deductions'] as Map<String, dynamic>? ?? {};
    final ageConfig = deductionsMap['age'] as Map<String, dynamic>? ?? {};
    final screenConfig = deductionsMap['screen'] as Map<String, dynamic>? ?? {};
    final bodyConfig = deductionsMap['body'] as Map<String, dynamic>? ?? {};
    final functionalConfig = deductionsMap['functional'] as Map<String, dynamic>? ?? {};
    final accessoriesConfig = deductionsMap['accessories'] as Map<String, dynamic>? ?? {};
    final markupsConfig = config['markups'] as Map<String, dynamic>? ?? {};

    double deductions = 0.0;

    // Age
    deductions += double.tryParse(ageConfig[_selectedAge]?.toString() ?? (_selectedAge == '3-6m' ? '0.05' : _selectedAge == '6-11m' ? '0.10' : _selectedAge == 'above-11m' ? '0.15' : '0.0')) ?? 0.0;

    // Screen
    deductions += double.tryParse(screenConfig[_selectedScreen]?.toString() ?? (_selectedScreen == 'scratches' ? '0.10' : _selectedScreen == 'heavy' ? '0.20' : _selectedScreen == 'cracked' ? '0.45' : '0.0')) ?? 0.0;

    // Body
    deductions += double.tryParse(bodyConfig[_selectedBody]?.toString() ?? (_selectedBody == 'scratches' ? '0.05' : _selectedBody == 'dents' ? '0.20' : _selectedBody == 'broken' ? '0.35' : '0.0')) ?? 0.0;

    // Functional defects
    _defects.forEach((key, value) {
      if (value) {
        double fallback = 0.0;
        if (key == 'frontcam') fallback = 0.05;
        else if (key == 'backcam') fallback = 0.10;
        else if (key == 'cameraglass') fallback = 0.03;
        else if (key == 'buttons') fallback = 0.05;
        else if (key == 'faceid') fallback = 0.10;
        else if (key == 'touchid') fallback = 0.08;
        else if (key == 'sound') fallback = 0.05;
        else if (key == 'mic') fallback = 0.05;
        else if (key == 'network') fallback = 0.08;
        else if (key == 'chargeport') fallback = 0.05;
        else if (key == 'vibrator') fallback = 0.02;
        else if (key == 'proximity') fallback = 0.03;
        else if (key == 'appleservice') fallback = 0.10;
        else if (key == 'androidbattery') fallback = 0.10;

        deductions += double.tryParse(functionalConfig[key]?.toString() ?? fallback.toString()) ?? 0.0;
      }
    });

    // Accessories
    if (!_hasBox) {
      deductions += double.tryParse(accessoriesConfig['box']?.toString() ?? '0.05') ?? 0.0;
    }
    if (!_hasCharger) {
      deductions += double.tryParse(accessoriesConfig['charger']?.toString() ?? '0.05') ?? 0.0;
    }
    if (!_hasBill) {
      deductions += double.tryParse(accessoriesConfig['bill']?.toString() ?? '0.05') ?? 0.0;
    }

    double factor = 1.0 - deductions;
    if (factor < 0.20) factor = 0.20;

    double finalQuote = 0.0;
    if (widget.category == 'laptops') {
      final guaranteedMarkup = double.tryParse(markupsConfig['laptops']?.toString() ?? '2500.0') ?? 2500.0;
      final cashifyBase = basePrice - guaranteedMarkup;
      finalQuote = (cashifyBase * factor) + guaranteedMarkup;
    } else {
      final guaranteedMarkup = double.tryParse(markupsConfig['mobiles']?.toString() ?? '1000.0') ?? 1000.0;
      final cashifyBase = basePrice - guaranteedMarkup;
      finalQuote = (cashifyBase * factor) + guaranteedMarkup;
    }

    return finalQuote.round();
  }

  @override
  Widget build(BuildContext context) {
    final isApple = widget.brand.toLowerCase() == 'apple' || widget.brand.toLowerCase() == 'iphone';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.modelData['name'] ?? 'Diagnostic Wizard', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFF2BB584),
      ),
      body: Column(
        children: [
          _buildStepProgress(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildStepContent(isApple),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepProgress() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStepIndicator(1, 'Specs'),
          _buildStepIndicator(2, 'Condition'),
          _buildStepIndicator(3, 'Defects'),
          _buildStepIndicator(4, 'Accs'),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepNum, String title) {
    final isCurrent = _currentStep == stepNum;
    final isPassed = _currentStep > stepNum;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrent
                ? const Color(0xFF2BB584)
                : isPassed
                    ? const Color(0xFFD1FAE5)
                    : Colors.grey.shade100,
            border: Border.all(
              color: isCurrent ? const Color(0xFF2BB584) : Colors.transparent,
            ),
          ),
          child: Center(
            child: isPassed
                ? const Icon(Icons.check_rounded, size: 16, color: Color(0xFF047857))
                : Text(
                    stepNum.toString(),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: isCurrent
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
            color: isCurrent ? const Color(0xFF0F172A) : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(bool isApple) {
    switch (_currentStep) {
      case 1:
        return _buildStep1Variants();
      case 2:
        return _buildStep2Conditions();
      case 3:
        return _buildStep3Defects(isApple);
      case 4:
        return _buildStep4Accessories();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1Variants() {
    final pricesMap = widget.modelData['prices'] as Map<String, dynamic>? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select RAM / Storage Variant',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 16),
        ...pricesMap.keys.map((variantName) {
          final isSelected = _selectedVariant == variantName;
          return GestureDetector(
            onTap: () => setState(() => _selectedVariant = variantName),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2BB584) : const Color(0xFFE2E8F0),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    variantName,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF2BB584)),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStep2Conditions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Device Age & Condition',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 16),
        
        // Age
        _buildConditionDropdown('Mobile Age:', _selectedAge, {
          'under-3m': 'Under 3 Months',
          '3-6m': '3 to 6 Months old',
          '6-11m': '6 to 11 Months old',
          'above-11m': 'Above 11 Months old',
        }, (val) => setState(() => _selectedAge = val!)),
        
        // Screen
        _buildConditionDropdown('Screen display condition:', _selectedScreen, {
          'flawless': 'Flawless (No Scratches)',
          'scratches': 'Minor Scratches',
          'heavy': 'Heavy Scratches',
          'cracked': 'Cracked Display / lines',
        }, (val) => setState(() => _selectedScreen = val!)),
        
        // Body
        _buildConditionDropdown('Body condition:', _selectedBody, {
          'flawless': 'Mint / Flawless',
          'scratches': 'Minor Scratches / Wear',
          'dents': 'Dents / Paint Chipping',
          'broken': 'Broken Glass / Panel Loose',
        }, (val) => setState(() => _selectedBody = val!)),
      ],
    );
  }

  Widget _buildConditionDropdown(String label, String value, Map<String, String> items, void Function(String?) onChange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF475569))),
          const SizedBox(height: 8),
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
      ),
    );
  }

  Widget _buildStep3Defects(bool isApple) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Functional Defect Checklist',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildDefectCard('frontcam', 'Front Camera', Icons.camera_front_rounded),
            _buildDefectCard('backcam', 'Back Camera', Icons.camera_rounded),
            _buildDefectCard('cameraglass', 'Camera Glass Broken', Icons.broken_image_rounded),
            _buildDefectCard('buttons', 'Buttons Faulty', Icons.volume_up_rounded),
            _buildDefectCard('faceid', 'Face ID Sensor', Icons.face_retouching_natural_rounded),
            _buildDefectCard('touchid', 'Fingerprint ID', Icons.fingerprint_rounded),
            _buildDefectCard('sound', 'Speakers Faulty', Icons.volume_mute_rounded),
            _buildDefectCard('mic', 'Microphone Faulty', Icons.mic_off_rounded),
            _buildDefectCard('network', 'WiFi/Bluetooth', Icons.wifi_lock_rounded),
            _buildDefectCard('chargeport', 'Charging Port', Icons.power_input_rounded),
            _buildDefectCard('vibrator', 'Vibrator Motor', Icons.vibration_rounded),
            _buildDefectCard('proximity', 'Proximity Sensor', Icons.sensor_window_rounded),
          ],
        ),
        const SizedBox(height: 16),
        if (isApple)
          _buildDefectCardRow('appleservice', 'Battery Service Required (Apple)', Icons.battery_alert_rounded),
        if (!isApple)
          _buildDefectCardRow('androidbattery', 'Battery Faulty / Swollen', Icons.battery_charging_full_rounded),
      ],
    );
  }

  Widget _buildDefectCard(String key, String label, IconData icon) {
    final isSelected = _defects[key] == true;
    return GestureDetector(
      onTap: () => setState(() => _defects[key] = !isSelected),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEE2E2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.redAccent : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.redAccent : const Color(0xFF64748B), size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.red.shade900 : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefectCardRow(String key, String label, IconData icon) {
    final isSelected = _defects[key] == true;
    return GestureDetector(
      onTap: () => setState(() => _defects[key] = !isSelected),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEE2E2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.redAccent : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.redAccent : const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.red.shade900 : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4Accessories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Accessories Present',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 16),
        _buildAccessoryRow(_hasBox, 'Original Box', Icons.card_giftcard_rounded, (val) => setState(() => _hasBox = val!)),
        const SizedBox(height: 12),
        _buildAccessoryRow(_hasCharger, 'Original Charger', Icons.bolt_rounded, (val) => setState(() => _hasCharger = val!)),
        const SizedBox(height: 12),
        _buildAccessoryRow(_hasBill, 'Valid Bill', Icons.receipt_long_rounded, (val) => setState(() => _hasBill = val!)),
      ],
    );
  }

  Widget _buildAccessoryRow(bool value, String label, IconData icon, void Function(bool?) onChange) {
    return GestureDetector(
      onTap: () => onChange(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2BB584)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF334155)),
              ),
            ),
            Checkbox(
              value: value,
              activeColor: const Color(0xFF2BB584),
              onChanged: onChange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final finalPrice = _calculateFinalPrice();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Estimated Value:', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
              Text(
                '₹${finalPrice.toFormattedString()}',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF2BB584)),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              if (_currentStep < 4) {
                setState(() => _currentStep++);
              } else {
                // Navigate to booking screen
                final List<String> issues = [];
                _defects.forEach((key, value) {
                  if (value) {
                    if (key == 'frontcam') issues.add('Front Camera Faulty');
                    else if (key == 'backcam') issues.add('Back Camera Faulty');
                    else if (key == 'cameraglass') issues.add('Camera Glass Broken');
                    else if (key == 'buttons') issues.add('Physical Buttons Faulty');
                    else if (key == 'faceid') issues.add('Face ID / Face Sensor Faulty');
                    else if (key == 'touchid') issues.add('Touch ID / Fingerprint Faulty');
                    else if (key == 'sound') issues.add('Speaker / Earpiece Sound Faulty');
                    else if (key == 'mic') issues.add('Microphone Faulty');
                    else if (key == 'network') issues.add('WiFi / Bluetooth Faulty');
                    else if (key == 'chargeport') issues.add('Charging Port Faulty');
                    else if (key == 'vibrator') issues.add('Vibrator Motor Faulty');
                    else if (key == 'proximity') issues.add('Proximity Sensor Faulty');
                    else if (key == 'appleservice') issues.add('Battery Service Required');
                    else if (key == 'androidbattery') issues.add('Battery Faulty / Swollen');
                  }
                });

                final List<String> accs = [];
                if (_hasBox) accs.add('Box');
                if (_hasCharger) accs.add('Charger');
                if (_hasBill) accs.add('Bill');

                final conditionString = 'Age: $_selectedAge, Screen: $_selectedScreen, Body: $_selectedBody, Issues: ${issues.isEmpty ? 'None' : issues.join(', ')}, Accessories: ${accs.isEmpty ? 'None' : accs.join(', ')}';

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingScreen(
                      deviceName: '${widget.brand.toUpperCase()} ${widget.modelData['name']} ($_selectedVariant)',
                      finalQuote: finalPrice,
                      conditionStr: conditionString,
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2BB584),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              _currentStep < 4 ? 'Continue' : 'Book Pickup',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

extension WizardNumberFormatting on int {
  String toFormattedString() {
    final str = toString();
    if (str.length <= 3) return str;
    return str.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
