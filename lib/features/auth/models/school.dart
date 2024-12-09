import '../../courses/models/course.dart';
import 'user.dart';

class School {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  final List<Course>? courses;
  final List<User>? users;

  const School({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.courses,
    this.users,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      active: json['active'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
        'email': email,
        'active': active,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };
}
