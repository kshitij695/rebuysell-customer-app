import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pricing_config.dart';
import '../theme/app_theme.dart';
import 'wizard_screen.dart';

class BrandModelsScreen extends StatefulWidget {
  final String category;
  final String brand;
  final List<Map<String, dynamic>> models;
  final PricingConfig pricingConfig;

  const BrandModelsScreen({
    Key? key,
    required this.category,
    required this.brand,
    required this.models,
    required this.pricingConfig,
  }) : super(key: key);

  @override
  State<BrandModelsScreen> createState() => _BrandModelsScreenState();
}

class _BrandModelsScreenState extends State<BrandModelsScreen> {
  String _searchQuery = '';
  String _selectedSeries = 'All';

  @override
  Widget build(BuildContext context) {
    // Extract unique series
    final seriesSet = {'All'};
    for (var m in widget.models) {
      if (m.containsKey('series') && m['series'] != null) {
        seriesSet.add(m['series'].toString());
      }
    }
    final seriesList = seriesSet.toList();

    // Filter models
    final filtered = widget.models.where((m) {
      final name = (m['name'] ?? '').toString().toLowerCase();
      final series = (m['series'] ?? '').toString();
      final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery);
      final matchesSeries = _selectedSeries == 'All' || series == _selectedSeries;
      return matchesSearch && matchesSeries;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.brand.toUpperCase()} Devices'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
              decoration: InputDecoration(
                hintText: 'Search ${widget.brand.toUpperCase()} model...',
                hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGreen),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.cardBorder),
                ),
              ),
            ),
          ),
          if (seriesList.length > 2)
            Container(
              height: 44,
              color: Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: seriesList.length,
                itemBuilder: (context, index) {
                  final s = seriesList[index];
                  final isSelected = _selectedSeries == s;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSeries = s),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryGreen : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        s,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.textMain,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const Divider(height: 1, color: AppTheme.cardBorder),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No models found matching criteria',
                      style: GoogleFonts.outfit(color: AppTheme.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final model = filtered[index];
                      final name = model['name'] ?? 'Unknown';
                      final series = model['series'] ?? '';
                      
                      // Compute max price from prices map
                      int maxPrice = 0;
                      if (model.containsKey('prices') && model['prices'] is Map) {
                        final prices = model['prices'] as Map<String, dynamic>;
                        for (var p in prices.values) {
                          if (p is num && p > maxPrice) maxPrice = p.toInt();
                        }
                      } else if (model.containsKey('basePrices') && model['basePrices'] is Map) {
                        final prices = model['basePrices'] as Map<String, dynamic>;
                        for (var p in prices.values) {
                          if (p is num && p > maxPrice) maxPrice = p.toInt();
                        }
                      } else if (model.containsKey('models') && model['models'] is List) {
                        final sub = model['models'] as List<dynamic>;
                        for (var item in sub) {
                          final bp = item['basePrice'];
                          if (bp is num && bp > maxPrice) maxPrice = bp.toInt();
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          title: Text(
                            name,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          subtitle: series.isNotEmpty
                              ? Text(series, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted))
                              : null,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (maxPrice > 0)
                                Text(
                                  'Get up to',
                                  style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textMuted),
                                ),
                              if (maxPrice > 0)
                                Text(
                                  '₹$maxPrice',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WizardScreen(
                                  category: widget.category,
                                  brand: widget.brand,
                                  modelData: model,
                                  pricingConfig: widget.pricingConfig,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
