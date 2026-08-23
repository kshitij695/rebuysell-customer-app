import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CategoryGrid extends StatelessWidget {
  final String activeCategory;
  final Function(String) onCategorySelected;

  const CategoryGrid({
    Key? key,
    required this.activeCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  final List<Map<String, dynamic>> _categories = const [
    {'id': 'mobiles', 'name': 'Sell Phone', 'icon': Icons.phone_iphone_rounded, 'available': true},
    {'id': 'laptops', 'name': 'Sell Laptop', 'icon': Icons.laptop_mac_rounded, 'available': true},
    {'id': 'tablets', 'name': 'Sell Tablet', 'icon': Icons.tablet_mac_rounded, 'available': false},
    {'id': 'watches', 'name': 'Smartwatch', 'icon': Icons.watch_rounded, 'available': false},
    {'id': 'earbuds', 'name': 'Sell Earbuds', 'icon': Icons.headphones_rounded, 'available': false},
    {'id': 'gaming', 'name': 'Consoles', 'icon': Icons.sports_esports_rounded, 'available': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sell For Cash',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMain,
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Instant Doorstep Payout',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = activeCategory == cat['id'];
              final isAvailable = cat['available'] as bool;

              return GestureDetector(
                onTap: () {
                  if (isAvailable) {
                    onCategorySelected(cat['id']);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${cat['name']} buyback is launching soon in your city!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryGreen.withOpacity(0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              cat['icon'] as IconData,
                              size: 22,
                              color: isSelected ? Colors.white : AppTheme.textMain,
                            ),
                          ),
                          if (!isAvailable)
                            Positioned(
                              top: -4,
                              right: -10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF94A3B8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'SOON',
                                  style: GoogleFonts.outfit(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat['name'],
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? AppTheme.primaryGreen : AppTheme.textMain,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
