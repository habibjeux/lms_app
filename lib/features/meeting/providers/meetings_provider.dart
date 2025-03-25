import 'package:flutter/foundation.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../data/meetings_repository.dart';
import '../models/course_session.dart';

class MeetingsProvider with ChangeNotifier {
  final MeetingsRepository _repository = MeetingsRepository();

  List<CourseSession> _upcomingSessions = [];
  CourseSession? _activeSession;
  CourseSession? _currentSession;
  bool _isLoading = false;
  String? _error;

  String _token = '';
  String _roomName = '';
  String _sessionTitle = '';
  String _courseTitle = '';

  List<CourseSession> get upcomingSessions => _upcomingSessions;
  CourseSession? get activeSession => _activeSession;
  CourseSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get token => _token;
  String get roomName => _roomName;
  String get sessionTitle => _sessionTitle;
  String get courseTitle => _courseTitle;

  Future<void> loadUpcomingSessions() async {
    _setLoading(true);
    _clearError();

    try {
      _upcomingSessions = await _repository.getUpcomingSessions();
      _clearError();
    } on AppException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Une erreur est survenue lors de la récupération des séances');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadActiveSession() async {
    _setLoading(true);
    _clearError();

    try {
      _activeSession = await _repository.getActiveSession();
      _clearError();
    } on AppException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(
          'Une erreur est survenue lors de la récupération de la séance active');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSessionById(String sessionId) async {
    _setLoading(true);
    _clearError();

    try {
      _currentSession = await _repository.getSessionById(sessionId);
      _clearError();
    } on AppException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Une erreur est survenue lors de la récupération de la séance');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> joinSession(String sessionId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _repository.joinSession(sessionId);

      _token = result['token'];
      _roomName = result['roomName'];
      _sessionTitle = result['sessionTitle'] ?? '';
      _courseTitle = result['courseTitle'] ?? '';

      _clearError();
      return true;
    } on AppException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError(
          'Une erreur est survenue lors de la tentative de rejoindre la séance');
      return false;
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
