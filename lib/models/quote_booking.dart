class SavedQuote {
  final String id;
  final String deviceName;
  final String brand;
  final String category;
  final String variant;
  final int finalPrice;
  final DateTime createdAt;
  final Map<String, dynamic> breakdown;

  SavedQuote({
    required this.id,
    required this.deviceName,
    required this.brand,
    required this.category,
    required this.variant,
    required this.finalPrice,
    required this.createdAt,
    required this.breakdown,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceName': deviceName,
    'brand': brand,
    'category': category,
    'variant': variant,
    'finalPrice': finalPrice,
    'createdAt': createdAt.toIso8601String(),
    'breakdown': breakdown,
  };

  factory SavedQuote.fromJson(Map<String, dynamic> json) => SavedQuote(
    id: json['id'] ?? '',
    deviceName: json['deviceName'] ?? '',
    brand: json['brand'] ?? '',
    category: json['category'] ?? 'mobiles',
    variant: json['variant'] ?? '',
    finalPrice: json['finalPrice'] ?? 0,
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    breakdown: json['breakdown'] ?? {},
  );
}

class BookingRecord {
  final String bookingId;
  final String deviceName;
  final int quotePrice;
  final String customerName;
  final String phone;
  final String address;
  final String slotDate;
  final String slotTime;
  final String paymentMode;
  final String paymentDetail;
  final String status;
  final DateTime timestamp;

  BookingRecord({
    required this.bookingId,
    required this.deviceName,
    required this.quotePrice,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.slotDate,
    required this.slotTime,
    required this.paymentMode,
    required this.paymentDetail,
    this.status = 'Scheduled',
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'bookingId': bookingId,
    'deviceName': deviceName,
    'quotePrice': quotePrice,
    'customerName': customerName,
    'phone': phone,
    'address': address,
    'slotDate': slotDate,
    'slotTime': slotTime,
    'paymentMode': paymentMode,
    'paymentDetail': paymentDetail,
    'status': status,
    'timestamp': timestamp.toIso8601String(),
  };

  factory BookingRecord.fromJson(Map<String, dynamic> json) => BookingRecord(
    bookingId: json['bookingId'] ?? '',
    deviceName: json['deviceName'] ?? '',
    quotePrice: json['quotePrice'] ?? 0,
    customerName: json['customerName'] ?? '',
    phone: json['phone'] ?? '',
    address: json['address'] ?? '',
    slotDate: json['slotDate'] ?? '',
    slotTime: json['slotTime'] ?? '',
    paymentMode: json['paymentMode'] ?? 'UPI',
    paymentDetail: json['paymentDetail'] ?? '',
    status: json['status'] ?? 'Scheduled',
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
  );
}
