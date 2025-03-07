import 'package:flutter/material.dart';

class QuizTimer extends StatelessWidget {
  final int remainingTime;
  final bool isAlmostUp;
  final bool isCritical;

  const QuizTimer({
    super.key,
    required this.remainingTime,
    required this.isAlmostUp,
    required this.isCritical,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = remainingTime ~/ 60;
    final seconds = remainingTime % 60;

    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 16,
            color: _getTextColor(),
          ),
          const SizedBox(width: 4),
          Text(
            timeText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getTextColor(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    if (isCritical) {
      return Colors.red.withOpacity(0.2);
    } else if (isAlmostUp) {
      return Colors.orange.withOpacity(0.2);
    } else {
      return Colors.blue.withOpacity(0.2);
    }
  }

  Color _getTextColor() {
    if (isCritical) {
      return Colors.red;
    } else if (isAlmostUp) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }
}
