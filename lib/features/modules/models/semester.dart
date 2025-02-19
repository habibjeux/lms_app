import 'module.dart';

class Semester {
  final String id;
  final String code;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Module>? modules;

  const Semester({
    required this.id,
    required this.code,
    required this.createdAt,
    required this.updatedAt,
    this.modules,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: json['id'],
      code: json['code'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
