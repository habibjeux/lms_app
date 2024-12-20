import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/exceptions/app_exception.dart';
import '../models/course.dart';
import '../models/module.dart';

class CoursesRepository {
  final Dio _dio = ApiClient.instance;
  final StorageService _storage = StorageService();
  final String _coursesStorageKey = 'student_courses';

  Future<List<Course>> getCourses({bool forceRefresh = false}) async {
    try {
      // Si pas de forceRefresh, essayer d'abord le cache
      if (!forceRefresh) {
        final cachedCourses = await _getCachedCourses();
        if (cachedCourses.isNotEmpty) {
          return cachedCourses;
        }
      }

      final response = await _dio.get('/student/courses');

      final List<Course> courses =
          (response.data as List).map((json) => Course.fromJson(json)).toList();

      // Mettre en cache
      await _cacheCourses(courses);

      return courses;
    } on DioException catch (e) {
      // En cas d'erreur réseau, essayer le cache
      if (e.type == DioExceptionType.connectionError) {
        final cachedCourses = await _getCachedCourses();
        if (cachedCourses.isNotEmpty) {
          return cachedCourses;
        }
      }

      if (e.error is AppException) {
        throw e.error as AppException;
      }
      throw AppException(message: 'Erreur lors du chargement des cours');
    }
  }

  Future<Course> getCourseDetail(String courseId) async {
    try {
      final response = await _dio.get('/student/courses/$courseId');
      return Course.fromJson(response.data);
    } on DioException {
      // Essayer de récupérer depuis le cache
      final cachedCourses = await _getCachedCourses();
      final cachedCourse = cachedCourses.firstWhere(
        (course) => course.id == courseId,
        orElse: () => throw AppException(message: 'Cours non trouvé'),
      );
      return cachedCourse;
    }
  }

  // Méthodes de cache
  Future<void> _cacheCourses(List<Course> courses) async {
    final coursesJson = courses.map((course) => course.toJson()).toList();
    await _storage.saveData(_coursesStorageKey, coursesJson);
  }

  Future<List<Course>> _getCachedCourses() async {
    try {
      final data = await _storage.getData(_coursesStorageKey);
      if (data != null) {
        return (data as List).map((json) => Course.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Gestion du cache des modules
  Future<void> cacheModules(String courseId, List<Module> modules) async {
    final moduleJson = modules.map((module) => module.toJson()).toList();
    await _storage.saveData('modules_$courseId', moduleJson);
  }

  Future<List<Module>> getCachedModules(String courseId) async {
    try {
      final data = await _storage.getData('modules_$courseId');
      if (data != null) {
        return (data as List).map((json) => Module.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Vérifier si un cours est inscrit en local
  Future<bool> isCourseEnrolled(String courseId) async {
    final courses = await _getCachedCourses();
    return courses.any((course) => course.id == courseId);
  }
}
