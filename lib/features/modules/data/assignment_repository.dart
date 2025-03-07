import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';

import '../../../core/network/api_client.dart';
import '../../../core/exceptions/app_exception.dart';
import '../models/assignment_submission.dart';

class AssignmentRepository {
  final Dio _api = ApiClient.instance;
  final Dio _apiUpload = ApiClient.apiUploadInstance;

  Future<AssignmentSubmission?> getSubmission(String assignmentId) async {
    try {
      // Vérifier d'abord localement
      final pendingSubmissionsBox = await Hive.openBox('pending_submissions');
      final pendingSubmissions = pendingSubmissionsBox.values.toList();

      final pendingSubmission = pendingSubmissions.firstWhere(
        (submission) =>
            submission['assignmentId'] == assignmentId &&
            submission['status'] == 'pending',
        orElse: () => null,
      );

      if (pendingSubmission != null) {
        return AssignmentSubmission(
          id: pendingSubmission['id'],
          assignmentId: pendingSubmission['assignmentId'],
          studentId: '',
          submissionDate: DateTime.parse(pendingSubmission['submissionDate']),
          files: List<String>.from(pendingSubmission['files']),
          comment: pendingSubmission['comment'],
          isLate: pendingSubmission['isLate'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deletedAt: null,
          active: true,
        );
      }

      // Sinon, chercher en ligne
      final response =
          await _api.get('/assignments/$assignmentId/my-submission');

      if (response.statusCode == 200) {
        if (response.data == null) {
          return null;
        }
        return AssignmentSubmission.fromJson(response.data);
      }

      return null;
    } catch (e) {
      throw AppException(
          message: 'Erreur lors de la récupération de la soumission: $e');
    }
  }

  Future<AssignmentSubmission> submitAssignment(
    String assignmentId,
    List<File> files,
    String? comment,
    bool isLate,
  ) async {
    try {
      // Upload des fichiers
      List<String> uploadedFilePaths = await _uploadFiles(files);

      // Soumettre le devoir
      final response = await _api.post(
        '/assignment-submissions',
        data: {
          'assignmentId': assignmentId,
          'files': uploadedFilePaths,
          'comment': comment,
          'isLate': isLate,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AssignmentSubmission.fromJson(response.data);
      } else {
        throw AppException(message: 'Erreur lors de la soumission');
      }
    } catch (e) {
      throw AppException(message: 'Erreur lors de la soumission: $e');
    }
  }

  Future<AssignmentSubmission> updateSubmission(
    String submissionId,
    String assignmentId,
    List<File> files,
    String? comment,
    bool isLate,
  ) async {
    try {
      // Upload des fichiers
      List<String> uploadedFilePaths = await _uploadFiles(files);

      // Mettre à jour la soumission
      final response = await _api.put(
        '/assignments/$submissionId/my-submission',
        data: {
          'assignmentId': assignmentId,
          'files': uploadedFilePaths,
          'comment': comment,
          'isLate': isLate,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AssignmentSubmission.fromJson(response.data);
      } else {
        throw AppException(
            message: 'Erreur lors de la mise à jour de la soumission');
      }
    } catch (e) {
      throw AppException(message: 'Erreur lors de la mise à jour: $e');
    }
  }

  Future<void> deleteSubmission(String submissionId) async {
    try {
      final response =
          await _api.delete('/assignments/$submissionId/my-submission');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw AppException(
            message: 'Erreur lors de la suppression de la soumission');
      }
    } catch (e) {
      throw AppException(message: 'Erreur lors de la suppression: $e');
    }
  }

  Future<List<String>> _uploadFiles(List<File> files) async {
    List<String> uploadedFilePaths = [];

    for (var file in files) {
      final fileName = file.path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();

      // Déterminer le type MIME
      String mimeType = _getMimeType(extension);

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path,
            filename: fileName, contentType: MediaType.parse(mimeType)),
      });

      final response = await _apiUpload.post(
        '/uploads',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        uploadedFilePaths.add(response.data['filePath']);
      } else {
        throw AppException(
            message: 'Erreur lors de l\'upload du fichier $fileName');
      }
    }

    return uploadedFilePaths;
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> saveOfflineSubmission(
    String assignmentId,
    List<File> files,
    String? comment,
    bool isLate,
    String? existingSubmissionId,
  ) async {
    // Stockage des fichiers localement pour synchronisation future
    final submissionId = existingSubmissionId ?? const Uuid().v4();
    final now = DateTime.now();

    // Copier les fichiers dans un dossier temporaire
    final tempDir = await getTemporaryDirectory();
    final submissionDir =
        Directory('${tempDir.path}/pending_submissions/$submissionId');
    await submissionDir.create(recursive: true);

    List<String> localPaths = [];

    for (var file in files) {
      final fileName = file.path.split('/').last;
      final localFile = File('${submissionDir.path}/$fileName');
      await file.copy(localFile.path);
      localPaths.add(localFile.path);
    }

    // Enregistrer les métadonnées dans Hive
    final submissionData = {
      'id': submissionId,
      'assignmentId': assignmentId,
      'files': localPaths,
      'comment': comment,
      'submissionDate': now.toIso8601String(),
      'isLate': isLate,
      'existingSubmissionId': existingSubmissionId,
      'status': 'pending',
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'active': true,
    };

    final pendingSubmissionsBox = await Hive.openBox('pending_submissions');
    await pendingSubmissionsBox.put(submissionId, submissionData);

    // Ajouter à la file d'attente de synchronisation
    final syncQueueBox = await Hive.openBox('sync_queue');
    final syncQueue = syncQueueBox.get('assignments_queue', defaultValue: []);
    if (!syncQueue.contains(submissionId)) {
      syncQueue.add(submissionId);
      await syncQueueBox.put('assignments_queue', syncQueue);
    }
  }

  Future<void> markOfflineSubmissionForDeletion(String submissionId) async {
    final pendingSubmissionsBox = await Hive.openBox('pending_submissions');
    final submission = pendingSubmissionsBox.get(submissionId);

    if (submission != null) {
      // Si c'est une soumission locale qui n'a pas encore été synchronisée, on peut simplement la supprimer
      await pendingSubmissionsBox.delete(submissionId);

      // Retirer de la file d'attente de synchronisation
      final syncQueueBox = await Hive.openBox('sync_queue');
      final syncQueue = syncQueueBox.get('assignments_queue', defaultValue: []);
      if (syncQueue.contains(submissionId)) {
        syncQueue.remove(submissionId);
        await syncQueueBox.put('assignments_queue', syncQueue);
      }

      // Supprimer les fichiers locaux
      final tempDir = await getTemporaryDirectory();
      final submissionDir =
          Directory('${tempDir.path}/pending_submissions/$submissionId');
      if (await submissionDir.exists()) {
        await submissionDir.delete(recursive: true);
      }
    } else {
      // Si c'est une soumission qui a déjà été synchronisée, on la marque pour suppression
      final deletionQueueBox = await Hive.openBox('deletion_queue');
      final deletionQueue =
          deletionQueueBox.get('assignments_queue', defaultValue: []);
      if (!deletionQueue.contains(submissionId)) {
        deletionQueue.add(submissionId);
        await deletionQueueBox.put('assignments_queue', deletionQueue);
      }
    }
  }
}
