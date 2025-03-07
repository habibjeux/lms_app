// lib/features/quizzes/presentation/widgets/quiz_attempt_list.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/quiz.dart';
import '../../models/quiz_attempt.dart';

class QuizAttemptList extends StatelessWidget {
  final List<QuizAttempt> attempts;
  final Quiz quiz;

  const QuizAttemptList({
    super.key,
    required this.attempts,
    required this.quiz,
  });

  @override
  Widget build(BuildContext context) {
    final sortedAttempts = List<QuizAttempt>.from(attempts)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return Column(
      children: [
        for (final attempt in sortedAttempts)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: Text(
                'Tentative du ${_formatDate(attempt.startDate)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildBadge(
                        attempt.isInProgress
                            ? 'En cours'
                            : attempt.isCompleted
                                ? 'Terminé'
                                : 'Expiré',
                        attempt.isInProgress
                            ? Colors.blue
                            : attempt.isCompleted
                                ? Colors.green
                                : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      if (!attempt.isInProgress) ...[
                        _buildBadge(
                          attempt.score >= quiz.passingScore * quiz.maxScore
                              ? 'Réussi'
                              : 'Échoué',
                          attempt.score >= quiz.passingScore * quiz.maxScore
                              ? Colors.green
                              : Colors.red,
                        ),
                      ],
                      if (!attempt.isSynchronized) ...[
                        const SizedBox(width: 8),
                        _buildBadge(
                          'Non synchronisé',
                          Colors.amber,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!attempt.isInProgress) ...[
                    Row(
                      children: [
                        Icon(Icons.score, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Score: ${attempt.score.toStringAsFixed(1)}/${quiz.maxScore}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Durée: ${attempt.durationText}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              trailing: attempt.isInProgress
                  ? const Icon(Icons.play_arrow, color: Colors.blue)
                  : null,
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(date);
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
