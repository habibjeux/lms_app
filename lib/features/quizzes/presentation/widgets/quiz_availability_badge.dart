// lib/features/quizzes/presentation/widgets/quiz_availability_badge.dart
import 'package:flutter/material.dart';
import '../../models/quiz.dart';

class QuizAvailabilityBadge extends StatelessWidget {
  final Quiz quiz;

  const QuizAvailabilityBadge({
    super.key,
    required this.quiz,
  });

  @override
  Widget build(BuildContext context) {
    if (!quiz.visible) {
      return _buildBadge('Non disponible', Colors.grey);
    }

    if (quiz.isExpired) {
      return _buildBadge('Terminé', Colors.red);
    }

    final now = DateTime.now();
    if (quiz.startDate != null && now.isBefore(quiz.startDate!)) {
      return _buildBadge('À venir', Colors.orange);
    }

    return _buildBadge('Disponible', Colors.green);
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
