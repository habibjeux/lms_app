import 'package:flutter/material.dart';

class QuizProgressBar extends StatelessWidget {
  final double progress;
  final int answered;
  final int total;

  const QuizProgressBar({
    super.key,
    required this.progress,
    required this.answered,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = progress < 0.5
        ? Colors.orange
        : progress < 1.0
            ? Colors.blue
            : Colors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progression',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              '$answered sur $total questions répondues',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            color: progressColor,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
