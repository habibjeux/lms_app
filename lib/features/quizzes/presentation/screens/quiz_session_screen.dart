import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../../../core/widgets/loading_indicator.dart';
import '../../data/providers/quiz_provider.dart';
import '../../models/quiz.dart';
import '../widgets/question_card.dart';
import '../widgets/quiz_progress_bar.dart';
import '../widgets/quiz_timer.dart';
import 'quiz_result_screen.dart';
import '../../../../../core/providers/connectivity_provider.dart';

class QuizSessionScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizSessionScreen({
    super.key,
    required this.quiz,
  });

  @override
  State<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  bool _showExitConfirmation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimer();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    final provider = Provider.of<QuizProvider>(context, listen: false);
    final quiz = provider.currentQuiz ?? widget.quiz;

    // Initialiser le temps restant s'il n'est pas déjà défini
    if (provider.remainingTime <= 0) {
      provider.updateRemainingTime(quiz.duration * 60);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = provider.remainingTime - 1;

      if (remaining <= 0) {
        // Temps écoulé, soumettre automatiquement
        timer.cancel();
        _submitQuiz();
      } else {
        provider.updateRemainingTime(remaining);
      }
    });
  }

  Future<void> _submitQuiz() async {
    final provider = Provider.of<QuizProvider>(context, listen: false);
    await provider.submitQuizAttempt();

    if (!mounted) return;

    // Naviguer vers l'écran de résultats
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          quiz: widget.quiz,
          attempt: provider.currentAttempt!,
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_showExitConfirmation) {
      return true;
    }

    setState(() {
      _showExitConfirmation = true;
    });

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final connectivityProvider = Provider.of<ConnectivityProvider>(context);
    final isOffline = !connectivityProvider.isOnline;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<QuizProvider>(
            builder: (context, provider, _) {
              final quiz = provider.currentQuiz ?? widget.quiz;
              return Text(quiz.title);
            },
          ),
          leading: _showExitConfirmation
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showExitConfirmation = true;
                    });
                  },
                ),
        ),
        body: _showExitConfirmation
            ? _buildExitConfirmation()
            : Consumer<QuizProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const LoadingIndicator();
                  }

                  final quiz = provider.currentQuiz ?? widget.quiz;
                  final questions = quiz.questions;

                  return Column(
                    children: [
                      // Barre de progression et minuteur
                      Container(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Question ${_currentPage + 1} sur ${questions.length}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                QuizTimer(
                                  remainingTime: provider.remainingTime,
                                  isAlmostUp: provider.isTimeAlmostUp,
                                  isCritical: provider.isCriticalTime,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            QuizProgressBar(
                              progress: provider.progressPercentage,
                              answered: provider.answeredQuestionsCount,
                              total: questions.length,
                            ),
                          ],
                        ),
                      ),

                      // Indicateur mode hors ligne
                      if (isOffline)
                        Container(
                          width: double.infinity,
                          color: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 16,
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.wifi_off,
                                  size: 16, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Mode hors ligne',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),

                      // Questions
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: questions.length,
                          onPageChanged: (page) {
                            setState(() {
                              _currentPage = page;
                            });
                          },
                          itemBuilder: (context, index) {
                            final question = questions[index];
                            return QuestionCard(
                              question: question,
                              index: index,
                              selectedAnswerId:
                                  provider.getSelectedAnswerId(question.id),
                              textAnswer: provider.getTextAnswer(question.id),
                              onAnswerSelected: (answerId) {
                                provider.saveStudentAnswer(
                                  questionId: question.id,
                                  answerId: answerId,
                                );
                              },
                              onTextAnswerChanged: (text) {
                                provider.saveStudentAnswer(
                                  questionId: question.id,
                                  textAnswer: text,
                                );
                              },
                            );
                          },
                        ),
                      ),

                      // Navigation et bouton de soumission
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0, -1),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Bouton précédent
                            ElevatedButton(
                              onPressed: _currentPage > 0
                                  ? () {
                                      _pageController.previousPage(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Précédent'),
                            ),

                            // Bouton suivant ou terminer
                            ElevatedButton(
                              onPressed: _currentPage < questions.length - 1
                                  ? () {
                                      _pageController.nextPage(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  : provider.canSubmit
                                      ? () => _submitQuiz()
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _currentPage < questions.length - 1
                                        ? Theme.of(context).primaryColor
                                        : Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                _currentPage < questions.length - 1
                                    ? 'Suivant'
                                    : 'Terminer le quiz',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildExitConfirmation() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quitter le quiz ?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Votre progression sera sauvegardée et vous pourrez continuer plus tard.',
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showExitConfirmation = false;
                      });
                    },
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Quitter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
