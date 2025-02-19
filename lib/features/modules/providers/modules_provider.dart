import 'package:flutter/foundation.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../data/modules_repository.dart';
import '../models/module.dart';

class ModulesProvider with ChangeNotifier {
  final ModulesRepository _repository = ModulesRepository();

  List<Module> _modules = [];
  bool _isLoading = false;
  String? _error;

  List<Module> get modules => _modules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadModules() async {
    _setLoading(true);
    _clearError();

    try {
      _modules = await _repository.getModules();
      _clearError();
    } on AppException catch (e) {
      _setError(e.toString());
    } catch (e) {
      _setError('Une erreur est survenue lors du chargement des modules');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshModules() async {
    try {
      final freshModules = await _repository.getModules(forceRefresh: true);
      _modules = freshModules;
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
  List<Module> getActiveModules() {
    return _modules.where((module) => module.active).toList();
  }

  // Recherche de modules
  List<Module> searchModules(String query) {
    if (query.isEmpty) return _modules;

    return _modules.where((module) {
      return module.title.toLowerCase().contains(query.toLowerCase()) ||
          module.code.toLowerCase().contains(query.toLowerCase()) ||
          module.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}
