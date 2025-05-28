import 'package:flutter/material.dart';
import '../../models/quiz.dart';
import 'quiz_availability_badge.dart';

class QuizInfoCard extends StatelessWidget {
  final Quiz quiz;

  const QuizInfoCard({
    super.key,
    required this.quiz,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    quiz.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                QuizAvailabilityBadge(quiz: quiz),
              ],
            ),
            const SizedBox(height: 8),
            if (quiz.startDate != null || quiz.endDate != null) ...[
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (quiz.startDate != null)
                          Text(
                            'Début: ${_formatDateTime(quiz.startDate!)}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        if (quiz.endDate != null)
                          Text(
                            'Fin: ${_formatDateTime(quiz.endDate!)}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              fontWeight: quiz.isExpired
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const Divider(),
            _buildInfoRow(
              Icons.timelapse,
              'Durée: ${quiz.durationText}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.refresh,
              'Tentatives autorisées: ${quiz.maxAttempts}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.check_circle_outline,
              'Score minimum: ${(quiz.passingScore * 100).toStringAsFixed(0)}%',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.help_outline,
              'Questions: ${quiz.questionCount}',
            ),
            if (quiz.shuffleQuestions) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.shuffle,
                'Questions dans un ordre aléatoire',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: Colors.grey[700]),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
