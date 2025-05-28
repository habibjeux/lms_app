import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/exceptions/app_exception.dart';
import '../models/quiz.dart';
import '../models/quiz_attempt.dart';
import '../models/student_answer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class QuizRepository {
  final Dio _dio = ApiClient.instance;
  final StorageService _storage = StorageService();

  String _getQuizKey(String quizId) => 'quiz_$quizId';
  String _getQuizAttemptsKey(String quizId) => 'quiz_attempts_$quizId';
  String _getPendingSubmissionsKey() => 'quiz_pending_submissions';

  Future<Quiz> getQuiz(String quizId) async {
    try {
      // Si pas de forceRefresh, essayer d'abord le cache
      /*final cachedQuiz = await _getCachedQuiz(quizId);
      if (cachedQuiz != null) {
        return cachedQuiz;
      }*/

      final response = await _dio.get('/activities/$quizId');
      print("Quiz.response: ${response.data}");
      final quiz = Quiz.fromJson(response.data);
      print("here: $quiz");

      //await _cacheQuiz(quiz);

      return quiz;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        final cachedQuiz = await _getCachedQuiz(quizId);
        if (cachedQuiz != null) {
          return cachedQuiz;
        }
      }

      if (e.error is AppException) {
        throw e.error as AppException;
      }
      throw AppException(message: 'Erreur lors du chargement du quiz');
    }
  }

  Future<List<QuizAttempt>> getQuizAttempts(String quizId) async {
    try {
      final response =
          await _dio.get('/students/quiz-attempts?activityId=$quizId');
      final attempts = (response.data as List)
          .map((json) => QuizAttempt.fromJson(json))
          .toList();
      await _cacheQuizAttempts(quizId, attempts);

      return attempts;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        final cachedAttempts = await _getCachedQuizAttempts(quizId);
        return cachedAttempts;
      }

      if (e.error is AppException) {
        throw e.error as AppException;
      }
      throw AppException(message: 'Erreur lors du chargement des tentatives');
    }
  }

  Future<QuizAttempt> submitQuizAttempt(QuizAttempt attempt) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOffline = connectivityResult.contains(ConnectivityResult.none);

      if (isOffline) {
        await _savePendingSubmission(attempt);

        final updatedAttempt = attempt.copyWith(
          status: 'completed',
          endDate: DateTime.now(),
          isSubmitted: true,
          isSynchronized: false,
        );

        await _updateCachedQuizAttempt(updatedAttempt);

        return updatedAttempt;
      } else {
        final response = await _dio.post(
          '/students/quiz-attempts/submit',
          data: attempt.toJson(),
        );

        final submittedAttempt = QuizAttempt.fromJson(response.data);
        await _updateCachedQuizAttempt(submittedAttempt);

        return submittedAttempt;
      }
    } on DioException {
      await _savePendingSubmission(attempt);

      final updatedAttempt = attempt.copyWith(
        status: 'completed',
        endDate: DateTime.now(),
        isSubmitted: true,
        isSynchronized: false,
      );
      await _updateCachedQuizAttempt(updatedAttempt);

      return updatedAttempt;
    }
  }

  Future<StudentAnswer> addStudentAnswer(StudentAnswer answer) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOffline = connectivityResult.contains(ConnectivityResult.none);

      if (isOffline) {
        final cachedAttempts =
            await _getCachedQuizAttempts(answer.quizAttemptId);

        final attemptIndex =
            cachedAttempts.indexWhere((a) => a.id == answer.quizAttemptId);

        if (attemptIndex >= 0) {
          final attempt = cachedAttempts[attemptIndex];

          final existingAnswerIndex = attempt.studentAnswers
              .indexWhere((a) => a.questionId == answer.questionId);

          if (existingAnswerIndex >= 0) {
            final updatedAnswers =
                List<StudentAnswer>.from(attempt.studentAnswers);
            updatedAnswers[existingAnswerIndex] = answer;

            final updatedAttempt = attempt.copyWith(
              studentAnswers: updatedAnswers,
              updatedAt: DateTime.now(),
            );

            cachedAttempts[attemptIndex] = updatedAttempt;
            await _cacheQuizAttempts(answer.quizAttemptId, cachedAttempts);
          } else {
            // Nouvelle réponse
            final updatedAnswers =
                List<StudentAnswer>.from(attempt.studentAnswers)..add(answer);

            final updatedAttempt = attempt.copyWith(
              studentAnswers: updatedAnswers,
              updatedAt: DateTime.now(),
            );

            cachedAttempts[attemptIndex] = updatedAttempt;
            await _cacheQuizAttempts(answer.quizAttemptId, cachedAttempts);
          }
        }

        return answer;
      } else {
        // En ligne, soumettre directement
        final response = await _dio.post(
          '/students/quiz-attempts/answers',
          data: answer.toJson(),
        );

        final serverAnswer = StudentAnswer.fromJson(response.data);

        // Mise à jour du cache
        final cachedAttempts =
            await _getCachedQuizAttempts(answer.quizAttemptId);

        final attemptIndex =
            cachedAttempts.indexWhere((a) => a.id == answer.quizAttemptId);

        if (attemptIndex >= 0) {
          final attempt = cachedAttempts[attemptIndex];

          // Vérifier si la réponse existe déjà
          final existingAnswerIndex = attempt.studentAnswers
              .indexWhere((a) => a.questionId == answer.questionId);

          if (existingAnswerIndex >= 0) {
            // Mise à jour d'une réponse existante
            final updatedAnswers =
                List<StudentAnswer>.from(attempt.studentAnswers);
            updatedAnswers[existingAnswerIndex] = serverAnswer;

            final updatedAttempt = attempt.copyWith(
              studentAnswers: updatedAnswers,
              updatedAt: DateTime.now(),
            );

            cachedAttempts[attemptIndex] = updatedAttempt;
            await _cacheQuizAttempts(answer.quizAttemptId, cachedAttempts);
          } else {
            // Nouvelle réponse
            final updatedAnswers =
                List<StudentAnswer>.from(attempt.studentAnswers)
                  ..add(serverAnswer);

            final updatedAttempt = attempt.copyWith(
              studentAnswers: updatedAnswers,
              updatedAt: DateTime.now(),
            );

            cachedAttempts[attemptIndex] = updatedAttempt;
            await _cacheQuizAttempts(answer.quizAttemptId, cachedAttempts);
          }
        }

        return serverAnswer;
      }
    } catch (e) {
      // En cas d'erreur, sauvegarder localement
      final cachedAttempts = await _getCachedQuizAttempts(answer.quizAttemptId);

      final attemptIndex =
          cachedAttempts.indexWhere((a) => a.id == answer.quizAttemptId);

      if (attemptIndex >= 0) {
        final attempt = cachedAttempts[attemptIndex];

        // Vérifier si la réponse existe déjà
        final existingAnswerIndex = attempt.studentAnswers
            .indexWhere((a) => a.questionId == answer.questionId);

        if (existingAnswerIndex >= 0) {
          // Mise à jour d'une réponse existante
          final updatedAnswers =
              List<StudentAnswer>.from(attempt.studentAnswers);
          updatedAnswers[existingAnswerIndex] = answer;

          final updatedAttempt = attempt.copyWith(
            studentAnswers: updatedAnswers,
            updatedAt: DateTime.now(),
          );

          cachedAttempts[attemptIndex] = updatedAttempt;
          await _cacheQuizAttempts(answer.quizAttemptId, cachedAttempts);
        } else {
          // Nouvelle réponse
          final updatedAnswers =
              List<StudentAnswer>.from(attempt.studentAnswers)..add(answer);

          final updatedAttempt = attempt.copyWith(
            studentAnswers: updatedAnswers,
            updatedAt: DateTime.now(),
          );

          cachedAttempts[attemptIndex] = updatedAttempt;
          await _cacheQuizAttempts(answer.quizAttemptId, cachedAttempts);
        }
      }

      return answer;
    }
  }

  // Créer une nouvelle tentative de quiz
  Future<QuizAttempt> createQuizAttempt(String quizId) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOffline = connectivityResult.contains(ConnectivityResult.none);

      if (isOffline) {
        // En mode hors ligne, créer une tentative locale
        final quiz = await _getCachedQuiz(quizId);
        if (quiz == null) {
          throw AppException(message: 'Quiz non disponible hors ligne');
        }

        final attempt = QuizAttempt.create(quiz);

        // Enregistrer dans le cache
        final attempts = await _getCachedQuizAttempts(quizId);
        attempts.add(attempt);
        await _cacheQuizAttempts(quizId, attempts);

        return attempt;
      } else {
        // En ligne, créer une tentative sur le serveur
        final response = await _dio.post(
          '/students/quiz-attempts',
          data: {'quizId': quizId},
        );

        final attempt = QuizAttempt.fromJson(response.data);

        // Mettre à jour le cache
        final attempts = await _getCachedQuizAttempts(quizId);
        attempts.add(attempt);
        await _cacheQuizAttempts(quizId, attempts);

        return attempt;
      }
    } catch (e) {
      // En cas d'erreur, créer une tentative locale
      try {
        final quiz = await _getCachedQuiz(quizId);
        if (quiz == null) {
          throw AppException(message: 'Quiz non disponible');
        }

        final attempt = QuizAttempt.create(quiz);

        // Enregistrer dans le cache
        final attempts = await _getCachedQuizAttempts(quizId);
        attempts.add(attempt);
        await _cacheQuizAttempts(quizId, attempts);

        return attempt;
      } catch (e) {
        throw AppException(
            message: 'Erreur lors de la création de la tentative');
      }
    }
  }

  // Synchroniser les tentatives en attente
  Future<void> syncPendingSubmissions() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOffline = connectivityResult.contains(ConnectivityResult.none);

      if (isOffline) {
        return; // Ne pas synchroniser en mode hors ligne
      }

      final pendingSubmissions = await _getPendingSubmissions();

      for (final attempt in pendingSubmissions) {
        try {
          // Soumettre la tentative
          final response = await _dio.post(
            '/students/quiz-attempts/submit',
            data: attempt.toJson(),
          );

          final submittedAttempt = QuizAttempt.fromJson(response.data);

          // Mettre à jour dans le cache
          await _updateCachedQuizAttempt(submittedAttempt);

          // Supprimer des soumissions en attente
          await _removePendingSubmission(attempt.id);
        } catch (e) {
          // Ignorer les erreurs pour continuer avec les autres tentatives
          continue;
        }
      }
    } catch (e) {
      // Ignorer les erreurs
    }
  }

  // Télécharger un quiz pour une utilisation hors ligne
  Future<Quiz> downloadQuizForOffline(String quizId) async {
    try {
      final quiz = await getQuiz(quizId);

      // Marquer comme téléchargé
      final downloadedQuiz = quiz.copyWith(isDownloaded: true);
      await _cacheQuiz(downloadedQuiz);

      return downloadedQuiz;
    } catch (e) {
      throw AppException(message: 'Erreur lors du téléchargement du quiz');
    }
  }

  // Vérifier si un quiz est téléchargé
  Future<bool> isQuizDownloaded(String quizId) async {
    final quiz = await _getCachedQuiz(quizId);
    return quiz?.isDownloaded ?? false;
  }

  // Supprimer un quiz téléchargé
  Future<void> removeDownloadedQuiz(String quizId) async {
    final quiz = await _getCachedQuiz(quizId);
    if (quiz != null) {
      final updatedQuiz = quiz.copyWith(isDownloaded: false);
      await _cacheQuiz(updatedQuiz);
    }
  }

  // Méthodes de cache
  Future<void> _cacheQuiz(Quiz quiz) async {
    await _storage.saveData(_getQuizKey(quiz.id), quiz.toJson());
  }

  Future<Quiz?> _getCachedQuiz(String quizId) async {
    try {
      final data = await _storage.getData(_getQuizKey(quizId));
      if (data != null) {
        return Quiz.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheQuizAttempts(
      String quizId, List<QuizAttempt> attempts) async {
    final attemptsJson = attempts.map((attempt) => attempt.toJson()).toList();
    await _storage.saveData(_getQuizAttemptsKey(quizId), attemptsJson);
  }

  Future<List<QuizAttempt>> _getCachedQuizAttempts(String quizId) async {
    try {
      final data = await _storage.getData(_getQuizAttemptsKey(quizId));
      if (data != null) {
        return (data as List)
            .map((json) => QuizAttempt.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _updateCachedQuizAttempt(QuizAttempt attempt) async {
    final attempts = await _getCachedQuizAttempts(attempt.quizId);

    final index = attempts.indexWhere((a) => a.id == attempt.id);
    if (index >= 0) {
      attempts[index] = attempt;
    } else {
      attempts.add(attempt);
    }

    await _cacheQuizAttempts(attempt.quizId, attempts);
  }

  Future<void> _savePendingSubmission(QuizAttempt attempt) async {
    final pendingSubmissions = await _getPendingSubmissions();

    final index = pendingSubmissions.indexWhere((a) => a.id == attempt.id);
    if (index >= 0) {
      pendingSubmissions[index] = attempt;
    } else {
      pendingSubmissions.add(attempt);
    }

    final submissionsJson =
        pendingSubmissions.map((sub) => sub.toJson()).toList();
    await _storage.saveData(_getPendingSubmissionsKey(), submissionsJson);
  }

  Future<void> _removePendingSubmission(String attemptId) async {
    final pendingSubmissions = await _getPendingSubmissions();

    final filteredSubmissions =
        pendingSubmissions.where((a) => a.id != attemptId).toList();

    final submissionsJson =
        filteredSubmissions.map((sub) => sub.toJson()).toList();
    await _storage.saveData(_getPendingSubmissionsKey(), submissionsJson);
  }

  Future<List<QuizAttempt>> _getPendingSubmissions() async {
    try {
      final data = await _storage.getData(_getPendingSubmissionsKey());
      if (data != null) {
        return (data as List)
            .map((json) => QuizAttempt.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
