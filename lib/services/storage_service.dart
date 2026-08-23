import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quote_booking.dart';

class StorageService {
  static const String _quotesKey = 'rebuysell_saved_quotes';
  static const String _bookingsKey = 'rebuysell_user_bookings';

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
