import 'package:flutter/material.dart';
import '../../models/quiz.dart';
import '../../models/quiz_attempt.dart';

class QuizResultSummary extends StatelessWidget {
  final Quiz quiz;
  final QuizAttempt attempt;

  const QuizResultSummary({
    super.key,
    required this.quiz,
    required this.attempt,
  });

  @override
  Widget build(BuildContext context) {
    final passingScorePoints = quiz.passingScore * quiz.maxScore;
    final isPassed = attempt.score >= passingScorePoints;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPassed ? Icons.check_circle : Icons.cancel,
                  color: isPassed ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPassed ? 'Quiz réussi !' : 'Quiz non réussi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isPassed ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Score:',
              '${attempt.score.toStringAsFixed(1)} / ${quiz.maxScore.toStringAsFixed(1)} points',
              bold: true,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Score minimum requis:',
              '${passingScorePoints.toStringAsFixed(1)} points (${(quiz.passingScore * 100).toStringAsFixed(0)}%)',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Pourcentage:',
              '${((attempt.score / quiz.maxScore) * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Temps passé:',
              attempt.durationText,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Questions répondues:',
              '${attempt.studentAnswers.length} / ${quiz.questions.length}',
            ),
            const SizedBox(height: 16),

            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: attempt.score / quiz.maxScore,
                backgroundColor: Colors.grey[300],
                color: _getScoreColor(attempt.score / quiz.maxScore),
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double scorePercentage) {
    if (scorePercentage >= quiz.passingScore) {
      return Colors.green;
    } else if (scorePercentage >= quiz.passingScore * 0.75) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
