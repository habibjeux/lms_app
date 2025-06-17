import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/network/api_client.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../../core/services/offline_storage_service.dart';
import '../models/assignment_submission.dart';
import '../models/assignment.dart';

class AssignmentRepository {
  final Dio _api = ApiClient.instance;
  final Dio _apiUpload = ApiClient.uploadInstance;
  final OfflineStorageService _offlineStorage = OfflineStorageService();

  // Récupérer un devoir par son ID
  Future<Assignment?> getAssignment(String assignmentId) async {
    try {
      // Vérifier d'abord si le devoir est disponible localement
      final localData = await _offlineStorage.getAssignment(assignmentId);
      if (localData != null) {
        print('📝 Devoir trouvé localement: $assignmentId');
        return Assignment.fromJson(localData);
      }

      // Si pas disponible localement et en ligne, récupérer depuis l'API
      if (await _isOnline()) {
        final response = await _api.get('/assignments/$assignmentId');
        if (response.statusCode == 200 && response.data != null) {
          // Sauvegarder localement pour usage hors ligne
          await _offlineStorage.saveAssignment(assignmentId, response.data);
          return Assignment.fromJson(response.data);
        }
      }

      return null;
    } catch (e) {
      print('Erreur lors de la récupération du devoir: $e');
      return null;
    }
  }

  // Récupérer la soumission de l'étudiant pour un devoir
  Future<AssignmentSubmission?> getSubmission(String assignmentId) async {
    try {
      // Vérifier d'abord s'il y a une soumission en attente localement
      final pendingSubmission = await _getPendingSubmission(assignmentId);
      if (pendingSubmission != null) {
        print('📝 Soumission en attente trouvée localement: $assignmentId');
        return pendingSubmission;
      }

      // Si en ligne, récupérer depuis l'API
      if (await _isOnline()) {
        final response =
            await _api.get('/assignments/$assignmentId/my-submission');
        if (response.statusCode == 200 && response.data != null) {
          return AssignmentSubmission.fromJson(response.data);
        }
      } else {
        // Hors ligne - vérifier s'il y a une soumission synchronisée localement
        final localSubmission = await _getLocalSubmission(assignmentId);
        if (localSubmission != null) {
          return localSubmission;
        }
      }

      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la soumission: $e');
      return null;
    }
  }

  // Soumettre un devoir
  Future<AssignmentSubmission> submitAssignment({
    required String assignmentId,
    required List<File> files,
    String? comment,
    bool isLate = false,
  }) async {
    try {
      if (await _isOnline()) {
        // Soumission en ligne directe
        return await _submitOnline(
          assignmentId: assignmentId,
          files: files,
          comment: comment,
          isLate: isLate,
        );
      } else {
        // Soumission hors ligne - sauvegarder localement
        return await _submitOffline(
          assignmentId: assignmentId,
          files: files,
          comment: comment,
          isLate: isLate,
        );
      }
    } catch (e) {
      print('Erreur lors de la soumission: $e');
      rethrow;
    }
  }

  // Soumission en ligne
  Future<AssignmentSubmission> _submitOnline({
    required String assignmentId,
    required List<File> files,
    String? comment,
    bool isLate = false,
  }) async {
    final formData = FormData();

    // Ajouter les fichiers
    for (final file in files) {
      formData.files.add(
        MapEntry(
          'files',
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        ),
      );
    }

    // Ajouter les autres données
    formData.fields.add(MapEntry('assignmentId', assignmentId));
    formData.fields.add(MapEntry('comment', comment ?? ''));
    formData.fields.add(MapEntry('isLate', isLate.toString()));

    final response = await _apiUpload.post(
      '/assignments/submit',
      data: formData,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return AssignmentSubmission.fromJson(response.data);
    } else {
      throw Exception(
          'Erreur lors de la soumission: ${response.statusMessage}');
    }
  }

  // Soumission hors ligne
  Future<AssignmentSubmission> _submitOffline({
    required String assignmentId,
    required List<File> files,
    String? comment,
    bool isLate = false,
  }) async {
    final submissionId = const Uuid().v4();
    final submissionDate = DateTime.now();

    // Copier les fichiers dans un répertoire temporaire
    final tempDir = await _getTempSubmissionDirectory(submissionId);
    final savedFiles = <String>[];

    for (final file in files) {
      final fileName = file.path.split('/').last;
      final tempFile = File('${tempDir.path}/$fileName');
      await file.copy(tempFile.path);
      savedFiles.add(tempFile.path);
    }

    // Créer la soumission locale
    final submission = AssignmentSubmission(
      id: submissionId,
      createdAt: submissionDate,
      updatedAt: submissionDate,
      active: true,
      assignmentId: assignmentId,
      studentId: 'current_student', // À remplacer par l'ID réel de l'étudiant
      files: savedFiles,
      comment: comment,
      isLate: isLate,
      submissionDate: submissionDate,
    );

    // Sauvegarder dans la file d'attente de synchronisation
    await _savePendingSubmission(submission);

    print('📝 Soumission sauvegardée localement en attente de synchronisation');
    return submission;
  }

  // Obtenir le répertoire temporaire pour les soumissions
  Future<Directory> _getTempSubmissionDirectory(String submissionId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = Directory('${appDir.path}/temp_submissions/$submissionId');
    await tempDir.create(recursive: true);
    return tempDir;
  }

  // Sauvegarder une soumission en attente
  Future<void> _savePendingSubmission(AssignmentSubmission submission) async {
    final pendingBox = await Hive.openBox('pending_submissions');
    final syncQueueBox = await Hive.openBox('sync_queue');

    // Sauvegarder la soumission avec un statut personnalisé
    final submissionData = submission.toJson();
    submissionData['status'] =
        'pending'; // Statut en attente de synchronisation
    await pendingBox.put(submission.id, submissionData);

    // Ajouter à la file de synchronisation
    final List<dynamic> queue =
        syncQueueBox.get('assignments_queue', defaultValue: []);
    queue.add(submission.id);
    await syncQueueBox.put('assignments_queue', queue);
  }

  // Récupérer une soumission en attente
  Future<AssignmentSubmission?> _getPendingSubmission(
      String assignmentId) async {
    try {
      final pendingBox = await Hive.openBox('pending_submissions');
      final submissions = pendingBox.values;

      for (final submissionData in submissions) {
        if (submissionData['assignmentId'] == assignmentId) {
          return AssignmentSubmission.fromJson(submissionData);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Récupérer une soumission synchronisée localement
  Future<AssignmentSubmission?> _getLocalSubmission(String assignmentId) async {
    try {
      final localBox = await Hive.openBox('synchronized_submissions');
      final submissionData = localBox.get(assignmentId);
      if (submissionData != null) {
        return AssignmentSubmission.fromJson(submissionData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Vérifier la connexion Internet
  Future<bool> _isOnline() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());

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

  // Obtenir le chemin local d'une pièce jointe
  Future<String?> getLocalAttachmentPath(
      String attachmentId, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final attachmentPath =
          '${directory.path}/assignments/attachments/$attachmentId-$filename';
      final file = File(attachmentPath);

      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
