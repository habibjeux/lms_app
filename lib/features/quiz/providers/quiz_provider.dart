import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/services/sync_service.dart';
import '../data/quiz_repository.dart';
import '../models/quiz.dart';
import '../models/quiz_attempt.dart';
import '../models/student_answer.dart';
import '../models/question.dart';

class QuizProvider with ChangeNotifier {
  final QuizRepository _repository = QuizRepository();
  final SyncService _syncService = SyncService();

  // État du quiz
  Quiz? _currentQuiz;
  QuizAttempt? _currentAttempt;
  List<StudentAnswer> _studentAnswers = [];
  List<QuizAttempt> _attempts = [];

  // État de l'interface
  bool _isLoading = false;
  bool _isDownloading = false;
  bool _isSubmitting = false;
  String? _error;
  int _currentQuestionIndex = 0;
  DateTime? _startTime;
  double _downloadProgress = 0.0;
  Timer? _timer;

  // Getters
  Quiz? get currentQuiz => _currentQuiz;
  QuizAttempt? get currentAttempt => _currentAttempt;
  List<StudentAnswer> get studentAnswers => _studentAnswers;
  List<QuizAttempt> get attempts => _attempts;
  bool get isLoading => _isLoading;
  bool get isDownloading => _isDownloading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  int get currentQuestionIndex => _currentQuestionIndex;
  DateTime? get startTime => _startTime;
  double get downloadProgress => _downloadProgress;

  // Getters calculés
  Question? get currentQuestion {
    if (_currentQuiz == null ||
        _currentQuestionIndex >= _currentQuiz!.questions.length) {
      return null;
    }
    return _currentQuiz!.questions[_currentQuestionIndex];
  }

  int get totalQuestions => _currentQuiz?.questions.length ?? 0;
  int get answeredQuestions => _studentAnswers.where((a) => a.hasAnswer).length;
  bool get isLastQuestion => _currentQuestionIndex >= totalQuestions - 1;
  bool get isFirstQuestion => _currentQuestionIndex == 0;

  Duration? get remainingTime {
    if (_startTime == null || _currentQuiz == null) return null;
    final elapsed = DateTime.now().difference(_startTime!);
    final total = Duration(minutes: _currentQuiz!.duration);
    final remaining = total - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isTimeUp => remainingTime?.inSeconds == 0;

  int get timeSpentInSeconds {
    if (_startTime == null) return 0;
    return DateTime.now().difference(_startTime!).inSeconds;
  }

  // Charger un quiz
  Future<void> loadQuiz(String quizId) async {
    _setLoading(true);
    _clearError();

    try {
      _currentQuiz = await _repository.getQuiz(quizId);
      await _loadAttempts(quizId);
      _initializeStudentAnswers();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Télécharger un quiz pour utilisation hors ligne
  Future<void> downloadQuizForOffline(String quizId) async {
    _setDownloading(true);
    _downloadProgress = 0.0;

    try {
      // Simuler le progrès de téléchargement
      for (int i = 0; i <= 100; i += 10) {
        _downloadProgress = i / 100;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await _syncService.downloadQuiz(
        quizId,
        moduleId: _currentQuiz?.moduleId ?? '',
        chapterId: _currentQuiz?.chapterId,
        title: _currentQuiz?.title ?? '',
      );

      if (_currentQuiz != null) {
        await _repository.saveQuizToCache(_currentQuiz!);
      }

      _downloadProgress = 1.0;
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du téléchargement: $e');
    } finally {
      _setDownloading(false);
    }
  }

  // Vérifier si un quiz est téléchargé
  Future<bool> isQuizDownloaded(String quizId) async {
    return await _repository.isQuizDownloaded(quizId);
  }

  // Commencer une tentative de quiz
  Future<void> startQuizAttempt() async {
    print('🚀 startQuizAttempt() appelé');
    if (_currentQuiz == null) {
      print('🚀 Erreur: quiz null');
      _setError('Aucun quiz chargé');
      return;
    }

    print('🚀 Quiz ID: ${_currentQuiz!.id}');
    _setLoading(true);
    _clearError();

    try {
      print('🚀 Appel repository.startQuizAttempt...');
      _currentAttempt = await _repository.startQuizAttempt(_currentQuiz!.id);
      print('🚀 _currentAttempt reçu: ${_currentAttempt?.id}');
      _startTime = DateTime.now();
      _currentQuestionIndex = 0;
      _initializeStudentAnswers();
      _startTimer(); // Démarrer le timer
      notifyListeners();
    } catch (e) {
      print('🚀 Exception dans startQuizAttempt: $e');
      // Si l'erreur est liée au nombre maximum de tentatives,
      // empêcher complètement l'accès au lieu du mode démonstration
      if (e.toString().contains('nombre maximum de tentatives') ||
          e.toString().contains('maximum attempts') ||
          e.toString().contains('tentatives autorisées')) {
        _setError(
            'Vous avez atteint le nombre maximum de tentatives autorisées pour ce quiz.');
        return;
      } else {
        _setError(e.toString());
      }
    } finally {
      _setLoading(false);
    }
  }

  // Démarrer le timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isTimeUp) {
        timer.cancel();
        // Soumettre automatiquement le quiz quand le temps est écoulé
        _autoSubmitQuiz();
      }
      notifyListeners();
    });
  }

  // Soumission automatique quand le temps est écoulé
  Future<void> _autoSubmitQuiz() async {
    if (_currentAttempt == null || _isSubmitting) return;

    print('⏰ Temps écoulé - Soumission automatique du quiz');
    _setError('Temps écoulé ! Le quiz a été soumis automatiquement.');
    await submitQuiz();
  }

  // Initialiser les réponses d'étudiant
  void _initializeStudentAnswers() {
    print('🔧 _initializeStudentAnswers appelée');
    print('🔧 _currentQuiz: ${_currentQuiz != null}');
    print('🔧 _currentAttempt: ${_currentAttempt != null}');

    if (_currentQuiz == null || _currentAttempt == null) {
      print('❌ Quiz ou tentative null, arrêt de l\'initialisation');
      return;
    }

    print('🔧 Nombre de questions: ${_currentQuiz!.questions.length}');

    _studentAnswers = _currentQuiz!.questions.map((question) {
      final studentAnswer = StudentAnswer(
        id: '${_currentAttempt!.id}_${question.id}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        active: true,
        questionId: question.id,
        quizAttemptId: _currentAttempt!.id,
        answerId: null,
        selectedAnswerIds: [],
        textAnswer: null,
        score: 0.0,
        isCorrect: false,
      );

      print(
          '🔧 StudentAnswer créée pour question ${question.id}: ${studentAnswer.id}');
      return studentAnswer;
    }).toList();

    print('🔧 Total StudentAnswers créées: ${_studentAnswers.length}');

    // Afficher les IDs des questions et des StudentAnswers
    for (int i = 0; i < _studentAnswers.length; i++) {
      print(
          '🔧 StudentAnswer[$i]: questionId=${_studentAnswers[i].questionId}');
    }

    // Notifier les changements
    notifyListeners();
  }

  // Forcer l'initialisation des réponses d'étudiant
  void _forceInitializeStudentAnswers() {
    print('💥 FORÇAGE BRUTAL de l\'initialisation');
    print('💥 Quiz questions: ${_currentQuiz?.questions.length}');
    print('💥 Attempt ID: ${_currentAttempt?.id}');

    if (_currentQuiz == null || _currentAttempt == null) {
      print('💥 ÉCHEC - Quiz ou tentative null');
      return;
    }

    _studentAnswers.clear(); // Vider d'abord

    for (final question in _currentQuiz!.questions) {
      final studentAnswer = StudentAnswer(
        id: 'force_${_currentAttempt!.id}_${question.id}_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        active: true,
        questionId: question.id,
        quizAttemptId: _currentAttempt!.id,
        answerId: null,
        selectedAnswerIds: [],
        textAnswer: null,
        score: 0.0,
        isCorrect: false,
      );

      _studentAnswers.add(studentAnswer);
      print(
          '💥 FORCÉ: StudentAnswer pour ${question.id} → ${studentAnswer.id}');
    }

    print('💥 TERMINÉ: ${_studentAnswers.length} StudentAnswers créées');
    notifyListeners();
  }

  // Sauvegarder une réponse
  Future<void> saveAnswer(
    String questionId, {
    List<String>? selectedAnswerIds,
    String? textAnswer,
  }) async {
    print('🔄 saveAnswer appelé pour question: $questionId');
    print('🔄 selectedAnswerIds: $selectedAnswerIds');
    print('🔄 textAnswer: $textAnswer');

    // FORCER l'initialisation si vide
    if (_studentAnswers.isEmpty) {
      print('🚨 FORÇAGE de l\'initialisation des StudentAnswers');
      if (_currentQuiz != null && _currentAttempt != null) {
        _forceInitializeStudentAnswers();
      } else {
        print(
            '❌ Quiz ou attempt null: quiz=${_currentQuiz != null}, attempt=${_currentAttempt != null}');
        return;
      }
    }

    final answerIndex = _studentAnswers.indexWhere(
      (answer) => answer.questionId == questionId,
    );

    print('🔄 answerIndex trouvé: $answerIndex');
    print('🔄 Total studentAnswers: ${_studentAnswers.length}');

    if (answerIndex == -1) {
      print('❌ Aucune réponse trouvée pour cette question');
      print('❌ Questions disponibles:');
      for (int i = 0; i < _studentAnswers.length; i++) {
        print('❌   [$i] ${_studentAnswers[i].questionId}');
      }
      print('❌ Question recherchée: $questionId');

      // DERNIÈRE TENTATIVE - créer la StudentAnswer à la volée
      print('🚨 CRÉATION À LA VOLÉE de la StudentAnswer');
      final newStudentAnswer = StudentAnswer(
        id: '${_currentAttempt!.id}_${questionId}_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        active: true,
        questionId: questionId,
        quizAttemptId: _currentAttempt!.id,
        answerId: null,
        selectedAnswerIds: selectedAnswerIds ?? [],
        textAnswer: textAnswer,
        score: 0.0, // Le backend calculera le score
        isCorrect: false,
      );
      _studentAnswers.add(newStudentAnswer);
      print('✅ StudentAnswer créée à la volée: ${newStudentAnswer.id}');

      // Sauvegarder au backend - le backend calculera le score automatiquement
      if (_currentAttempt != null && !_currentAttempt!.id.startsWith('demo_')) {
        try {
          await _repository.saveStudentAnswer(newStudentAnswer);
          print(
              '✅ Réponse sauvegardée en base - le backend calculera le score');

          // Recharger les réponses pour récupérer le score calculé par le backend
          await _refreshStudentAnswersFromBackend();
        } catch (e) {
          print('❌ Erreur lors de la sauvegarde: $e');
        }
      }

      notifyListeners();
      return;
    }

    // Mettre à jour la réponse locale
    final updatedAnswer = _studentAnswers[answerIndex].copyWith(
      selectedAnswerIds: selectedAnswerIds ?? [],
      textAnswer: textAnswer,
      score: 0.0, // Le backend calculera le score
      isCorrect: false, // Le backend déterminera si c'est correct
    );

    _studentAnswers[answerIndex] = updatedAnswer;
    print(
        '✅ Réponse mise à jour localement: ${updatedAnswer.selectedAnswerIds}');

    // Sauvegarder au backend seulement si pas en mode demo
    if (_currentAttempt != null && !_currentAttempt!.id.startsWith('demo_')) {
      try {
        await _repository.saveStudentAnswer(updatedAnswer);
        print('✅ Réponse sauvegardée en base - le backend calculera le score');

        // Recharger les réponses pour récupérer le score calculé par le backend
        await _refreshStudentAnswersFromBackend();
      } catch (e) {
        print('❌ Erreur lors de la sauvegarde automatique: $e');
        // Ne pas bloquer l'interface en cas d'erreur de sauvegarde
      }
    }

    notifyListeners();
  }

  // Recharger les réponses depuis le backend pour récupérer les scores calculés
  Future<void> _refreshStudentAnswersFromBackend() async {
    if (_currentAttempt == null) return;

    try {
      // Récupérer la tentative mise à jour avec les réponses et scores du backend
      final updatedAttempt =
          await _repository.getQuizAttempt(_currentAttempt!.id);
      if (updatedAttempt != null && updatedAttempt.studentAnswers.isNotEmpty) {
        // Mettre à jour nos réponses locales avec les données du backend
        for (final backendAnswer in updatedAttempt.studentAnswers) {
          final localIndex = _studentAnswers.indexWhere(
            (answer) => answer.questionId == backendAnswer.questionId,
          );

          if (localIndex != -1) {
            _studentAnswers[localIndex] = backendAnswer;
            print(
                '🔄 Score mis à jour depuis le backend - Question ${backendAnswer.questionId}: ${backendAnswer.score}');
          }
        }
        notifyListeners();
      }
    } catch (e) {
      print('❌ Erreur lors du rechargement des réponses: $e');
    }
  }

  // Calculer le score d'une question
  double _calculateScore(Question question, List<String> selectedAnswerIds) {
    print('📊 Calcul du score pour question: ${question.id}');
    print('📊 Points de la question: ${question.points}');
    print('📊 Réponses sélectionnées: $selectedAnswerIds');

    // Debug: afficher TOUTES les réponses avec leur statut isCorrect
    print('📊 TOUTES les réponses de la question:');
    for (final answer in question.answers) {
      print(
          '📊   - ${answer.id}: "${answer.text}" (isCorrect: ${answer.isCorrect})');
    }

    final correctAnswers = question.correctAnswers;
    print(
        '📊 Réponses correctes: ${correctAnswers.map((a) => '${a.id}: ${a.text}').toList()}');

    final selectedCorrect = selectedAnswerIds
        .where(
          (id) => correctAnswers.any((answer) => answer.id == id),
        )
        .length;

    print('📊 Nombre de réponses correctes sélectionnées: $selectedCorrect');
    print('📊 Total réponses correctes: ${correctAnswers.length}');
    print('📊 Permet multiples réponses: ${question.allowsMultipleAnswers}');

    double calculatedScore = 0.0;

    if (question.allowsMultipleAnswers) {
      // Pour les questions à choix multiples
      final totalCorrect = correctAnswers.length;
      final incorrectSelected = selectedAnswerIds.length - selectedCorrect;

      print('📊 Réponses incorrectes sélectionnées: $incorrectSelected');

      if (incorrectSelected > 0) {
        calculatedScore = 0.0; // Pénalité pour les mauvaises réponses
        print('📊 Score = 0 (pénalité pour mauvaises réponses)');
      } else {
        calculatedScore = (selectedCorrect / totalCorrect) * question.points;
        print(
            '📊 Score = ($selectedCorrect / $totalCorrect) * ${question.points} = $calculatedScore');
      }
    } else {
      // Pour les questions à choix unique
      calculatedScore = selectedCorrect > 0 ? question.points : 0.0;
      print('📊 Score = ${selectedCorrect > 0 ? question.points : 0.0}');
    }

    print('📊 Score final: $calculatedScore');
    return calculatedScore;
  }

  // Navigation entre les questions
  void goToQuestion(int index) {
    if (index >= 0 && index < totalQuestions) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  void nextQuestion() {
    if (!isLastQuestion) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (!isFirstQuestion) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  // Soumettre le quiz
  Future<void> submitQuiz() async {
    if (_currentAttempt == null) {
      _setError('Aucune tentative en cours');
      return;
    }

    // Ne pas permettre la soumission en mode demo
    if (_currentAttempt!.id.startsWith('demo_')) {
      _setError('Impossible de soumettre un quiz en mode démonstration');
      return;
    }

    _setSubmitting(true);
    _clearError();

    try {
      // Rafraîchir une dernière fois les réponses depuis le backend avant soumission
      print('🎯 Rafraîchissement final des scores depuis le backend...');
      await _refreshStudentAnswersFromBackend();

      final totalScore =
          _studentAnswers.fold(0.0, (sum, answer) => sum + answer.score);
      print('🎯 Score total avant soumission: $totalScore');
      print('🎯 Temps passé: ${timeSpentInSeconds} secondes');

      final submittedAttempt = await _repository.submitQuizAttempt(
        _currentAttempt!.id,
        _studentAnswers,
      );

      _currentAttempt = submittedAttempt;
      print(
          '🎯 Quiz soumis avec succès - Score final du backend: ${submittedAttempt.score}');

      await _loadAttempts(_currentQuiz!.id);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setSubmitting(false);
    }
  }

  // Charger les tentatives précédentes
  Future<void> _loadAttempts(String quizId) async {
    try {
      _attempts = await _repository.getStudentAttempts(quizId);
    } catch (e) {
      print('Erreur lors du chargement des tentatives: $e');
      _attempts = [];
    }
  }

  // Réinitialiser l'état
  void reset() {
    _timer?.cancel();
    _currentQuiz = null;
    _currentAttempt = null;
    _studentAnswers = [];
    _attempts = [];
    _currentQuestionIndex = 0;
    _startTime = null;
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Méthodes utilitaires
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

  // Récupérer la réponse de l'étudiant pour une question
  StudentAnswer? getStudentAnswer(String questionId) {
    try {
      return _studentAnswers.firstWhere(
        (answer) => answer.questionId == questionId,
      );
    } catch (e) {
      return null;
    }
  }

  // Vérifier si une réponse est sélectionnée
  bool isAnswerSelected(String questionId, String answerId) {
    final studentAnswer = getStudentAnswer(questionId);
    final isSelected =
        studentAnswer?.selectedAnswerIds.contains(answerId) ?? false;
    return isSelected;
  }

  // Obtenir le texte de la réponse
  String? getTextAnswer(String questionId) {
    final studentAnswer = getStudentAnswer(questionId);
    return studentAnswer?.textAnswer;
  }

  // Obtenir le score total actuel
  double get currentTotalScore {
    return _studentAnswers.fold(0.0, (sum, answer) => sum + answer.score);
  }

  // Vérifier si le quiz peut être démarré (pas de tentatives dépassées)
  bool get canStartQuiz {
    if (_currentQuiz == null) return false;
    return _attempts.length < _currentQuiz!.maxAttempts;
  }
}
