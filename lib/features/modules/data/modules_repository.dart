import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/exceptions/app_exception.dart';
import '../models/module.dart';

class ModulesRepository {
  final Dio _dio = ApiClient.instance;
  final StorageService _storage = StorageService();
  final String _modulesStorageKey = 'student_modules';

  Future<List<Module>> getModules({bool forceRefresh = false}) async {
    try {
      // Si pas de forceRefresh, essayer d'abord le cache
      if (!forceRefresh) {
        final cachedModules = await _getCachedModules();
        if (cachedModules.isNotEmpty) {
          return cachedModules;
        }
      }

      final response = await _dio.get('/students/modules');

      final List<Module> modules =
          (response.data as List).map((json) => Module.fromJson(json)).toList();

      // Mettre en cache
      await _cacheModules(modules);

      return modules;
    } on DioException catch (e) {
      // En cas d'erreur réseau, essayer le cache
      if (e.type == DioExceptionType.connectionError) {
        final cachedModules = await _getCachedModules();
        if (cachedModules.isNotEmpty) {
          return cachedModules;
        }
      }

      if (e.error is AppException) {
        throw e.error as AppException;
      }
      throw AppException(message: 'Erreur lors du chargement des modules');
    }
  }

  Future<Module> getModuleDetail(String moduleId) async {
    try {
      final response = await _dio.get('/student/modules/$moduleId');
      return Module.fromJson(response.data);
    } on DioException {
      // Essayer de récupérer depuis le cache
      final cachedModules = await _getCachedModules();
      final cachedModule = cachedModules.firstWhere(
        (module) => module.id == moduleId,
        orElse: () => throw AppException(message: 'Module non trouvé'),
      );
      return cachedModule;
    }
  }

  // Méthodes de cache
  Future<void> _cacheModules(List<Module> modules) async {
    final modulesJson = modules.map((module) => module.toJson()).toList();
    await _storage.saveData(_modulesStorageKey, modulesJson);
  }

  Future<List<Module>> _getCachedModules() async {
    try {
      final data = await _storage.getData(_modulesStorageKey);
      if (data != null) {
        return (data as List).map((json) => Module.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Gestion des modules spécifiques à un cours
  Future<void> cacheModulesForCourse(
      String courseId, List<Module> modules) async {
    final moduleJson = modules.map((module) => module.toJson()).toList();
    await _storage.saveData('modules_$courseId', moduleJson);
  }

  Future<List<Module>> getCachedModulesForCourse(String courseId) async {
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

  // Vérifier si un module est inscrit en local
  Future<bool> isModuleEnrolled(String moduleId) async {
    final modules = await _getCachedModules();
    return modules.any((module) => module.id == moduleId);
  }
}
