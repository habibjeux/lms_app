import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../../core/services/offline_storage_service.dart';
import '../models/quiz.dart';
import '../models/quiz_attempt.dart';
import '../models/student_answer.dart';

class QuizRepository {
  final Dio _api = ApiClient.instance;
  final OfflineStorageService _offlineStorage = OfflineStorageService();

  // Récupérer un quiz par son ID
  Future<Quiz> getQuiz(String quizId) async {
    try {
      final response = await _api.get('/quizzes/$quizId');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is! Map<String, dynamic>) {
          throw AppException(message: 'Format de réponse invalide');
        }

        // Fusionner les données de l'activité avec les données du quiz
        final quizData = Map<String, dynamic>.from(data);
        if (data['quiz'] != null && data['quiz'] is Map<String, dynamic>) {
          quizData.addAll(data['quiz']);
        }

        return Quiz.fromJson(quizData);
      } else {
        throw AppException(message: 'Quiz non trouvé');
      }
    } catch (e) {
      // Essayer de récupérer depuis le cache local
      final cachedQuiz = await _getQuizFromCache(quizId);
      if (cachedQuiz != null) {
        return cachedQuiz;
      }

      if (e is AppException) {
        rethrow;
      }
      throw AppException(message: 'Erreur lors du chargement du quiz: $e');
    }
  }

  // Sauvegarder un quiz en cache
  Future<void> saveQuizToCache(Quiz quiz) async {
    try {
      await _offlineStorage.saveQuiz(quiz.id, quiz.toJson());
    } catch (e) {
      print('Erreur lors de la sauvegarde du quiz en cache: $e');
    }
  }

  // Récupérer un quiz depuis le cache
  Future<Quiz?> _getQuizFromCache(String quizId) async {
    try {
      final cachedData = await _offlineStorage.getQuiz(quizId);
      if (cachedData != null) {
        // S'assurer que cachedData est du bon type
        Map<String, dynamic> quizData;
        quizData = cachedData;
        return Quiz.fromJson(quizData);
      }
    } catch (e) {
      print('Erreur lors de la récupération du quiz depuis le cache: $e');
    }
    return null;
  }

  // Vérifier si un quiz est téléchargé
  Future<bool> isQuizDownloaded(String quizId) async {
    final cachedQuiz = await _getQuizFromCache(quizId);
    return cachedQuiz != null;
  }

  // Commencer une tentative de quiz
  Future<QuizAttempt> startQuizAttempt(String quizId) async {
    try {
      final response = await _api.post('/students/quiz-attempts', data: {
        'quizId': quizId,
        'startDate': DateTime.now().toIso8601String(),
      });

      print('🚀 startQuizAttempt response status: ${response.statusCode}');
      print('🚀 startQuizAttempt response data: ${response.data}');

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final quizAttempt = QuizAttempt.fromJson(response.data);
        print('🚀 QuizAttempt créé: ${quizAttempt.id}');
        return quizAttempt;
      } else {
        throw AppException(
            message:
                'Impossible de démarrer le quiz - Status: ${response.statusCode}');
      }
    } catch (e) {
      print('🚀 Erreur dans startQuizAttempt: $e');
      if (e is AppException) {
        rethrow;
      }
      throw AppException(message: 'Erreur lors du démarrage du quiz: $e');
    }
  }

  // Sauvegarder une réponse d'étudiant
  Future<void> saveStudentAnswer(StudentAnswer answer) async {
    try {
      await _api.post('/students/quiz-attempts/answers', data: answer.toJson());
    } catch (e) {
      // En cas d'erreur, sauvegarder localement pour synchronisation ultérieure
      await _saveAnswerLocally(answer);
      // Extraire le message d'erreur spécifique du serveur si disponible
      String errorMessage = 'Erreur lors de la sauvegarde de la réponse';

      if (e is DioException && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['error'] ??
              responseData['message'] ??
              responseData['detail'] ??
              'Erreur lors de la sauvegarde de la réponse';
        } else if (responseData is String) {
          errorMessage = responseData;
        }
      } else if (e is Exception) {
        final exceptionMessage = e.toString();
        if (exceptionMessage.startsWith('Exception: ')) {
          errorMessage = exceptionMessage.substring(11);
        } else {
          errorMessage = exceptionMessage;
        }
      }

      throw AppException(message: errorMessage);
    }
  }

  // Sauvegarder une réponse simple (SCQ, TRUE_FALSE, SHORT_ANSWER)
  Future<void> saveAnswer(String attemptId, String questionId,
      {String? answerId, String? textAnswer}) async {
    try {
      await _api.post('/students/quiz-attempts/answers', data: {
        'quizAttemptId': attemptId,
        'questionId': questionId,
        if (answerId != null) 'answerId': answerId,
        if (textAnswer != null) 'textAnswer': textAnswer,
      });
    } catch (e) {
      // Extraire le message d'erreur spécifique du serveur si disponible
      String errorMessage = 'Erreur lors de la sauvegarde de la réponse';

      if (e is DioException && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['error'] ??
              responseData['message'] ??
              responseData['detail'] ??
              'Erreur lors de la sauvegarde de la réponse';
        } else if (responseData is String) {
          errorMessage = responseData;
        }
      } else if (e is Exception) {
        final exceptionMessage = e.toString();
        if (exceptionMessage.startsWith('Exception: ')) {
          errorMessage = exceptionMessage.substring(11);
        } else {
          errorMessage = exceptionMessage;
        }
      }

      throw AppException(message: errorMessage);
    }
  }

  // Sauvegarder des réponses multiples (MCQ)
  Future<void> saveMultipleAnswer(
      String attemptId, String questionId, List<String> answerIds) async {
    try {
      await _api.post('/students/quiz-attempts/answers', data: {
        'quizAttemptId': attemptId,
        'questionId': questionId,
        'answerIds': answerIds,
      });
    } catch (e) {
      // Extraire le message d'erreur spécifique du serveur si disponible
      String errorMessage = 'Erreur lors de la sauvegarde des réponses';

      if (e is DioException && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['error'] ??
              responseData['message'] ??
              responseData['detail'] ??
              'Erreur lors de la sauvegarde des réponses';
        } else if (responseData is String) {
          errorMessage = responseData;
        }
      } else if (e is Exception) {
        final exceptionMessage = e.toString();
        if (exceptionMessage.startsWith('Exception: ')) {
          errorMessage = exceptionMessage.substring(11);
        } else {
          errorMessage = exceptionMessage;
        }
      }

      throw AppException(message: errorMessage);
    }
  }

  // Sauvegarder une réponse localement
  Future<void> _saveAnswerLocally(StudentAnswer answer) async {
    try {
      // Implémenter la sauvegarde locale pour synchronisation ultérieure
      // Vous pouvez utiliser Hive ou une autre solution de stockage local
    } catch (e) {
      print('Erreur lors de la sauvegarde locale de la réponse: $e');
    }
  }

  // Soumettre une tentative de quiz
  Future<QuizAttempt> submitQuizAttempt(
      String attemptId, List<StudentAnswer> answers) async {
    try {
      // Calculer le score total
      double totalScore =
          answers.fold(0.0, (sum, answer) => sum + answer.score);

      print('🎯 Soumission quiz - attemptId: $attemptId');
      print('🎯 Soumission quiz - answers count: ${answers.length}');
      print('🎯 Soumission quiz - totalScore: $totalScore');

      // Log des scores individuels pour debug
      for (final answer in answers) {
        print(
            '🎯 Question ${answer.questionId}: Score ${answer.score}, Correct: ${answer.isCorrect}');
      }

      final response = await _api.post('/students/quiz-attempts/submit', data: {
        'id': attemptId, // Le backend attend 'id', pas 'attemptId'
        'answers': answers.map((answer) => answer.toJson()).toList(),
        'totalScore': totalScore,
        'endDate': DateTime.now().toIso8601String(),
      });

      if (response.statusCode == 200 && response.data != null) {
        final submittedAttempt = QuizAttempt.fromJson(response.data);
        print(
            '🎯 Quiz soumis avec succès - Score final: ${submittedAttempt.score}');
        return submittedAttempt;
      } else {
        throw AppException(message: 'Erreur lors de la soumission du quiz');
      }
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }

      // Extraire le message d'erreur spécifique du serveur si disponible
      String errorMessage = 'Erreur lors de la soumission du quiz';

      if (e is DioException && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['error'] ??
              responseData['message'] ??
              responseData['detail'] ??
              'Erreur lors de la soumission du quiz';
        } else if (responseData is String) {
          errorMessage = responseData;
        }
      } else if (e is Exception) {
        final exceptionMessage = e.toString();
        if (exceptionMessage.startsWith('Exception: ')) {
          errorMessage = exceptionMessage.substring(11);
        } else {
          errorMessage = exceptionMessage;
        }
      }

      throw AppException(message: errorMessage);
    }
  }

  // Récupérer les tentatives d'un étudiant pour un quiz
  Future<List<QuizAttempt>> getStudentAttempts(String quizId) async {
    try {
      final response = await _api.get('/students/quiz-attempts',
          queryParameters: {'activityId': quizId});

      if (response.statusCode == 200 && response.data != null) {
        // La réponse est directement une liste
        if (response.data is List) {
          final List<dynamic> attemptsData = response.data;
          return attemptsData
              .map((data) => QuizAttempt.fromJson(data))
              .toList();
        } else if (response.data is Map && response.data['data'] is List) {
          final List<dynamic> attemptsData = response.data['data'];
          return attemptsData
              .map((data) => QuizAttempt.fromJson(data))
              .toList();
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      print('Erreur lors de la récupération des tentatives: $e');
      return [];
    }
  }

  // Récupérer une tentative spécifique
  Future<QuizAttempt?> getQuizAttempt(String attemptId) async {
    try {
      final response = await _api.get('/students/quiz-attempts/$attemptId');

      if (response.statusCode == 200 && response.data != null) {
        return QuizAttempt.fromJson(response.data);
      }
    } catch (e) {
      print('Erreur lors de la récupération de la tentative: $e');
    }
    return null;
  }

  // Supprimer le cache d'un quiz
  Future<void> deleteQuizCache(String quizId) async {
    try {
      // Implémenter la suppression du cache
      // Vous pouvez utiliser la méthode appropriée de votre service de stockage
    } catch (e) {
      print('Erreur lors de la suppression du cache du quiz: $e');
    }
  }
}
