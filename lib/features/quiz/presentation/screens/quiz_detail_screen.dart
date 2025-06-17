import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../models/quiz.dart';
import '../../providers/quiz_provider.dart';
import 'quiz_session_screen.dart';

class QuizDetailScreen extends StatefulWidget {
  final String quizId;

  const QuizDetailScreen({
    super.key,
    required this.quizId,
  });

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().loadQuiz(widget.quizId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        elevation: 0,
      ),
      body: Consumer2<QuizProvider, ConnectivityProvider>(
        builder: (context, quizProvider, connectivityProvider, child) {
          if (quizProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (quizProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      quizProvider.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => quizProvider.loadQuiz(widget.quizId),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final quiz = quizProvider.currentQuiz;
          if (quiz == null) {
            return const Center(
              child: Text('Quiz non trouvé'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et informations de base
                _buildHeader(quiz),
                const SizedBox(height: 24),

                // Informations détaillées
                _buildQuizInfo(quiz),
                const SizedBox(height: 24),

                // Tentatives précédentes
                if (quizProvider.attempts.isNotEmpty) ...[
                  _buildAttemptsSection(quizProvider.attempts),
                  const SizedBox(height: 24),
                ],

                // Boutons d'action
                _buildActionButtons(
                    context, quiz, quizProvider, connectivityProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Quiz quiz) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.quiz,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    quiz.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            if (!quiz.isAvailable) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      quiz.isExpired ? Icons.schedule : Icons.lock,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      quiz.isExpired ? 'Expiré' : 'Non disponible',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuizInfo(Quiz quiz) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.access_time,
              label: 'Durée',
              value: quiz.durationText,
            ),
            _buildInfoRow(
              icon: Icons.help_outline,
              label: 'Questions',
              value:
                  '${quiz.questionCount} question${quiz.questionCount > 1 ? 's' : ''}',
            ),
            _buildInfoRow(
              icon: Icons.grade,
              label: 'Score maximum',
              value: '${quiz.maxScore.toStringAsFixed(1)} points',
            ),
            _buildInfoRow(
              icon: Icons.repeat,
              label: 'Tentatives autorisées',
              value: quiz.maxAttempts.toString(),
            ),
            _buildInfoRow(
              icon: Icons.check_circle_outline,
              label: 'Score de passage',
              value: '${(quiz.passingScore * 100).toStringAsFixed(0)}%',
            ),
            if (quiz.startDate != null)
              _buildInfoRow(
                icon: Icons.event,
                label: 'Disponible à partir du',
                value: _formatDate(quiz.startDate!),
              ),
            if (quiz.endDate != null)
              _buildInfoRow(
                icon: Icons.event_busy,
                label: 'Disponible jusqu\'au',
                value: _formatDate(quiz.endDate!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptsSection(List attempts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tentatives précédentes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...attempts.map((attempt) => _buildAttemptItem(attempt)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttemptItem(dynamic attempt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.assignment_turned_in,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tentative du ${_formatDate(attempt.startDate)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Score: ${attempt.scoreText}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (attempt.endDate != null)
                  Text(
                    'Durée: ${attempt.timeSpentText}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            attempt.isCompleted ? Icons.check_circle : Icons.pending,
            color: attempt.isCompleted ? Colors.green : Colors.orange,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Quiz quiz,
    QuizProvider quizProvider,
    ConnectivityProvider connectivityProvider,
  ) {
    return Column(
      children: [
        // Bouton principal
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: quiz.isAvailable && connectivityProvider.isOnline
                ? () => _startQuiz(context, quizProvider)
                : null,
            icon: const Icon(Icons.play_arrow),
            label: Text(
              quiz.isAvailable
                  ? 'Commencer le quiz'
                  : quiz.isExpired
                      ? 'Quiz expiré'
                      : 'Quiz non disponible',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        // Message hors ligne
        if (!connectivityProvider.isOnline) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Connexion Internet requise pour passer le quiz',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _startQuiz(BuildContext context, QuizProvider quizProvider) async {
    try {
      await quizProvider.startQuizAttempt();

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const QuizSessionScreen(),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du démarrage du quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
