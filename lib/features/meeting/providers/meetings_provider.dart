import 'package:flutter/foundation.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../data/modules_repository.dart';

class MeetingsProvider with ChangeNotifier {
  final MeetingRepository _repository = MeetingRepository();

  String _token = '';
  bool _isLoading = false;
  String? _error;

  String get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadJitsiToken() async {
    _setLoading(true);
    _clearError();

    try {
      _token = await _repository.getJitsiJWTToken();
      _clearError();
    } on AppException catch (e) {
      _setError(e.toString());
    } catch (e) {
      _setError(
          'Une erreur est survenue lors de la récupération du token Jitsi');
    } finally {
      _setLoading(false);
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
}
