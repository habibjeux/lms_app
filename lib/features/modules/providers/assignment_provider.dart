import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/assignment_repository.dart';
import '../models/assignment.dart';
import '../models/assignment_submission.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/download_storage_service.dart';
import '../../../core/utlils/error_helper.dart';
import 'package:flutter/material.dart';

class AssignmentProvider with ChangeNotifier {
  final AssignmentRepository _repository = AssignmentRepository();
  final SyncService _syncService = SyncService();
  final DownloadStorageService _downloadStorage = DownloadStorageService();

  Assignment? _currentAssignment;
  AssignmentSubmission? _currentSubmission;
  final List<AssignmentSubmission> _submissions = [];

  bool _isLoading = false;
  bool _isDownloading = false;
  bool _isSubmitting = false;
  double _downloadProgress = 0.0;
  double _submitProgress = 0.0;
  String? _error;
  final bool _isDownloaded = false;

  // Getters
  Assignment? get currentAssignment => _currentAssignment;
  AssignmentSubmission? get currentSubmission => _currentSubmission;
  List<AssignmentSubmission> get submissions => _submissions;
  bool get isLoading => _isLoading;
  bool get isDownloading => _isDownloading;
  bool get isSubmitting => _isSubmitting;
  double get downloadProgress => _downloadProgress;
  double get submitProgress => _submitProgress;
  String? get error => _error;
  bool get isDownloaded => _isDownloaded;
  bool get hasSubmission => _currentSubmission != null;

  // Vérifier si on peut supprimer une soumission
  bool get canDeleteSubmission {
    if (_currentAssignment == null || _currentSubmission == null) {
      return false;
    }

    // Vérifier si la date limite est dépassée
    if (_currentAssignment!.endDate != null &&
        DateTime.now().isAfter(_currentAssignment!.endDate!)) {
      return false;
    }

    return true;
  }

  // Méthodes privées pour gérer les états
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setDownloading(bool downloading) {
    _isDownloading = downloading;
    notifyListeners();
  }

  void _setSubmitting(bool submitting) {
    _isSubmitting = submitting;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Charger un devoir
  Future<void> loadAssignment(String assignmentId) async {
    _setLoading(true);
    _clearError();

    try {
      print("🔍 Chargement de l'assignment: $assignmentId");
      _currentAssignment = await _repository.getAssignment(assignmentId);

      if (_currentAssignment != null) {
        print("✅ Assignment chargé: ${_currentAssignment!.title}");
        await _loadSubmission(assignmentId);
      } else {
        print("❌ Assignment introuvable pour l'ID: $assignmentId");
        _setError("Devoir introuvable");
      }

      notifyListeners();
    } catch (e) {
      print("❌ Erreur lors du chargement de l'assignment: $e");
      _setError("Erreur lors du chargement: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  // Charger la soumission de l'étudiant
  Future<void> _loadSubmission(String assignmentId) async {
    try {
      print("🔍 Chargement de la soumission pour: $assignmentId");
      _currentSubmission = await _repository.getSubmission(assignmentId);
      if (_currentSubmission != null) {
        print("✅ Soumission trouvée: ${_currentSubmission!.id}");
      } else {
        print("ℹ️ Aucune soumission trouvée pour cet assignment");
      }
    } catch (e) {
      print('❌ Erreur lors du chargement de la soumission: $e');
      print('Stack trace: ${StackTrace.current}');
      _currentSubmission = null;
    }
  }

  // Télécharger un devoir pour utilisation hors ligne
  Future<void> downloadAssignmentForOffline(String assignmentId) async {
    _setDownloading(true);
    _downloadProgress = 0.0;

    try {
      // Simuler le progrès de téléchargement
      for (int i = 0; i <= 100; i += 10) {
        _downloadProgress = i / 100;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await _syncService.downloadAssignment(
        assignmentId,
        moduleId: _currentAssignment?.moduleId ?? '',
        chapterId: _currentAssignment?.chapterId,
        title: _currentAssignment?.title ?? '',
      );

      if (_currentAssignment != null) {
        await _repository.saveAssignmentToCache(_currentAssignment!);
      }

      _downloadProgress = 1.0;
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du téléchargement: $e');
    } finally {
      _setDownloading(false);
    }
  }

  // Vérifier si un devoir est téléchargé
  Future<bool> isAssignmentDownloaded(String assignmentId) async {
    return await _repository.isAssignmentDownloaded(assignmentId);
  }

  // Soumettre un devoir
  Future<void> submitAssignment(
    String assignmentId,
    List<File> files,
    String? comment,
  ) async {
    _setSubmitting(true);
    _submitProgress = 0.0;
    _clearError();

    try {
      // Vérifier si le devoir est en retard
      final isLate = _currentAssignment != null &&
          _currentAssignment!.endDate != null &&
          DateTime.now().isAfter(_currentAssignment!.endDate!);

      // Simuler le progrès d'upload
      for (int i = 0; i <= 50; i += 10) {
        _submitProgress = i / 100;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 50));
      }

      _currentSubmission = await _repository.submitAssignment(
        assignmentId: assignmentId,
        files: files,
        comment: comment,
        isLate: isLate,
      );

      // Finaliser le progrès
      _submitProgress = 1.0;
      notifyListeners();
    } catch (e) {
      _setError(
          ErrorHelper.getCleanErrorMessage(e, 'Erreur lors de la soumission'));
    } finally {
      _setSubmitting(false);
    }
  }

  // Supprimer une soumission (seulement en ligne)
  Future<void> deleteSubmission(
      String submissionId, String assignmentId) async {
    _setLoading(true);
    _clearError();

    try {
      // Vérifier si le devoir existe
      if (_currentAssignment == null) {
        throw Exception('Devoir non chargé');
      }

      // Vérifier si la date limite est dépassée
      if (_currentAssignment!.endDate != null &&
          DateTime.now().isAfter(_currentAssignment!.endDate!)) {
        throw Exception(
            'Impossible de supprimer la soumission après la date limite du devoir');
      }

      await _repository.deleteSubmission(submissionId, assignmentId);
      _currentSubmission = null;
      notifyListeners();
    } catch (e) {
      _setError(
          ErrorHelper.getCleanErrorMessage(e, 'Erreur lors de la suppression'));
    } finally {
      _setLoading(false);
    }
  }

  // Rafraîchir les données
  Future<void> refresh(String assignmentId) async {
    await loadAssignment(assignmentId);
  }

  // Nettoyer les données
  // Vérifier le nombre de soumissions en attente
  Future<int> getPendingSubmissionsCount() async {
    return await _syncService.getPendingSubmissionsCount();
  }

  // Synchroniser les soumissions en attente
  Future<void> syncPendingSubmissions() async {
    try {
      await _syncService.syncPendingAssignmentSubmissions();

      // Recharger les données si on a un assignment actuel
      if (_currentAssignment != null) {
        await _loadSubmission(_currentAssignment!.id);
      }

      notifyListeners();
    } catch (e) {
      print('Erreur lors de la synchronisation: $e');
    }
  }

  void clear() {
    _currentAssignment = null;
    _currentSubmission = null;
    _submissions.clear();
    _isLoading = false;
    _isDownloading = false;
    _isSubmitting = false;
    _downloadProgress = 0.0;
    _submitProgress = 0.0;
    _error = null;
    notifyListeners();
  }
}
