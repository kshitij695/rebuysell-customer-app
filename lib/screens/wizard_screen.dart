import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pricing_config.dart';
import '../models/quote_booking.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'booking_screen.dart';

class WizardScreen extends StatefulWidget {
  final String category;
  final String brand;
  final Map<String, dynamic> modelData;
  final PricingConfig pricingConfig;

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
  int _currentStep = 0;
  
  // Selections
  String _selectedVariant = '';
  int _basePrice = 0;
  String _deviceAge = 'under-3m';
  String _screenCondition = 'flawless';
  String _bodyCondition = 'flawless';
  final Set<String> _selectedFaults = {};
  
  // NOTE: Original Accessories start UNSELECTED by default as required!
  final Set<String> _selectedAccessories = {};

  final List<String> _steps = ['Specs', 'Age', 'Screen', 'Body', 'Faults', 'Accessories'];

  @override
  void initState() {
    super.initState();
    _initVariants();
  }

  void _initVariants() {
    if (widget.modelData.containsKey('prices') && widget.modelData['prices'] is Map) {
      final prices = widget.modelData['prices'] as Map<String, dynamic>;
      if (prices.isNotEmpty) {
        _selectedVariant = prices.keys.first;
        _basePrice = (prices[_selectedVariant] as num).toInt();
      }
    } else if (widget.modelData.containsKey('basePrices') && widget.modelData['basePrices'] is Map) {
      final prices = widget.modelData['basePrices'] as Map<String, dynamic>;
      if (prices.isNotEmpty) {
        _selectedVariant = prices.keys.first;
        _basePrice = (prices[_selectedVariant] as num).toInt();
      }
    } else if (widget.modelData.containsKey('models') && widget.modelData['models'] is List) {
      final list = widget.modelData['models'] as List<dynamic>;
      if (list.isNotEmpty) {
        _selectedVariant = list.first['name'] ?? '';
        _basePrice = (list.first['basePrice'] as num? ?? 0).toInt();
      }
    }
  }

  int _calculateFinalPrice() {
    if (_basePrice <= 0) return 0;
    double price = _basePrice.toDouble();

    // 1. Age deduction
    final ageRate = widget.pricingConfig.ageDeductions[_deviceAge] ?? 0.0;
    price -= (_basePrice * ageRate);

    // 2. Screen condition
    final screenRate = widget.pricingConfig.screenDeductions[_screenCondition] ?? 0.0;
    price -= (_basePrice * screenRate);

    // 3. Body condition
    final bodyRate = widget.pricingConfig.bodyDeductions[_bodyCondition] ?? 0.0;
    price -= (_basePrice * bodyRate);

    // 4. Functional faults
    for (var f in _selectedFaults) {
      final rate = widget.pricingConfig.faultPenalties[f] ?? 0.05;
      price -= (_basePrice * rate);
    }

    // 5. Missing Accessories deductions (Deduct if NOT present in _selectedAccessories)
    if (!_selectedAccessories.contains('box')) {
      final boxRate = widget.pricingConfig.accessoryDeductions['box'] ?? 0.05;
      price -= (_basePrice * boxRate);
    }
    if (!_selectedAccessories.contains('charger')) {
      final chargerRate = widget.pricingConfig.accessoryDeductions['charger'] ?? 0.05;
      price -= (_basePrice * chargerRate);
    }
    if (!_selectedAccessories.contains('bill')) {
      final billRate = widget.pricingConfig.accessoryDeductions['bill'] ?? 0.05;
      price -= (_basePrice * billRate);
    }

    // Ensure floor price
    final floor = _basePrice * 0.15;
    if (price < floor) price = floor;

    return price.round();
  }

  @override
  Widget build(BuildContext context) {
    final finalPrice = _calculateFinalPrice();
    final modelName = widget.modelData['name'] ?? 'Device';

    return Scaffold(
      appBar: AppBar(
        title: Text(modelName),
      ),
      body: Column(
        children: [
          _buildProgressHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildCurrentStepContent(),
            ),
          ),
          _buildBottomValuationBar(finalPrice, modelName),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(_steps.length, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isCompleted || isCurrent ? AppTheme.primaryGreen : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildVariantSelection();
      case 1:
        return _buildAgeSelection();
      case 2:
        return _buildScreenCondition();
      case 3:
        return _buildBodyCondition();
      case 4:
        return _buildFaultsSelection();
      case 5:
        return _buildAccessoriesSelection();
      default:
        return Container();
    }
  }

  Widget _buildVariantSelection() {
    List<Map<String, dynamic>> variants = [];
    if (widget.modelData.containsKey('prices') && widget.modelData['prices'] is Map) {
      final prices = widget.modelData['prices'] as Map<String, dynamic>;
      prices.forEach((k, v) => variants.add({'name': k, 'price': v}));
    } else if (widget.modelData.containsKey('basePrices') && widget.modelData['basePrices'] is Map) {
      final prices = widget.modelData['basePrices'] as Map<String, dynamic>;
      prices.forEach((k, v) => variants.add({'name': k, 'price': v}));
    } else if (widget.modelData.containsKey('models') && widget.modelData['models'] is List) {
      final list = widget.modelData['models'] as List<dynamic>;
      for (var item in list) {
        variants.add({'name': item['name'], 'price': item['basePrice']});
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Storage / RAM Configuration', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 6),
        Text('Choose the exact variant of your device', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13)),
        const SizedBox(height: 16),
        ...variants.map((v) {
          final isSelected = _selectedVariant == v['name'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedVariant = v['name'];
                _basePrice = (v['price'] as num).toInt();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder, width: isSelected ? 2 : 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(v['name'], style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text('₹${v['price']}', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppTheme.primaryGreen, fontSize: 16)),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAgeSelection() {
    final ages = [
      {'id': 'under-3m', 'title': 'Below 3 Months', 'sub': 'With valid invoice & warranty'},
      {'id': '3-6m', 'title': '3 - 6 Months', 'sub': 'Under brand warranty'},
      {'id': '6-11m', 'title': '6 - 11 Months', 'sub': 'Near warranty expiry'},
      {'id': 'above-11m', 'title': 'Above 11 Months', 'sub': 'Out of manufacturer warranty'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How old is your device?', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 6),
        Text('Warranty status affects your buyback value', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13)),
        const SizedBox(height: 16),
        ...ages.map((a) {
          final isSelected = _deviceAge == a['id'];
          return GestureDetector(
            onTap: () => setState(() => _deviceAge = a['id']!),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder, width: isSelected ? 2 : 1),
              ),
              child: Row(
                children: [
                  Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: isSelected ? AppTheme.primaryGreen : const Color(0xFF94A3B8)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['title']!, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(a['sub']!, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildScreenCondition() {
    final conditions = [
      {'id': 'flawless', 'title': 'Flawless (No Scratches)', 'sub': 'Zero visible marks on the display glass'},
      {'id': 'scratches', 'title': 'Minor Scratches', 'sub': '1-2 light scratches seen under bright light'},
      {'id': 'heavy', 'title': 'Heavy Scratches / Lines', 'sub': 'Deep scratches or minor display shading'},
      {'id': 'cracked', 'title': 'Cracked / Broken Glass', 'sub': 'Glass broken but touch & display still working'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Screen / Display Condition', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 6),
        Text('Check your display carefully in good lighting', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13)),
        const SizedBox(height: 16),
        ...conditions.map((c) {
          final isSelected = _screenCondition == c['id'];
          return GestureDetector(
            onTap: () => setState(() => _screenCondition = c['id']!),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder, width: isSelected ? 2 : 1),
              ),
              child: Row(
                children: [
                  Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: isSelected ? AppTheme.primaryGreen : const Color(0xFF94A3B8)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['title']!, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(c['sub']!, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildBodyCondition() {
    final conditions = [
      {'id': 'flawless', 'title': 'Flawless Body', 'sub': 'Like new, no dents or paint peeling'},
      {'id': 'scratches', 'title': 'Minor Scratches', 'sub': 'Normal daily usage wear and hairline marks'},
      {'id': 'dents', 'title': 'Dents / Edge Bends', 'sub': 'Visible drops or chipped corners'},
      {'id': 'broken', 'title': 'Cracked Back / Frame', 'sub': 'Back glass cracked or frame bent'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Body / Frame Physical Condition', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 6),
        Text('Inspect the sides, back panel, and edges', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13)),
        const SizedBox(height: 16),
        ...conditions.map((c) {
          final isSelected = _bodyCondition == c['id'];
          return GestureDetector(
            onTap: () => setState(() => _bodyCondition = c['id']!),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder, width: isSelected ? 2 : 1),
              ),
              child: Row(
                children: [
                  Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: isSelected ? AppTheme.primaryGreen : const Color(0xFF94A3B8)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['title']!, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(c['sub']!, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFaultsSelection() {
    final faults = [
      {'id': 'frontcam', 'title': 'Front Camera Issue'},
      {'id': 'backcam', 'title': 'Rear / Main Camera Fault'},
      {'id': 'buttons', 'title': 'Volume / Power Buttons Defective'},
      {'id': 'faceid', 'title': 'Face ID / Fingerprint Not Working'},
      {'id': 'sound', 'title': 'Speaker / Earpiece Fault'},
      {'id': 'mic', 'title': 'Microphone Not Working'},
      {'id': 'network', 'title': 'WiFi / Cellular Fault'},
      {'id': 'chargeport', 'title': 'Charging Port Defective'},
      {'id': 'androidbattery', 'title': 'Battery Service Required (< 80% Health)'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Functional Issues (If Any)', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 6),
        Text('Select only if specific features are not functioning', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13)),
        const SizedBox(height: 16),
        ...faults.map((f) {
          final isSelected = _selectedFaults.contains(f['id']);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedFaults.remove(f['id']);
                } else {
                  _selectedFaults.add(f['id']!);
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFEF2F2) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? const Color(0xFFEF4444) : AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: isSelected ? const Color(0xFFEF4444) : const Color(0xFF94A3B8)),
                  const SizedBox(width: 12),
                  Text(f['title']!, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAccessoriesSelection() {
    final accessories = [
      {'id': 'box', 'title': 'Original Box (with matching IMEI)', 'icon': Icons.inventory_2_rounded},
      {'id': 'charger', 'title': 'Original Fast Charger & Cable', 'icon': Icons.electrical_services_rounded},
      {'id': 'bill', 'title': 'Valid Original Purchase Invoice / Bill', 'icon': Icons.receipt_long_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Original Accessories You Have', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 6),
        Text('Select only the accessories you will hand over during doorstep pickup', style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13)),
        const SizedBox(height: 16),
        ...accessories.map((a) {
          final isSelected = _selectedAccessories.contains(a['id']);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedAccessories.remove(a['id']);
                } else {
                  _selectedAccessories.add(a['id'] as String);
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder, width: isSelected ? 2 : 1),
              ),
              child: Row(
                children: [
                  Icon(isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: isSelected ? AppTheme.primaryGreen : const Color(0xFF94A3B8)),
                  const SizedBox(width: 12),
                  Icon(a['icon'] as IconData, size: 22, color: isSelected ? AppTheme.primaryGreen : AppTheme.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(a['title'] as String, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildBottomValuationBar(int finalPrice, String modelName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Estimated Valuation', style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted)),
                  Text(
                    '₹$finalPrice',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            if (_currentStep > 0)
              TextButton(
                onPressed: () => setState(() => _currentStep--),
                child: Text('Back', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
              ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                if (_currentStep < _steps.length - 1) {
                  setState(() => _currentStep++);
                } else {
                  // Final step: Save quote locally and proceed to booking
                  final quote = SavedQuote(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    deviceName: modelName,
                    brand: widget.brand,
                    category: widget.category,
                    variant: _selectedVariant,
                    finalPrice: finalPrice,
                    createdAt: DateTime.now(),
                    breakdown: {
                      'basePrice': _basePrice,
                      'age': _deviceAge,
                      'screen': _screenCondition,
                      'body': _bodyCondition,
                      'faults': _selectedFaults.toList(),
                      'accessories': _selectedAccessories.toList(),
                    },
                  );
                  await StorageService.saveQuote(quote);

                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(
                        savedQuote: quote,
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _currentStep == _steps.length - 1 ? 'Book Pickup' : 'Continue',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
