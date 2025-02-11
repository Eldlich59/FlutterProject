class PricePackage {
  final String id;
  final String name;
  final String chuyenKhoaId;
  final double price;
  final String description;
  final List<String> includedServices;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PricePackage({
    required this.id,
    required this.name,
    required this.chuyenKhoaId,
    required this.price,
    required this.description,
    required this.includedServices,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'chuyen_khoa_id': chuyenKhoaId,
        'price': price,
        'description': description,
        'included_services': includedServices,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory PricePackage.fromJson(Map<String, dynamic> json) {
    try {
      return PricePackage(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        chuyenKhoaId: json['chuyen_khoa_id']?.toString() ?? '',
        price: (json['price'] ?? 0).toDouble(),
        description: json['description']?.toString() ?? '',
        includedServices: List<String>.from(json['included_services'] ?? []),
        isActive: json['is_active'] ?? true,
        createdAt:
            DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'])
            : null,
      );
    } catch (e) {
      print('Error parsing price package: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}
