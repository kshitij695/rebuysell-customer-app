import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pricing_config.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/category_grid.dart';
import '../widgets/promo_carousel.dart';
import '../widgets/trust_badges.dart';
import 'brand_models_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _catalog = {};
  PricingConfig _pricingConfig = PricingConfig.defaultConfig();
  String _activeCategory = 'mobiles';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final res = await ApiService.fetchCatalogAndConfig();
      setState(() {
        _catalog = res['catalog'] as Map<String, dynamic>? ?? {};
        _pricingConfig = res['config'] as PricingConfig? ?? PricingConfig.defaultConfig();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/logo.jpg',
                width: 22,
                height: 22,
                errorBuilder: (ctx, _, __) => const Icon(Icons.bolt_rounded, color: AppTheme.primaryGreen, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'ReBuySell',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadCatalog,
            tooltip: 'Sync Latest Pricing',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primaryGreen),
                  const SizedBox(height: 16),
                  Text(
                    'Syncing live device valuations...',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _loadCatalog,
                  color: AppTheme.primaryGreen,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      _buildSearchBar(),
                      PromoCarousel(onSellTap: () {
                        setState(() => _activeCategory = 'mobiles');
                      }),
                      const SizedBox(height: 10),
                      CategoryGrid(
                        activeCategory: _activeCategory,
                        onCategorySelected: (cat) => setState(() => _activeCategory = cat),
                      ),
                      const SizedBox(height: 10),
                      _buildTrendingTradeIns(),
                      const SizedBox(height: 10),
                      _buildBrandsSection(),
                      const SizedBox(height: 10),
                      const TrustBadges(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
        decoration: InputDecoration(
          hintText: _activeCategory == 'mobiles'
              ? 'Search your Mobile (e.g. iPhone 15, S24 Ultra)...'
              : 'Search your Laptop (e.g. MacBook M2, Dell G15)...',
          hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGreen),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildTrendingTradeIns() {
    final List<Map<String, dynamic>> trending = [
      {'name': 'iPhone 16 Pro Max', 'price': '84,000', 'tag': 'HOT', 'brand': 'apple', 'cat': 'mobiles'},
      {'name': 'Galaxy S24 Ultra', 'price': '72,500', 'tag': 'TOP', 'brand': 'samsung', 'cat': 'mobiles'},
      {'name': 'MacBook Air M2', 'price': '50,000', 'tag': 'DEAL', 'brand': 'apple', 'cat': 'laptops'},
      {'name': 'OnePlus 12', 'price': '38,000', 'tag': 'POPULAR', 'brand': 'oneplus', 'cat': 'mobiles'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🔥 Hot Buyback Valuations',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMain,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Guaranteed +₹1,000 Extra',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentOrange,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 115,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: trending.length,
            itemBuilder: (context, index) {
              final item = trending[index];
              return GestureDetector(
                onTap: () {
                  _navigateToBrand(item['cat'], item['brand']);
                },
                child: Container(
                  width: 170,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentOrange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item['tag'],
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.accentOrange,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFCBD5E1)),
                        ],
                      ),
                      Text(
                        item['name'],
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Up to ₹${item['price']}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBrandsSection() {
    final categoryMap = _catalog[_activeCategory] as Map<String, dynamic>? ?? {};
    final allBrands = categoryMap.keys.toList();

    final filteredBrands = _searchQuery.isEmpty
        ? allBrands
        : allBrands.where((b) {
            if (b.toLowerCase().contains(_searchQuery)) return true;
            final models = categoryMap[b] as List<dynamic>? ?? [];
            return models.any((m) => (m['name'] ?? '').toString().toLowerCase().contains(_searchQuery));
          }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Brand (${_activeCategory == 'mobiles' ? 'Smartphones' : 'Laptops'})',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMain,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          filteredBrands.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Text(
                    'No brands or models match "$_searchQuery"',
                    style: GoogleFonts.outfit(color: AppTheme.textMuted),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredBrands.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) {
                    final brand = filteredBrands[index];
                    final modelsList = categoryMap[brand] as List<dynamic>? ?? [];
                    final count = modelsList.length;

                    return GestureDetector(
                      onTap: () => _navigateToBrand(_activeCategory, brand),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.cardBorder),
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
                            Text(
                              brand.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: AppTheme.textMain,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$count Models',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreen,
                              ),
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

  void _navigateToBrand(String category, String brand) {
    final categoryMap = _catalog[category] as Map<String, dynamic>? ?? {};
    final models = (categoryMap[brand] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrandModelsScreen(
          category: category,
          brand: brand,
          models: models,
          pricingConfig: _pricingConfig,
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text(
              'Online Connection Required',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'ReBuySell syncs dynamic valuations in real time with our pricing engine. Please check your internet connection and try again.',
              style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadCatalog,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
