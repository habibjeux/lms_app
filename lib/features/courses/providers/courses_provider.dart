import 'package:flutter/foundation.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../data/courses_repository.dart';
import '../models/course.dart';

class CoursesProvider with ChangeNotifier {
  final CoursesRepository _repository = CoursesRepository();

  List<Course> _courses = [];
  bool _isLoading = false;
  String? _error;

  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCourses() async {
    _setLoading(true);
    _clearError();

    try {
      _courses = await _repository.getCourses();
      _clearError();
    } on AppException catch (e) {
      _setError(e.toString());
    } catch (e) {
      _setError('Une erreur est survenue lors du chargement des cours');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshCourses() async {
    try {
      final freshCourses = await _repository.getCourses(forceRefresh: true);
      _courses = freshCourses;
      _clearError();
      notifyListeners();
    } on AppException catch (e) {
      _setError(e.toString());
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Méthodes de filtrage
  List<Course> getActiveCourses() {
    return _courses.where((course) => course.active).toList();
  }

  // Recherche de cours
  List<Course> searchCourses(String query) {
    if (query.isEmpty) return _courses;

    return _courses.where((course) {
      return course.title.toLowerCase().contains(query.toLowerCase()) ||
          course.code.toLowerCase().contains(query.toLowerCase()) ||
          course.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}
