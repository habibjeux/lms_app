import 'package:flutter/material.dart';
import '../../models/enums/question_type.dart';
import '../../models/question.dart';
import '../../models/student_answer.dart';
import '../../models/answer.dart';

class AnsweredQuestionCard extends StatelessWidget {
  final Question question;
  final StudentAnswer? studentAnswer;
  final bool showCorrectAnswer;

  const AnsweredQuestionCard({
    super.key,
    required this.question,
    this.studentAnswer,
    this.showCorrectAnswer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionHeader(),
            const SizedBox(height: 12),
            Text(
              question.text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildAnswers(context),
            if (showCorrectAnswer && studentAnswer != null) ...[
              const SizedBox(height: 12),
              _buildFooter(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionHeader() {
    String typeText;
    switch (question.type) {
      case QuestionType.MCQ:
        typeText = 'Choix multiple';
        break;
      case QuestionType.SCQ:
        typeText = 'Choix unique';
        break;
      case QuestionType.TRUE_FALSE:
        typeText = 'Vrai/Faux';
        break;
      case QuestionType.SHORT_ANSWER:
        typeText = 'Réponse courte';
        break;
      case QuestionType.MATCHING:
        typeText = 'Association';
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            typeText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ),
        if (studentAnswer != null)
          Row(
            children: [
              Icon(
                _isCorrect() ? Icons.check_circle : Icons.cancel,
                color: _isCorrect() ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${studentAnswer!.score}/${question.points} points',
                style: TextStyle(
                  color: _isCorrect() ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAnswers(BuildContext context) {
    if (question.isShortAnswer) {
      return _buildShortAnswerResult();
    } else {
      return Column(
        children: [
          for (final answer in question.answers)
            _buildAnswerItem(context, answer),
        ],
      );
    }
  }

  Widget _buildAnswerItem(BuildContext context, Answer answer) {
    final isSelected = studentAnswer?.answerId == answer.id;
    final isCorrect = answer.isCorrect;
    final showCorrect = showCorrectAnswer;

    Color backgroundColor;
    Color borderColor;
    Color textColor = Colors.black;

    if (showCorrect) {
      if (isSelected && isCorrect) {
        // Sélectionné et correct
        backgroundColor = Colors.green.withOpacity(0.1);
        borderColor = Colors.green;
        textColor = Colors.green[700]!;
      } else if (isSelected && !isCorrect) {
        // Sélectionné mais incorrect
        backgroundColor = Colors.red.withOpacity(0.1);
        borderColor = Colors.red;
        textColor = Colors.red[700]!;
      } else if (!isSelected && isCorrect) {
        // Non sélectionné mais correct
        backgroundColor = Colors.green.withOpacity(0.05);
        borderColor = Colors.green.withOpacity(0.5);
        textColor = Colors.green[700]!;
      } else {
        // Non sélectionné et incorrect
        backgroundColor = Colors.white;
        borderColor = Colors.grey[300]!;
      }
    } else {
      if (isSelected) {
        backgroundColor = Theme.of(context).primaryColor.withOpacity(0.1);
        borderColor = Theme.of(context).primaryColor;
      } else {
        backgroundColor = Colors.white;
        borderColor = Colors.grey[300]!;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          if (question.isSingleChoice || question.isTrueFalse)
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? borderColor : Colors.grey,
              size: 20,
            )
          else
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected ? borderColor : Colors.grey,
              size: 20,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              answer.text,
              style: TextStyle(color: textColor),
            ),
          ),
          if (showCorrect && isCorrect)
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildShortAnswerResult() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Votre réponse:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(studentAnswer?.textAnswer ?? 'Aucune réponse fournie'),
          if (showCorrectAnswer) ...[
            const SizedBox(height: 16),
            const Text(
              'Réponse acceptée:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              question.answers.isNotEmpty
                  ? question.answers.first.text
                  : 'Aucune réponse modèle fournie',
              style: const TextStyle(color: Colors.green),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    if (_isCorrect()) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Réponse correcte !',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Réponse incorrecte',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Color _getBorderColor() {
    if (!showCorrectAnswer || studentAnswer == null) {
      return Colors.grey[300]!;
    }

    return _isCorrect()
        ? Colors.green.withOpacity(0.3)
        : Colors.red.withOpacity(0.3);
  }

  bool _isCorrect() {
    if (studentAnswer == null) return false;

    // Pour les questions à réponse courte, vérifier le score
    if (question.isShortAnswer) {
      return studentAnswer!.score > 0;
    }

    // Pour les autres types de questions, vérifier l'ID de la réponse
    if (studentAnswer!.answerId == null) return false;

    final selectedAnswer = question.answers.firstWhere(
      (answer) => answer.id == studentAnswer!.answerId,
      orElse: () => Answer(
        id: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        active: false,
        text: '',
        isCorrect: false,
        points: 0,
        questionId: '',
      ),
    );

    return selectedAnswer.isCorrect;
  }
}
