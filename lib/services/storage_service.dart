import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quote_booking.dart';

class CustomerProfile {
  final String phone;
  final String firstName;
  final String lastName;
  final String email;
  final String address;
  final String upi;

  CustomerProfile({
    required this.phone,
    required this.firstName,
    required this.lastName,
    this.email = '',
    this.address = '',
    this.upi = '',
  });

  String get fullName => '$firstName $lastName'.trim();

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'address': address,
    'upi': upi,
  };

  factory CustomerProfile.fromJson(Map<String, dynamic> json) => CustomerProfile(
    phone: json['phone'] ?? '',
    firstName: json['firstName'] ?? '',
    lastName: json['lastName'] ?? '',
    email: json['email'] ?? '',
    address: json['address'] ?? '',
    upi: json['upi'] ?? '',
  );
}

class StorageService {
  static const String _quotesKey = 'rebuysell_saved_quotes';
  static const String _bookingsKey = 'rebuysell_user_bookings';
  static const String _profileKey = 'rebuysell_customer_profile';
  static const String _verifiedKey = 'rebuysell_phone_verified';

  static Future<bool> isPhoneVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_verifiedKey) ?? false;
  }

  static Future<void> setPhoneVerified(bool verified) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_verifiedKey, verified);
  }

  static Future<CustomerProfile?> getCustomerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return CustomerProfile.fromJson(jsonDecode(raw));
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveCustomerProfile(CustomerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    await prefs.setBool(_verifiedKey, true);
  }

  static Future<List<SavedQuote>> getSavedQuotes() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_quotesKey) ?? [];
    return list.map((item) => SavedQuote.fromJson(jsonDecode(item))).toList();
  }

  static Future<void> saveQuote(SavedQuote quote) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_quotesKey) ?? [];
    list.insert(0, jsonEncode(quote.toJson()));
    if (list.length > 20) list.removeLast();
    await prefs.setStringList(_quotesKey, list);
  }

  static Future<List<BookingRecord>> getBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_bookingsKey) ?? [];
    return list.map((item) => BookingRecord.fromJson(jsonDecode(item))).toList();
  }

  static Future<void> saveBooking(BookingRecord booking) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_bookingsKey) ?? [];
    list.insert(0, jsonEncode(booking.toJson()));
    await prefs.setStringList(_bookingsKey, list);
  }
}
