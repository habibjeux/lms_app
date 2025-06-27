import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/download_storage_service.dart';
import '../../../core/exceptions/app_exception.dart';
import '../models/module.dart';

class ModulesRepository {
  final Dio _dio = ApiClient.instance;
  final StorageService _storage = StorageService();
  final DownloadStorageService _downloadStorage = DownloadStorageService();
  final String _modulesStorageKey = 'student_modules';

  Future<Map<String, dynamic>> getModules({
    int page = 1,
    int limit = 5,
    String? search,
  }) async {
    print(
        "📚 Chargement des modules - page: $page, limit: $limit, search: $search");

    // Vérifier la connectivité
    final isOnline = await _isOnline();
    print("📱 Mode: ${isOnline ? 'en ligne' : 'hors ligne'}");

    if (!isOnline) {
      // Mode hors ligne : récupérer les modules téléchargés
      return await _getOfflineModules(search: search);
    }

    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      print("🌐 Tentative de chargement depuis l'API...");
      final response = await _dio.get(
        '/modules',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> modulesData = response.data['data'];
        final int total = response.data['totals'];

        final List<Module> modules =
            modulesData.map((item) => Module.fromJson(item)).toList();

        // Sauvegarder en cache pour utilisation hors ligne
        await _cacheModules(modules);
        print("✅ Modules chargés depuis l'API: ${modules.length}");

        return {
          'modules': modules,
          'total': total,
        };
      } else {
        throw AppException(message: 'Erreur lors du chargement des modules');
      }
    } on DioException catch (e) {
      print("❌ Erreur API, tentative de récupération depuis le cache...");
      // En cas d'erreur, essayer le cache local
      return await _getOfflineModules(search: search);
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

  // Méthode pour récupérer les modules hors ligne
  Future<Map<String, dynamic>> _getOfflineModules({String? search}) async {
    print(
        "🔒 Mode hors ligne - Récupération des modules depuis le cache local");

    try {
      // Récupérer les modules depuis le cache
      final cachedModules = await _getCachedModules();
      print("📦 Modules trouvés en cache: ${cachedModules.length}");

      // Récupérer les modules qui ont des contenus téléchargés
      final downloadedItems = await _downloadStorage.getDownloadedItems();
      print("💾 Éléments téléchargés: ${downloadedItems.length}");

      // Extraire les IDs de modules des éléments téléchargés (Set pour éviter doublons)
      final downloadedModuleIds = <String>{};
      for (final item in downloadedItems) {
        if (item['moduleId'] != null) {
          downloadedModuleIds.add(item['moduleId']);
        }
      }
      print("📚 Modules avec contenu téléchargé: $downloadedModuleIds");

      // Filtrer pour ne garder que les modules avec du contenu téléchargé
      // Utiliser un Map pour éviter les doublons par ID
      final uniqueModulesMap = <String, Module>{};
      for (final module in cachedModules) {
        if (downloadedModuleIds.contains(module.id)) {
          uniqueModulesMap[module.id] = module;
        }
      }

      List<Module> availableModules = uniqueModulesMap.values.toList();

      print("✅ Modules disponibles hors ligne: ${availableModules.length}");

      // Appliquer le filtre de recherche si nécessaire
      if (search != null && search.isNotEmpty) {
        availableModules = availableModules.where((module) {
          return module.title.toLowerCase().contains(search.toLowerCase()) ||
              module.code.toLowerCase().contains(search.toLowerCase()) ||
              (module.description
                      ?.toLowerCase()
                      .contains(search.toLowerCase()) ??
                  false);
        }).toList();
        print(
            "🔍 Modules filtrés par recherche '$search': ${availableModules.length}");
      }

      return {
        'modules': availableModules,
        'total': availableModules.length,
      };
    } catch (e) {
      print("❌ Erreur lors de la récupération hors ligne: $e");
      return {
        'modules': <Module>[],
        'total': 0,
      };
    }
  }

  // Vérifier la connectivité Internet
  Future<bool> _isOnline() async {
    final List<ConnectivityResult> connectivityResult =
        await Connectivity().checkConnectivity();

    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }

    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}
