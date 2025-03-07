import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../../core/services/sync_service.dart';
import '../data/assignment_repository.dart';
import '../models/assignment_submission.dart';

class AssignmentSubmissionProvider with ChangeNotifier {
  final AssignmentRepository _repository = AssignmentRepository();
  final SyncService _syncService = SyncService();

  AssignmentSubmission? _submission;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  bool _isSuccess = false;

  AssignmentSubmission? get submission => _submission;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  bool get isSuccess => _isSuccess;
  bool get hasSubmission => _submission != null;

  Future<void> loadSubmission(String assignmentId) async {
    _setLoading(true);
    _clearError();
    setSuccess(false);

    try {
      _submission = await _repository.getSubmission(assignmentId);
      _clearError();
    } catch (e) {
      _setError('Erreur lors du chargement de la soumission: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitAssignment(
      String assignmentId, List<File> files, String? comment, bool isLate,
      {AssignmentSubmission? existingSubmission}) async {
    _setSaving(true);
    _clearError();
    setSuccess(false);

    try {
      final isOnline = await _syncService.isOnline();

      if (isOnline) {
        if (existingSubmission != null) {
          _submission = await _repository.updateSubmission(
              existingSubmission.id, assignmentId, files, comment, isLate);
        } else {
          _submission = await _repository.submitAssignment(
              assignmentId, files, comment, isLate);
        }
      } else {
        await _repository.saveOfflineSubmission(
            assignmentId, files, comment, isLate, existingSubmission?.id);

        // Optionnellement mettre à jour l'affichage en local
        if (existingSubmission != null) {
          _submission = AssignmentSubmission(
            id: existingSubmission.id,
            assignmentId: assignmentId,
            files: files.map((f) => f.path).toList(),
            comment: comment,
            isLate: isLate,
            submissionDate: DateTime.now(),
            studentId: existingSubmission.studentId,
            createdAt: existingSubmission.createdAt,
            updatedAt: DateTime.now(),
            deletedAt: null,
            active: true,
          );
        } else {
          _submission = AssignmentSubmission(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            assignmentId: assignmentId,
            files: files.map((f) => f.path).toList(),
            comment: comment,
            isLate: isLate,
            submissionDate: DateTime.now(),
            studentId: '', // sera rempli lors de la synchronisation
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            deletedAt: null,
            active: true,
          );
        }
      }

      setSuccess(true);
    } catch (e) {
      _setError('Erreur lors de la soumission: $e');
    } finally {
      _setSaving(false);
    }
  }

  Future<void> deleteSubmission(
      String submissionId, String assignmentId) async {
    _setSaving(true);
    _clearError();
    setSuccess(false);

    try {
      final isOnline = await _syncService.isOnline();

      if (isOnline) {
        await _repository.deleteSubmission(submissionId);
      } else {
        await _repository.markOfflineSubmissionForDeletion(submissionId);
      }

      _submission = null;
      setSuccess(true);
    } catch (e) {
      _setError('Erreur lors de la suppression: $e');
    } finally {
      _setSaving(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void setSuccess(bool value) {
    _isSuccess = value;
    notifyListeners();
  }

  void reset() {
    _submission = null;
    _isLoading = false;
    _isSaving = false;
    _error = null;
    _isSuccess = false;
    notifyListeners();
  }
}
