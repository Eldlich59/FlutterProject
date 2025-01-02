class Medicine {
  final int id; // Thay đổi từ String sang int
  final String name;
  final String unit;
  final double price;
  final DateTime manufacturingDate;
  final DateTime expiryDate;

  Medicine({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.manufacturingDate,
    required this.expiryDate,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['MaThuoc'] ?? 0, // Đổi giá trị mặc định từ '' sang 0
      name: json['TenThuoc'] ?? '',
      unit: json['DonVi'] ?? '',
      price: (json['DonGia'] as num).toDouble(),
      manufacturingDate: DateTime.parse(json['NgaySX']),
      expiryDate: DateTime.parse(json['HanSD']),
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
      id: 0, // Đổi giá trị mặc định từ '' sang 0
      name: name,
      unit: unit,
      price: price,
      manufacturingDate: manufacturingDate,
      expiryDate: expiryDate,
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
