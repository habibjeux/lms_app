import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../data/assignment_repository.dart';
import '../models/assignment.dart';
import '../models/assignment_submission.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/download_storage_service.dart';
import '../../../core/network/api_client.dart';
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

  // État des téléchargements des pièces jointes
  final Map<String, bool> _downloadingAttachments = {};
  final Map<String, bool> _downloadedAttachments = {};

  // État des téléchargements des fichiers soumis
  final Map<String, bool> _downloadingSubmissionFiles = {};
  final Map<String, bool> _downloadedSubmissionFiles = {};

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

        // Vérifier le statut des pièces jointes
        await _checkAllAttachmentsStatus();
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

        // Vérifier le statut des fichiers soumis
        await _checkAllSubmissionFilesStatus();
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
      print(
          "🔽 Début du téléchargement complet de l'assignment: $assignmentId");

      // Étape 1: Charger COMPLÈTEMENT l'assignment depuis l'API (25% du progrès)
      _downloadProgress = 0.1;
      notifyListeners();

      print("📥 Chargement de l'assignment complet depuis l'API...");
      _currentAssignment = await _repository.getAssignment(assignmentId);
      if (_currentAssignment == null) {
        throw Exception('Impossible de charger l\'assignment depuis l\'API');
      }

      print(
          "✅ Assignment chargé avec ${_currentAssignment!.attachments.length} pièces jointes");

      // Charger aussi la soumission et s'assurer qu'elle est sauvegardée localement
      await _loadSubmission(assignmentId);
      if (_currentSubmission != null) {
        print("💾 Sauvegarde de la soumission pour utilisation hors ligne...");
        await _repository.saveSubmissionLocally(
            assignmentId, _currentSubmission!);
      }

      _downloadProgress = 0.25;
      notifyListeners();

      // Étape 2: Sauvegarder les métadonnées et télécharger via le sync service (25% du progrès)
      print("💾 Sauvegarde des métadonnées via sync service...");
      await _syncService.downloadAssignment(
        assignmentId,
        moduleId: _currentAssignment!.moduleId,
        chapterId: _currentAssignment!.chapterId,
        title: _currentAssignment!.title,
      );

      await _repository.saveAssignmentToCache(_currentAssignment!);

      _downloadProgress = 0.5;
      notifyListeners();

      // Étape 3: Télécharger toutes les pièces jointes (25% du progrès)
      print("📎 Téléchargement des pièces jointes...");
      if (_currentAssignment!.attachments.isNotEmpty) {
        final attachmentCount = _currentAssignment!.attachments.length;
        print("📁 Téléchargement de $attachmentCount pièces jointes...");

        for (int i = 0; i < attachmentCount; i++) {
          final attachment = _currentAssignment!.attachments[i];
          try {
            print(
                "⬇️ Téléchargement pièce jointe ${i + 1}/$attachmentCount: ${attachment.filename}");
            await downloadAttachment(attachment);
            // Mise à jour du progrès pour les pièces jointes
            _downloadProgress = 0.5 + (0.25 * (i + 1) / attachmentCount);
            notifyListeners();
            print("✅ Pièce jointe téléchargée: ${attachment.filename}");
          } catch (e) {
            print(
                "❌ Erreur lors du téléchargement de la pièce jointe ${attachment.filename}: $e");
            // Continue avec les autres pièces jointes même si une échoue
          }
        }
      } else {
        print("ℹ️ Aucune pièce jointe à télécharger");
      }

      _downloadProgress = 0.75;
      notifyListeners();

      // Étape 4: Télécharger tous les fichiers soumis (25% final)
      print("📄 Téléchargement des fichiers soumis...");
      if (_currentSubmission?.files.isNotEmpty ?? false) {
        final submissionFileCount = _currentSubmission!.files.length;
        print("📄 Téléchargement de $submissionFileCount fichiers soumis...");

        for (int i = 0; i < submissionFileCount; i++) {
          final filePath = _currentSubmission!.files[i];
          try {
            print(
                "⬇️ Téléchargement fichier soumis ${i + 1}/$submissionFileCount: $filePath");
            await downloadSubmissionFile(filePath);
            // Mise à jour du progrès pour les fichiers soumis
            _downloadProgress = 0.75 + (0.25 * (i + 1) / submissionFileCount);
            notifyListeners();
            print("✅ Fichier soumis téléchargé: $filePath");
          } catch (e) {
            print(
                "❌ Erreur lors du téléchargement du fichier soumis $filePath: $e");
            // Continue avec les autres fichiers même si un échoue
          }
        }
      } else {
        print("ℹ️ Aucun fichier soumis à télécharger");
      }

      _downloadProgress = 1.0;
      notifyListeners();

      print(
          "🎉 Téléchargement complet terminé pour l'assignment: $assignmentId");
    } catch (e) {
      print("❌ Erreur lors du téléchargement complet: $e");
      _setError('Erreur lors du téléchargement: $e');
    } finally {
      _setDownloading(false);
    }
  }

  // Vérifier si un devoir est téléchargé
  Future<bool> isAssignmentDownloaded(String assignmentId) async {
    return await _repository.isAssignmentDownloaded(assignmentId);
  }

  // Charger un assignment déjà téléchargé (mode hors ligne)
  Future<void> loadOfflineAssignment(String assignmentId) async {
    _setLoading(true);
    _clearError();

    try {
      print("🔍 Chargement de l'assignment hors ligne: $assignmentId");
      _currentAssignment = await _repository.getAssignment(assignmentId);

      if (_currentAssignment != null) {
        print("✅ Assignment hors ligne chargé: ${_currentAssignment!.title}");
        await _loadSubmission(assignmentId);

        // EN MODE HORS LIGNE : Forcer la vérification et le rechargement des états
        print("🔄 Vérification forcée des états des fichiers téléchargés...");

        // Vider les états actuels pour les recalculer
        _downloadedAttachments.clear();
        _downloadedSubmissionFiles.clear();

        // Vérifier les pièces jointes une par une
        for (final attachment in _currentAssignment!.attachments) {
          final attachmentId = _getAttachmentId(attachment);
          print(
              "🔍 Vérification pièce jointe: $attachmentId (${attachment.filename})");

          final isDownloaded =
              await _downloadStorage.isAttachmentDownloaded(attachmentId);
          _downloadedAttachments[attachmentId] = isDownloaded;

          if (isDownloaded) {
            final attachmentInfo =
                await _downloadStorage.getAttachmentInfo(attachmentId);
            print(
                "✅ Pièce jointe trouvée: ${attachment.filename} -> ${attachmentInfo?['localPath']}");
          } else {
            print("❌ Pièce jointe non trouvée: ${attachment.filename}");
          }
        }

        // Vérifier les fichiers soumis si une soumission existe
        if (_currentSubmission?.files.isNotEmpty ?? false) {
          for (final filePath in _currentSubmission!.files) {
            print("🔍 Vérification fichier soumis: $filePath");

            final isDownloaded = await _downloadStorage
                .isSubmissionFileDownloaded(filePath, _currentSubmission!.id);
            _downloadedSubmissionFiles[filePath] = isDownloaded;

            if (isDownloaded) {
              final fileInfo = await _downloadStorage.getSubmissionFileInfo(
                  filePath, _currentSubmission!.id);
              print(
                  "✅ Fichier soumis trouvé: $filePath -> ${fileInfo?['localPath']}");
            } else {
              print("❌ Fichier soumis non trouvé: $filePath");
            }
          }
        }

        print("📊 États finaux:");
        print(
            "   - Pièces jointes: ${_downloadedAttachments.length} vérifiées");
        print(
            "   - Fichiers soumis: ${_downloadedSubmissionFiles.length} vérifiés");
      } else {
        print("❌ Assignment introuvable hors ligne pour l'ID: $assignmentId");
        _setError("Devoir non disponible hors ligne");
      }

      notifyListeners();
    } catch (e) {
      print("❌ Erreur lors du chargement de l'assignment hors ligne: $e");
      _setError("Erreur lors du chargement hors ligne: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
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

  // Méthodes pour les pièces jointes
  bool isDownloadingAttachment(String attachmentId) {
    return _downloadingAttachments[attachmentId] ?? false;
  }

  bool isAttachmentDownloaded(String attachmentId) {
    return _downloadedAttachments[attachmentId] ?? false;
  }

  Future<void> checkAttachmentStatus(String attachmentId) async {
    final isDownloaded =
        await _downloadStorage.isAttachmentDownloaded(attachmentId);
    _downloadedAttachments[attachmentId] = isDownloaded;
    notifyListeners();
  }

  Future<void> _checkAllAttachmentsStatus() async {
    if (_currentAssignment?.attachments.isEmpty ?? true) return;

    print("🔄 Vérification du statut des pièces jointes...");
    for (final attachment in _currentAssignment!.attachments) {
      final attachmentId = _getAttachmentId(attachment);
      print("🔍 Vérification pièce jointe: $attachmentId");

      final isDownloaded =
          await _downloadStorage.isAttachmentDownloaded(attachmentId);
      _downloadedAttachments[attachmentId] = isDownloaded;

      print(
          "   - ${attachment.filename}: ${isDownloaded ? '✅ téléchargée' : '❌ non téléchargée'}");
    }
    print(
        "📊 Vérification terminée: ${_downloadedAttachments.length} pièces jointes vérifiées");
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getAttachmentLocalPath(
      String attachmentId) async {
    return await _downloadStorage.getAttachmentInfo(attachmentId);
  }

  Future<void> downloadAttachment(dynamic attachment) async {
    final attachmentId = _getAttachmentId(attachment);
    print(
        "📎 Début téléchargement pièce jointe: $attachmentId (${attachment.filename})");

    _downloadingAttachments[attachmentId] = true;
    notifyListeners();

    try {
      // Créer le répertoire local pour les pièces jointes
      final directory = await getApplicationDocumentsDirectory();
      final attachmentsPath = '${directory.path}/assignments/attachments';
      await Directory(attachmentsPath).create(recursive: true);

      // Nom de fichier unique pour éviter les conflits
      final localFile =
          File('$attachmentsPath/$attachmentId-${attachment.filename}');

      // Vérifier si le fichier existe déjà physiquement
      if (await localFile.exists()) {
        print(
            '📁 Pièce jointe existe déjà physiquement: ${attachment.filename}');

        // Vérifier aussi dans Hive et mettre à jour si nécessaire
        final isInHive =
            await _downloadStorage.isAttachmentDownloaded(attachmentId);
        if (!isInHive) {
          print('💾 Mise à jour des métadonnées dans Hive...');
          await _downloadStorage.saveAttachment(
            attachment,
            _currentAssignment?.moduleId ?? '',
            _currentAssignment?.chapterId,
            _currentAssignment?.id ?? '',
            localPath: localFile.path,
          );
        }

        _downloadedAttachments[attachmentId] = true;
        return;
      }

      // Construire l'URL complète
      final serverUrl = dotenv.env['SERVER_URL'] ?? '';
      final fullUrl = attachment.url.startsWith('http')
          ? attachment.url
          : '$serverUrl${attachment.url}';

      print('⬇️ Téléchargement de la pièce jointe depuis: $fullUrl');

      // Télécharger le fichier
      final dio = ApiClient.downloadInstance;
      final response = await dio.get(
        fullUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      // Sauvegarder le fichier localement
      await localFile.writeAsBytes(response.data);
      print(
          '💾 Pièce jointe sauvegardée: ${attachment.filename} -> ${localFile.path}');

      // Sauvegarder les métadonnées avec le chemin local
      await _downloadStorage.saveAttachment(
        attachment,
        _currentAssignment?.moduleId ?? '',
        _currentAssignment?.chapterId,
        _currentAssignment?.id ?? '',
        localPath: localFile.path,
      );

      _downloadedAttachments[attachmentId] = true;
      print('✅ Pièce jointe téléchargée avec succès: ${attachment.filename}');
    } catch (e) {
      print(
          '❌ Erreur lors du téléchargement de la pièce jointe ${attachment.filename}: $e');
      _setError('Erreur lors du téléchargement de la pièce jointe: $e');
    } finally {
      _downloadingAttachments[attachmentId] = false;
      notifyListeners();
    }
  }

  Future<void> downloadAllAttachments() async {
    if (_currentAssignment?.attachments.isEmpty ?? true) return;

    for (final attachment in _currentAssignment!.attachments) {
      await downloadAttachment(attachment);
    }
  }

  // Méthodes pour les fichiers soumis
  bool isDownloadingSubmissionFile(String filePath) {
    return _downloadingSubmissionFiles[filePath] ?? false;
  }

  bool isSubmissionFileDownloaded(String filePath) {
    return _downloadedSubmissionFiles[filePath] ?? false;
  }

  Future<void> checkSubmissionFileStatus(String filePath) async {
    if (_currentSubmission == null) return;

    final isDownloaded = await _downloadStorage.isSubmissionFileDownloaded(
        filePath, _currentSubmission!.id);
    _downloadedSubmissionFiles[filePath] = isDownloaded;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getSubmissionFileLocalPath(
      String filePath) async {
    if (_currentSubmission == null) {
      print("❌ Pas de soumission actuelle pour récupérer le chemin local");
      return null;
    }

    print(
        "🔍 Récupération chemin local pour: $filePath avec soumission ID: ${_currentSubmission!.id}");
    final result = await _downloadStorage.getSubmissionFileInfo(
        filePath, _currentSubmission!.id);
    print("📂 Résultat récupération: $result");
    return result;
  }

  Future<void> downloadSubmissionFile(String filePath) async {
    if (_currentSubmission == null || _currentAssignment == null) return;

    final filename = filePath.split('/').last;
    print("📄 Début téléchargement fichier soumis: $filename");

    _downloadingSubmissionFiles[filePath] = true;
    notifyListeners();

    try {
      // Créer le répertoire local pour les fichiers soumis
      final directory = await getApplicationDocumentsDirectory();
      final submissionFilesPath = '${directory.path}/assignments/submissions';
      await Directory(submissionFilesPath).create(recursive: true);

      // Nom de fichier unique
      final localFile =
          File('$submissionFilesPath/${_currentSubmission!.id}-$filename');

      // Vérifier si le fichier existe déjà physiquement
      if (await localFile.exists()) {
        print('📁 Fichier soumis existe déjà physiquement: $filename');

        // TOUJOURS mettre à jour les métadonnées pour s'assurer de la cohérence
        print('💾 Mise à jour forcée des métadonnées dans Hive...');
        await _downloadStorage.saveSubmissionFile(
          filePath,
          _currentAssignment!.id,
          _currentSubmission!.id,
          localPath: localFile.path,
        );
        print('💾 Métadonnées mises à jour avec succès pour: $filename');

        _downloadedSubmissionFiles[filePath] = true;
        return;
      }

      // Construire l'URL complète
      final serverUrl = dotenv.env['SERVER_URL'] ?? '';
      final fullUrl =
          filePath.startsWith('http') ? filePath : '$serverUrl$filePath';

      print('⬇️ Téléchargement du fichier soumis depuis: $fullUrl');

      // Télécharger le fichier
      final dio = ApiClient.downloadInstance;
      final response = await dio.get(
        fullUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      // Sauvegarder le fichier localement
      await localFile.writeAsBytes(response.data);
      print('💾 Fichier soumis sauvegardé: $filename -> ${localFile.path}');

      // Sauvegarder les métadonnées avec le chemin local
      await _downloadStorage.saveSubmissionFile(
        filePath,
        _currentAssignment!.id,
        _currentSubmission!.id,
        localPath: localFile.path,
      );

      _downloadedSubmissionFiles[filePath] = true;
      print('✅ Fichier soumis téléchargé avec succès: $filename');
    } catch (e) {
      print('❌ Erreur lors du téléchargement du fichier soumis $filePath: $e');
      _setError('Erreur lors du téléchargement du fichier soumis: $e');
    } finally {
      _downloadingSubmissionFiles[filePath] = false;
      notifyListeners();
    }
  }

  Future<void> downloadAllSubmissionFiles() async {
    if (_currentSubmission?.files.isEmpty ?? true) return;

    for (final filePath in _currentSubmission!.files) {
      await downloadSubmissionFile(filePath);
    }
  }

  Future<void> _checkAllSubmissionFilesStatus() async {
    if (_currentSubmission?.files.isEmpty ?? true) return;

    print("🔄 Vérification du statut des fichiers soumis...");
    for (final filePath in _currentSubmission!.files) {
      print("🔍 Vérification fichier soumis: $filePath");

      final isDownloaded = await _downloadStorage.isSubmissionFileDownloaded(
          filePath, _currentSubmission!.id);
      _downloadedSubmissionFiles[filePath] = isDownloaded;

      final filename = filePath.split('/').last;
      print(
          "   - $filename: ${isDownloaded ? '✅ téléchargé' : '❌ non téléchargé'}");
    }
    print(
        "📊 Vérification terminée: ${_downloadedSubmissionFiles.length} fichiers soumis vérifiés");
    notifyListeners();
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
    _downloadingAttachments.clear();
    _downloadedAttachments.clear();
    _downloadingSubmissionFiles.clear();
    _downloadedSubmissionFiles.clear();
    notifyListeners();
  }

  // Méthode utilitaire pour obtenir un ID cohérent pour les pièces jointes
  String _getAttachmentId(dynamic attachment) {
    // Utiliser d'abord l'ID si disponible, sinon le nom de fichier
    return attachment.id?.toString() ?? attachment.filename?.toString() ?? '';
  }
}
