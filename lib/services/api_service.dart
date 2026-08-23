import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/pricing_config.dart';

class ApiService {
  static Future<Map<String, dynamic>> fetchCatalogAndConfig() async {
    try {
      final response = await http
          .get(Uri.parse("${AppConfig.workerUrl}/agent/trade-in-catalog.js"))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = response.body;

        // 1. Parse Mobiles (window.brandData = {...};)
        Map<String, dynamic> mobileBrands = {};
        final mobileIndex = body.indexOf("window.brandData =");
        if (mobileIndex != -1) {
          final start = mobileIndex + "window.brandData =".length;
          final end = body.indexOf(";", start);
          if (end != -1) {
            final raw = body.substring(start, end).trim();
            mobileBrands = jsonDecode(raw) as Map<String, dynamic>;
          }
        }

        // 2. Parse Laptops (window.laptopBrandData = {...};)
        Map<String, dynamic> laptopBrands = {};
        final laptopIndex = body.indexOf("window.laptopBrandData =");
        if (laptopIndex != -1) {
          final start = laptopIndex + "window.laptopBrandData =".length;
          final end = body.indexOf(";", start);
          if (end != -1) {
            final raw = body.substring(start, end).trim();
            laptopBrands = jsonDecode(raw) as Map<String, dynamic>;
          }
        }

        // 3. Parse Pricing Config (window.rebuysellPricingConfig = {...};)
        PricingConfig config = PricingConfig.defaultConfig();
        final configIndex = body.indexOf("window.rebuysellPricingConfig =");
        if (configIndex != -1) {
          final start = configIndex + "window.rebuysellPricingConfig =".length;
          final end = body.indexOf(";", start);
          if (end != -1) {
            final raw = body.substring(start, end).trim();
            final json = jsonDecode(raw) as Map<String, dynamic>;
            config = PricingConfig.fromJson(json);
          }
        }

        return {
          "catalog": {
            "mobiles": mobileBrands,
            "laptops": laptopBrands,
          },
          "config": config,
        };
      } else {
        throw Exception("Server returned HTTP ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection failed: $e");
    }
  }

  static Future<bool> submitLead(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse("${AppConfig.workerUrl}/api/submit-lead"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
