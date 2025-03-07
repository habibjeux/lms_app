import 'package:flutter/material.dart';
import '../../models/quiz.dart';
import '../../models/quiz_attempt.dart';
import '../../models/student_answer.dart';
import '../widgets/answered_question_card.dart';
import '../widgets/quiz_result_summary.dart';

class QuizResultScreen extends StatelessWidget {
  final Quiz quiz;
  final QuizAttempt attempt;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.attempt,
  });

  @override
  Widget build(BuildContext context) {
    final showCorrectAnswers = quiz.showCorrectAnswers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats du quiz'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Récapitulatif des résultats
              QuizResultSummary(
                quiz: quiz,
                attempt: attempt,
              ),
              const SizedBox(height: 24),

              // Questions avec réponses
              const Text(
                'Détails des réponses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              if (showCorrectAnswers)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: quiz.questions.length,
                  itemBuilder: (context, index) {
                    final question = quiz.questions[index];
                    final studentAnswer = _findStudentAnswer(question.id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: AnsweredQuestionCard(
                        question: question,
                        studentAnswer: studentAnswer,
                        showCorrectAnswer: true,
                      ),
                    );
                  },
                )
              else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Les réponses correctes ne sont pas disponibles pour ce quiz.',
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Retour'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  StudentAnswer? _findStudentAnswer(String questionId) {
    try {
      return attempt.studentAnswers.firstWhere(
        (answer) => answer.questionId == questionId,
      );
    } catch (e) {
      return null;
    }
  }
}
