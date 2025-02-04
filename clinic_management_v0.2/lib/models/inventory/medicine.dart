class Medicine {
  final String id; // Change back to String type
  final String name;
  final String unit;
  final double price;
  final DateTime manufacturingDate;
  final DateTime expiryDate;
  final int stock; // Add new field

  Medicine({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.manufacturingDate,
    required this.expiryDate,
    required this.stock, // Add new field
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: (json['MaThuoc']?.toString() ?? '')
          .trim(), // Handle null and empty strings
      name: (json['TenThuoc'] ?? '').trim(),
      unit: (json['DonVi'] ?? '').trim(),
      price: (json['DonGia'] as num?)?.toDouble() ?? 0.0,
      manufacturingDate:
          DateTime.parse(json['NgaySX'] ?? DateTime.now().toIso8601String()),
      expiryDate:
          DateTime.parse(json['HanSD'] ?? DateTime.now().toIso8601String()),
      stock: json['SoLuongTon'] ?? 0,
    );
  }

  // Thêm constructor mới cho việc tạo medicine mới
  factory Medicine.create({
    required String name,
    required String unit,
    required double price,
    required DateTime manufacturingDate,
    required DateTime expiryDate,
  }) {
    return Medicine(
      id: '', // Empty string for new medicines
      name: name,
      unit: unit,
      price: price,
      manufacturingDate: manufacturingDate,
      expiryDate: expiryDate,
      stock: 0, // Default stock for new medicines
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaThuoc': id,
      'TenThuoc': name,
      'DonVi': unit,
      'DonGia': price,
      'NgaySX': manufacturingDate.toIso8601String(),
      'HanSD': expiryDate.toIso8601String(),
      'SoLuongTon': stock, // Update to match database column name
    };
  }

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  bool get isNearExpiry =>
      !isExpired &&
      expiryDate.isBefore(DateTime.now().add(const Duration(days: 30)));

  bool isValidPrice() => price > 0 && price <= 10000000;

  bool isValidDates() =>
      manufacturingDate.isBefore(expiryDate) &&
      manufacturingDate.isBefore(DateTime.now());
}
