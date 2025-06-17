import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/assignment_repository.dart';
import '../models/assignment.dart';
import '../models/assignment_submission.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/download_storage_service.dart';

class AssignmentProvider with ChangeNotifier {
  final AssignmentRepository _repository = AssignmentRepository();
  final SyncService _syncService = SyncService();
  final DownloadStorageService _downloadStorage = DownloadStorageService();

  Assignment? _currentAssignment;
  AssignmentSubmission? _currentSubmission;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  bool _isDownloaded = false;
  double _downloadProgress = 0.0;

  // Getters
  Assignment? get currentAssignment => _currentAssignment;
  AssignmentSubmission? get currentSubmission => _currentSubmission;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  bool get isDownloaded => _isDownloaded;
  double get downloadProgress => _downloadProgress;

  // Charger un devoir
  Future<void> loadAssignment(String assignmentId) async {
    _setLoading(true);
    _setError(null);

    try {
      // Charger le devoir
      _currentAssignment = await _repository.getAssignment(assignmentId);

      if (_currentAssignment != null) {
        // Vérifier s'il est téléchargé
        _isDownloaded =
            await _downloadStorage.isAssignmentDownloaded(assignmentId);

        // Charger la soumission existante
        await _loadSubmission(assignmentId);
      }
    } catch (e) {
      _setError('Erreur lors du chargement du devoir: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Charger la soumission existante
  Future<void> _loadSubmission(String assignmentId) async {
    try {
      _currentSubmission = await _repository.getSubmission(assignmentId);
    } catch (e) {
      print('Erreur lors du chargement de la soumission: $e');
      // Ne pas afficher d'erreur à l'utilisateur pour la soumission
    }
  }

  // Télécharger un devoir
  Future<void> downloadAssignment(
    String assignmentId, {
    String? moduleId,
    String? chapterId,
    String? title,
  }) async {
    _setError(null);
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      await _syncService.downloadAssignment(
        assignmentId,
        moduleId: moduleId,
        chapterId: chapterId,
        title: title,
        onProgress: (progress) {
          _downloadProgress = progress;
          notifyListeners();
        },
      );

      _isDownloaded = true;
      _downloadProgress = 1.0;

      // Recharger le devoir avec les données complètes
      await loadAssignment(assignmentId);
    } catch (e) {
      _setError('Erreur lors du téléchargement: $e');
      _downloadProgress = 0.0;
    }

    notifyListeners();
  }

  // Soumettre un devoir
  Future<bool> submitAssignment({
    required String assignmentId,
    required List<File> files,
    String? comment,
    bool isLate = false,
  }) async {
    _setSubmitting(true);
    _setError(null);

    try {
      final submission = await _repository.submitAssignment(
        assignmentId: assignmentId,
        files: files,
        comment: comment,
        isLate: isLate,
      );

      _currentSubmission = submission;

      // Si c'est une soumission hors ligne, informer l'utilisateur
      if (!await _syncService.isOnline()) {
        _setError(
            'Soumission sauvegardée localement. Elle sera synchronisée dès que la connexion sera rétablie.');
      }

      return true;
    } catch (e) {
      _setError('Erreur lors de la soumission: $e');
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  // Vérifier si un devoir est téléchargé
  Future<bool> checkIfDownloaded(String assignmentId) async {
    _isDownloaded = await _downloadStorage.isAssignmentDownloaded(assignmentId);
    notifyListeners();
    return _isDownloaded;
  }

  // Obtenir le chemin local d'une pièce jointe
  Future<String?> getLocalAttachmentPath(
      String attachmentId, String filename) async {
    return await _repository.getLocalAttachmentPath(attachmentId, filename);
  }

  // Obtenir le nombre de soumissions en attente
  Future<int> getPendingSubmissionsCount() async {
    return await _syncService.getPendingSubmissionsCount();
  }

  // Synchroniser les soumissions en attente
  Future<void> syncPendingSubmissions() async {
    try {
      await _syncService.syncPendingAssignmentSubmissions();

      // Recharger la soumission actuelle si elle existe
      if (_currentAssignment != null) {
        await _loadSubmission(_currentAssignment!.id);
      }

      notifyListeners();
    } catch (e) {
      print('Erreur lors de la synchronisation: $e');
    }
  }

  // Méthodes privées pour la gestion d'état
  void _setLoading(bool loading) {
    _isLoading = loading;
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

  // Nettoyer les données
  void clear() {
    _currentAssignment = null;
    _currentSubmission = null;
    _isLoading = false;
    _isSubmitting = false;
    _error = null;
    _isDownloaded = false;
    _downloadProgress = 0.0;
    notifyListeners();
  }
}
