class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String? avatarUrl;
  final String? bio;
  final String? email;
  final String? phone;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    this.avatarUrl,
    this.bio,
    this.email,
    this.phone,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      name: json['name'],
      specialty: json['specialty'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      email: json['email'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'avatar_url': avatarUrl,
      'bio': bio,
      'email': email,
      'phone': phone,
    };
  }
}
