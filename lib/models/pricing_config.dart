class PricingConfig {
  final Map<String, double> ageDeductions;
  final Map<String, double> screenDeductions;
  final Map<String, double> bodyDeductions;
  final Map<String, double> faultPenalties;
  final Map<String, double> accessoryDeductions;
  final Map<String, double> markups;

  PricingConfig({
    required this.ageDeductions,
    required this.screenDeductions,
    required this.bodyDeductions,
    required this.faultPenalties,
    required this.accessoryDeductions,
    required this.markups,
  });

  factory PricingConfig.fromJson(Map<String, dynamic> json) {
    Map<String, double> toDoubleMap(dynamic map) {
      if (map is! Map) return {};
      return map.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    }

    final deductions = json['deductions'] as Map<String, dynamic>? ?? {};

    return PricingConfig(
      ageDeductions: toDoubleMap(deductions['age']),
      screenDeductions: toDoubleMap(deductions['screen']),
      bodyDeductions: toDoubleMap(deductions['body']),
      faultPenalties: toDoubleMap(deductions['faults']),
      accessoryDeductions: toDoubleMap(deductions['accessories']),
      markups: toDoubleMap(json['markups']),
    );
  }

  factory PricingConfig.defaultConfig() {
    return PricingConfig(
      ageDeductions: {'under-3m': 0.0, '3-6m': 0.05, '6-11m': 0.10, 'above-11m': 0.15},
      screenDeductions: {'flawless': 0.0, 'scratches': 0.10, 'heavy': 0.20, 'cracked': 0.45},
      bodyDeductions: {'flawless': 0.0, 'scratches': 0.05, 'dents': 0.20, 'broken': 0.35},
      faultPenalties: {
        'frontcam': 0.05, 'backcam': 0.10, 'cameraglass': 0.03, 'buttons': 0.05,
        'faceid': 0.10, 'touchid': 0.08, 'sound': 0.05, 'mic': 0.05,
        'network': 0.08, 'chargeport': 0.05, 'vibrator': 0.02, 'proximity': 0.03,
        'appleservice': 0.10, 'androidbattery': 0.10
      },
      accessoryDeductions: {'box': 0.05, 'charger': 0.05, 'bill': 0.05},
      markups: {'mobiles': 1000.0, 'laptops': 2500.0},
    );
  }
}
