import 'package:dio/dio.dart';
import '../models/module.dart';
import '../models/module_summary.dart';

class ModuleRepository {
  final Dio _dio;

  ModuleRepository(this._dio);

  Future<Map<String, dynamic>> getModules({
    int page = 1,
    int limit = 5,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await _dio.get(
        '/modules',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> modulesJson = response.data['data'];
        final int total = response.data['totals'];

        return {
          'modules': modulesJson.map((json) => Module.fromJson(json)).toList(),
          'total': total,
        };
      } else {
        throw Exception('Erreur lors de la récupération des modules');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des modules: $e');
    }
  }

  Future<Module> createModule(Module module) async {
    try {
      final response = await _dio.post(
        '/modules',
        data: module.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Module.fromJson(response.data);
      } else {
        throw Exception('Erreur lors de la création du module');
      }
    } catch (e) {
      throw Exception('Erreur lors de la création du module: $e');
    }
  }

  Future<ModuleSummary> getModuleSummary(String moduleId) async {
    try {
      final response = await _dio.get('/modules/$moduleId/summary');
      return ModuleSummary.fromJson(response.data);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du résumé du module: $e');
    }
  }
}
