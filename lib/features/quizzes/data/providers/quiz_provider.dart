import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/exceptions/app_exception.dart';
import '../../models/quiz.dart';
import '../../models/quiz_attempt.dart';
import '../../models/student_answer.dart';
import '../quiz_repository.dart';

class QuizProvider with ChangeNotifier {
  final QuizRepository _repository = QuizRepository();

  // État
  Quiz? _currentQuiz;
  QuizAttempt? _currentAttempt;
  List<QuizAttempt> _attempts = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  int _remainingTime = 0; // En secondes
  bool _isDownloaded = false;

  // Getters
  Quiz? get currentQuiz => _currentQuiz;
  QuizAttempt? get currentAttempt => _currentAttempt;
  List<QuizAttempt> get attempts => _attempts;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  int get remainingTime => _remainingTime;
  bool get isDownloaded => _isDownloaded;

  // Calcul des propriétés dérivées
  bool get hasCurrentQuiz => _currentQuiz != null;
  bool get hasCurrentAttempt => _currentAttempt != null;
  bool get hasError => _error != null;
  bool get canSubmit => _currentAttempt?.canSubmit ?? false;
  bool get isQuizExpired => _currentQuiz?.isExpired ?? false;
  bool get isAttemptInProgress => _currentAttempt?.isInProgress ?? false;

  // Nombre de questions répondues
  int get answeredQuestionsCount {
    if (_currentAttempt == null) return 0;
    return _currentAttempt!.studentAnswers.length;
  }

  // Pourcentage de progression
  double get progressPercentage {
    if (_currentQuiz == null || _currentAttempt == null) return 0.0;
    return answeredQuestionsCount / _currentQuiz!.questions.length;
  }

  // Méthodes pour le chargement des données
  Future<void> loadQuiz(String quizId, {bool forceRefresh = false}) async {
    _setLoading(true);
    _clearError();

    try {
      _currentQuiz =
          await _repository.getQuiz(quizId, forceRefresh: forceRefresh);
      _isDownloaded = await _repository.isQuizDownloaded(quizId);
      notifyListeners();
    } on AppException catch (e) {
      _setError(e.toString());
    } catch (e) {
      _setError('Erreur lors du chargement du quiz');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadQuizAttempts(String quizId) async {
    _setLoading(true);
    _clearError();

    try {
      _attempts = await _repository.getQuizAttempts(quizId);

      // Trouver une tentative en cours si elle existe
      final inProgressAttempt = _attempts.firstWhere(
        (attempt) => attempt.isInProgress,
        orElse: () => QuizAttempt(
          id: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          active: false,
          quizId: '',
          startDate: DateTime.now(),
          timeSpent: 0,
          score: 0,
          status: '',
          studentAnswers: [],
        ),
      );

      if (inProgressAttempt.id.isNotEmpty) {
        _currentAttempt = inProgressAttempt;
      }

      notifyListeners();
    } on AppException catch (e) {
      _setError(e.toString());
    } catch (e) {
      _setError('Erreur lors du chargement des tentatives');
    } finally {
      _setLoading(false);
    }
  }

  // Méthodes de gestion des tentatives
  Future<void> startQuizAttempt(String quizId) async {
    _setLoading(true);
    _clearError();

    try {
      _currentAttempt = await _repository.createQuizAttempt(quizId);

      // Ajouter la tentative à la liste
      _attempts = [_currentAttempt!, ..._attempts];

      // Initialiser le temps restant
      if (_currentQuiz != null) {
        _remainingTime = _currentQuiz!.duration * 60; // Convertir en secondes
      }

      notifyListeners();
    } on AppException catch (e) {
      _setError(e.toString());
    } catch (e) {
      _setError('Erreur lors de la création de la tentative');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitQuizAttempt() async {
    if (_currentAttempt == null) return;

    _isSubmitting = true;
    _clearError();
    notifyListeners();

    try {
      final submittedAttempt =
          await _repository.submitQuizAttempt(_currentAttempt!);

      // Mettre à jour les tentatives
      final index = _attempts.indexWhere((a) => a.id == _currentAttempt!.id);
      if (index >= 0) {
        _attempts[index] = submittedAttempt;
      }

      _currentAttempt = submittedAttempt;

      notifyListeners();
    } on AppException catch (e) {
      _setError(e.toString());
    } catch (e) {
      _setError('Erreur lors de la soumission du quiz');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // Ajouter ou mettre à jour une réponse
  Future<void> saveStudentAnswer({
    required String questionId,
    String? answerId,
    String? textAnswer,
  }) async {
    if (_currentAttempt == null) return;

    try {
      // Créer ou mettre à jour la réponse
      final answer = StudentAnswer.create(
        questionId: questionId,
        answerId: answerId,
        quizAttemptId: _currentAttempt!.id,
        textAnswer: textAnswer,
      );

      final savedAnswer = await _repository.addStudentAnswer(answer);

      // Mettre à jour la tentative courante
      final existingAnswerIndex = _currentAttempt!.studentAnswers
          .indexWhere((a) => a.questionId == questionId);

      if (existingAnswerIndex >= 0) {
        // Mise à jour d'une réponse existante
        final updatedAnswers =
            List<StudentAnswer>.from(_currentAttempt!.studentAnswers);
        updatedAnswers[existingAnswerIndex] = savedAnswer;

        _currentAttempt = _currentAttempt!.copyWith(
          studentAnswers: updatedAnswers,
          updatedAt: DateTime.now(),
        );
      } else {
        // Nouvelle réponse
        final updatedAnswers =
            List<StudentAnswer>.from(_currentAttempt!.studentAnswers)
              ..add(savedAnswer);

        _currentAttempt = _currentAttempt!.copyWith(
          studentAnswers: updatedAnswers,
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();
    } catch (e) {
      // Ignorer les erreurs, l'utilisateur pourra réessayer
    }
  }

  // Mettre à jour le temps restant
  void updateRemainingTime(int seconds) {
    if (_remainingTime != seconds) {
      _remainingTime = seconds;
      notifyListeners();
    }
  }

  // Synchroniser les tentatives en attente
  Future<void> syncPendingSubmissions() async {
    try {
      await _repository.syncPendingSubmissions();

      // Recharger les tentatives si un quiz est chargé
      if (_currentQuiz != null) {
        await loadQuizAttempts(_currentQuiz!.id);
      }
    } catch (e) {
      // Ignorer les erreurs
    }
  }

  // Télécharger un quiz pour une utilisation hors ligne
  Future<void> downloadQuizForOffline(String quizId) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.downloadQuizForOffline(quizId);
      _isDownloaded = true;
      notifyListeners();
    } on AppException catch (e) {
      _setError(e.toString());
    } catch (e) {
      _setError('Erreur lors du téléchargement du quiz');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> isQuizDownloaded(String quizId) async {
    try {
      return await _repository.isQuizDownloaded(quizId);
    } catch (e) {
      return false;
    }
  }

  // Supprimer un quiz téléchargé
  Future<void> removeDownloadedQuiz(String quizId) async {
    try {
      await _repository.removeDownloadedQuiz(quizId);
      _isDownloaded = false;
      notifyListeners();
    } catch (e) {
      // Ignorer les erreurs
    }
  }

  // Helpers
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

  // Obtenir la réponse pour une question spécifique
  StudentAnswer? getStudentAnswerForQuestion(String questionId) {
    if (_currentAttempt == null) return null;

    try {
      return _currentAttempt!.studentAnswers
          .firstWhere((answer) => answer.questionId == questionId);
    } catch (e) {
      return null;
    }
  }

  // Obtenir l'ID de la réponse sélectionnée pour une question
  String? getSelectedAnswerId(String questionId) {
    final studentAnswer = getStudentAnswerForQuestion(questionId);
    return studentAnswer?.answerId;
  }

  // Obtenir la réponse textuelle pour une question
  String? getTextAnswer(String questionId) {
    final studentAnswer = getStudentAnswerForQuestion(questionId);
    return studentAnswer?.textAnswer;
  }

  // Vérifier si une question a été répondue
  bool isQuestionAnswered(String questionId) {
    return getStudentAnswerForQuestion(questionId) != null;
  }

  // Formater le temps restant en mm:ss
  String get formattedRemainingTime {
    final minutes = _remainingTime ~/ 60;
    final seconds = _remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Vérifier si le temps est bientôt écoulé (moins de 5 minutes)
  bool get isTimeAlmostUp {
    return _remainingTime <= 300; // 5 minutes en secondes
  }

  // Vérifier si le temps est critique (moins de 1 minute)
  bool get isCriticalTime {
    return _remainingTime <= 60; // 1 minute en secondes
  }
}
