import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/error_message.dart';
import '../../data/providers/quiz_provider.dart';
import '../../models/quiz.dart';
import '../../../../../core/widgets/loading_indicator.dart';
import '../widgets/download_quiz_button.dart';
import '../widgets/quiz_attempt_list.dart';
import '../widgets/quiz_info_card.dart';
import 'quiz_session_screen.dart';

class QuizDetailScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizDetailScreen({
    super.key,
    required this.quiz,
  });

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuizData();
    });
  }

  Future<void> _loadQuizData() async {
    final provider = Provider.of<QuizProvider>(context, listen: false);
    await provider.loadQuiz(widget.quiz.id);
    await provider.loadQuizAttempts(widget.quiz.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
      ),
      body: Consumer<QuizProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.currentQuiz == null) {
            return const LoadingIndicator();
          }

          if (provider.error != null && provider.currentQuiz == null) {
            return ErrorMessage(
              message: provider.error!,
              onRetry: _loadQuizData,
            );
          }

          final quiz = provider.currentQuiz ?? widget.quiz;

          return RefreshIndicator(
            onRefresh: _loadQuizData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations du quiz
                  QuizInfoCard(quiz: quiz),
                  const SizedBox(height: 16),

                  // Bouton de téléchargement pour mode hors ligne
                  DownloadQuizButton(quizId: quiz.id),
                  // Bouton pour commencer le quiz
                  if (quiz.isAvailable &&
                      quiz.maxAttempts < provider.attempts.length)
                    _buildStartQuizButton(context, provider, quiz),
                  const SizedBox(height: 24),
                  if (quiz.maxAttempts > 0 &&
                      provider.attempts.length >= quiz.maxAttempts)
                    const Text(
                      'Vous avez atteint le nombre maximum de tentatives.',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Historique des tentatives
                  const Text(
                    'Mes tentatives',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (provider.isLoading && provider.attempts.isEmpty)
                    const LoadingIndicator()
                  else if (provider.attempts.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Aucune tentative pour le moment.'),
                      ),
                    )
                  else
                    QuizAttemptList(
                      attempts: provider.attempts,
                      quiz: quiz,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStartQuizButton(
    BuildContext context,
    QuizProvider provider,
    Quiz quiz,
  ) {
    final hasInProgressAttempt = provider.isAttemptInProgress;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: quiz.isAvailable
            ? () async {
                if (hasInProgressAttempt) {
                  // Continuer la tentative en cours
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizSessionScreen(quiz: quiz),
                    ),
                  );
                } else {
                  // Commencer une nouvelle tentative
                  await provider.startQuizAttempt(quiz.id);
                  if (!mounted) return;

                  // Vérifier s'il y a eu une erreur
                  if (provider.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(provider.error!)),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizSessionScreen(quiz: quiz),
                    ),
                  );
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        child: Text(
          hasInProgressAttempt ? 'Continuer la tentative' : 'Commencer le quiz',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
