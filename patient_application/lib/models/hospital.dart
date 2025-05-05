class Hospital {
  final String id;
  final String name;
  final String address;
  final String? phoneNumber;
  final String? imageUrl;
  final String? description;
  final String? operatingHours;
  final bool isActive;

  Hospital({
    required this.id,
    required this.name,
    required this.address,
    this.phoneNumber,
    this.imageUrl,
    this.description,
    this.operatingHours,
    this.isActive = true,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      phoneNumber: json['phone_number'] as String?,
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
      operatingHours: json['operating_hours'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (imageUrl != null) 'image_url': imageUrl,
      if (description != null) 'description': description,
      if (operatingHours != null) 'operating_hours': operatingHours,
      'is_active': isActive,
    };
  }
}
