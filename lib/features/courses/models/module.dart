import '../../quizzes/models/quiz.dart';
import 'chapter.dart';
import 'course.dart';
import 'resource.dart';
import 'semester.dart';
import 'teaching.dart';

class Module {
  final String id;
  final String code;
  final String title;
  final int coefficient;
  final int credits;
  final String description;
  final String courseId;
  final String semesterId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  final Course? course;
  final Semester? semester;
  final List<Chapter>? chapters;
  final List<Teaching>? teachings;
  final List<Quiz>? quizzes;
  final List<Resource>? resources;

  const Module({
    required this.id,
    required this.code,
    required this.title,
    required this.coefficient,
    required this.credits,
    required this.description,
    required this.courseId,
    required this.semesterId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.course,
    this.semester,
    this.chapters,
    this.teachings,
    this.quizzes,
    this.resources,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'],
      code: json['code'],
      title: json['title'],
      coefficient: json['coefficient'],
      credits: json['credits'],
      description: json['description'],
      courseId: json['courseId'],
      semesterId: json['semesterId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      deletedAt:
          json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'coefficient': coefficient,
        'credits': credits,
        'description': description,
        'courseId': courseId,
        'semesterId': semesterId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };
}
