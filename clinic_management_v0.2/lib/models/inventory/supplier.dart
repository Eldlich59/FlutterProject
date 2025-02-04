class Supplier {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;

  Supplier({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['MaNCC'],
      name: json['TenNCC'],
      address: json['DiaChi'],
      phone: json['SDT'],
      email: json['Email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MaNCC': id,
      'TenNCC': name,
      'DiaChi': address,
      'SDT': phone,
      'Email': email,
    };
  }
}
