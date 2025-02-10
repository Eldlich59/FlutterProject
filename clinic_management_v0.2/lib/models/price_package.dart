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
    return PricePackage(
      id: json['id'],
      name: json['name'],
      chuyenKhoaId: json['chuyen_khoa_id'],
      price: json['price'].toDouble(),
      description: json['description'],
      includedServices: List<String>.from(json['included_services']),
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}
