import 'course.dart';
import 'level.dart';
import 'module.dart';

class CourseLevel {
  final String id;
  final String courseId;
  final String levelId;

  final Course? course;
  final Level? level;
  final List<Module>? modules;

  const CourseLevel({
    required this.id,
    required this.courseId,
    required this.levelId,
    this.course,
    this.level,
    this.modules,
  });

  factory CourseLevel.fromJson(Map<String, dynamic> json) {
    return CourseLevel(
      id: json['id'],
      courseId: json['courseId'],
      levelId: json['levelId'],
    );
  }
}
