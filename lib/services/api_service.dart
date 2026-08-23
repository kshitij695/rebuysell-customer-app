import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  static Future<Map<String, dynamic>> fetchCatalogAndConfig() async {
    final response = await http.get(Uri.parse("${AppConfig.workerUrl}/agent/trade-in-catalog.js"));
    if (response.statusCode == 200) {
      final body = response.body;
      
      // Parse brandData
      String brandDataStr = "";
      final brandDataIndex = body.indexOf("window.brandData =");
      if (brandDataIndex != -1) {
        final start = brandDataIndex + "window.brandData =".length;
        final end = body.indexOf(";", start);
        if (end != -1) {
          brandDataStr = body.substring(start, end).trim();
        }
      }
      
      // Parse pricingConfig
      String pricingConfigStr = "";
      final pricingConfigIndex = body.indexOf("window.rebuysellPricingConfig =");
      if (pricingConfigIndex != -1) {
        final start = pricingConfigIndex + "window.rebuysellPricingConfig =".length;
        final end = body.indexOf(";", start);
        if (end != -1) {
          pricingConfigStr = body.substring(start, end).trim();
        }
      }
      
      // Fallback merge for laptopBrandData
      Map<String, dynamic> catalogMap = brandDataStr.isNotEmpty ? jsonDecode(brandDataStr) : {};
      final laptopIndex = body.indexOf("window.laptopBrandData =");
      if (laptopIndex != -1) {
        final start = laptopIndex + "window.laptopBrandData =".length;
        final end = body.indexOf(";", start);
        if (end != -1) {
          final laptops = jsonDecode(body.substring(start, end).trim()) as Map<String, dynamic>;
          laptops.forEach((key, value) {
            catalogMap[key] = value;
          });
        }
      }
      
      return {
        "catalog": catalogMap,
        "config": pricingConfigStr.isNotEmpty ? jsonDecode(pricingConfigStr) : {},
      };
    } else {
      throw Exception("Failed to load catalog from server");
    }
  }

  static Future<bool> submitLead(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse("${AppConfig.workerUrl}/api/submit-lead"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      return resData['success'] == true;
    }
    return false;
  }
}
