import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'wizard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _catalog = {};
  Map<String, dynamic> _config = {};
  String _selectedCategory = 'mobiles';
  String _selectedBrand = '';
  String _searchQuery = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final res = await ApiService.fetchCatalogAndConfig();
      setState(() {
        _catalog = res['catalog'] ?? {};
        _config = res['config'] ?? {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load pricing catalog: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ReBuySell',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2BB584),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2BB584)))
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: GoogleFonts.outfit(color: Colors.red)))
              : Column(
                  children: [
                    _buildCategorySelector(),
                    _buildSearchAndBrandGrid(),
                  ],
                ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      color: const Color(0xFF2BB584),
      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildCategoryButton('mobiles', Icons.phone_android_rounded, 'Mobiles'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCategoryButton('laptops', Icons.laptop_chromebook_rounded, 'Laptops'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String category, IconData icon, String label) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _selectedBrand = '';
          _searchQuery = '';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF2BB584) : Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                color: isSelected ? const Color(0xFF2BB584) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndBrandGrid() {
    // Brands list for category
    final brandsMap = _catalog[_selectedCategory] as Map<String, dynamic>? ?? {};
    final brands = brandsMap.keys.toList();

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase().trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search brand or model name...',
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
          if (_selectedBrand.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Select Brand',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF0F172A)),
              ),
            ),
            Expanded(child: _buildBrandGrid(brands)),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedBrand = ''),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF2BB584)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedBrand.toUpperCase()} Models',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildModelList(brandsMap[_selectedBrand] as List<dynamic>? ?? [])),
          ],
        ],
      ),
    );
  }

  Widget _buildBrandGrid(List<String> brands) {
    final filteredBrands = brands.where((b) => b.toLowerCase().contains(_searchQuery)).toList();
    if (filteredBrands.isEmpty) {
      return Center(child: Text("No brands match your search.", style: GoogleFonts.outfit(color: const Color(0xFF64748B))));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: filteredBrands.length,
      itemBuilder: (context, idx) {
        final bName = filteredBrands[idx];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedBrand = bName;
              _searchQuery = '';
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Center(
              child: Text(
                bName.toUpperCase(),
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: const Color(0xFF334155)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModelList(List<dynamic> models) {
    final filteredModels = models.where((m) {
      final name = (m['name'] as String? ?? '').toLowerCase();
      return name.contains(_searchQuery);
    }).toList();

    if (filteredModels.isEmpty) {
      return Center(child: Text("No models match your search.", style: GoogleFonts.outfit(color: const Color(0xFF64748B))));
    }

    return ListView.separated(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      itemCount: filteredModels.length,
      separatorBuilder: (c, i) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final m = filteredModels[idx] as Map<String, dynamic>;
        final mName = m['name'] as String? ?? 'Unknown Model';
        final series = m['series'] as String? ?? '';
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WizardScreen(
                  category: _selectedCategory,
                  brand: _selectedBrand,
                  modelData: m,
                  pricingConfig: _config,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mName,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF0F172A)),
                    ),
                    if (series.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        series,
                        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        );
      },
    );
  }
}
