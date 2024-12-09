// ignore: file_names
import 'school.dart';
import 'student.dart';

// ignore: constant_identifier_names
enum UserRole { SUPER_ADMIN, MANAGER, TEACHER, STUDENT }

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? password;
  final UserRole role;
  final bool active;
  final String? schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  final School? school;
  final Student? student;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.role,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.schoolId,
    this.deletedAt,
    this.school,
    this.student,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      password: json['password'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
      ),
      active: json['active'],
      schoolId: json['schoolId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'role': role.toString().split('.').last,
        'active': active,
        'schoolId': schoolId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };
}
