class Medicine {
  final String id;
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'price': price,
        'manufacturingDate': manufacturingDate.toIso8601String(),
        'expiryDate': expiryDate.toIso8601String(),
      };

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
        id: json['id'],
        name: json['name'],
        unit: json['unit'],
        price: json['price'],
        manufacturingDate: DateTime.parse(json['manufacturingDate']),
        expiryDate: DateTime.parse(json['expiryDate']),
      );

  Medicine copyWith({
    String? id,
    String? name,
    String? unit,
    double? price,
    DateTime? manufacturingDate,
    DateTime? expiryDate,
  }) =>
      Medicine(
        id: id ?? this.id,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        price: price ?? this.price,
        manufacturingDate: manufacturingDate ?? this.manufacturingDate,
        expiryDate: expiryDate ?? this.expiryDate,
      );

  @override
  String toString() =>
      'Medicine{id: $id, name: $name, unit: $unit, price: $price, manufacturingDate: $manufacturingDate, expiryDate: $expiryDate}';
}
