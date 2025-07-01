import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quiz_provider.dart';
import '../../models/question.dart';
import '../../models/answer.dart';

class QuizSessionScreen extends StatefulWidget {
  const QuizSessionScreen({super.key});

  @override
  State<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 40,
        automaticallyImplyLeading: false,
        actions: [
          Consumer<QuizProvider>(
            builder: (context, quizProvider, child) {
              final remainingTime = quizProvider.remainingTime;
              if (remainingTime != null) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      '${remainingTime.inMinutes}:${(remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: remainingTime.inMinutes < 5
                            ? Colors.red
                            : Colors.white,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          if (quizProvider.currentQuiz == null) {
            return const Center(
              child: Text('Aucun quiz en cours'),
            );
          }

          if (quizProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Vérifier s'il y a une erreur qui empêche l'accès au quiz
          if (quizProvider.error != null &&
              (quizProvider.error!.contains('nombre maximum de tentatives') ||
                  quizProvider.error!.contains('maximum attempts') ||
                  quizProvider.error!.contains('tentatives autorisées'))) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.block,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Accès refusé',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      quizProvider.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red[700],
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            );
          }

          final currentQuestion = quizProvider.currentQuestion;
          if (currentQuestion == null) {
            return const Center(
              child: Text('Aucune question disponible'),
            );
          }

          return Column(
            children: [
              // Barre de progression
              _buildProgressBar(quizProvider),

              // Contenu de la question
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Numéro de question
                      Text(
                        'Question ${quizProvider.currentQuestionIndex + 1} sur ${quizProvider.totalQuestions}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                      ),
                      const SizedBox(height: 16),

                      // Question
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildQuestionContent(
                              currentQuestion, quizProvider),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Boutons de navigation
              _buildNavigationButtons(quizProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(QuizProvider quizProvider) {
    final progress =
        (quizProvider.currentQuestionIndex + 1) / quizProvider.totalQuestions;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${quizProvider.currentQuestionIndex + 1}/${quizProvider.totalQuestions}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${quizProvider.answeredQuestions} répondues',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Affichage seulement du minuteur (pas de score)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (quizProvider.remainingTime != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: quizProvider.remainingTime!.inMinutes < 5
                        ? Colors.red.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: quizProvider.remainingTime!.inMinutes < 5
                            ? Colors.red
                            : Colors.blue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Temps restant: ${quizProvider.remainingTime!.inMinutes}:${(quizProvider.remainingTime!.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: quizProvider.remainingTime!.inMinutes < 5
                              ? Colors.red
                              : Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.orange.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(Question question, QuizProvider quizProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Texte de la question
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.text,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${question.points} point${question.points > 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Image si disponible
        if (question.imageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              question.imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image_not_supported),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Réponses
        _buildAnswerOptions(question, quizProvider),
      ],
    );
  }

  Widget _buildAnswerOptions(Question question, QuizProvider quizProvider) {
    print('🎯 Question type debug:');
    print('🎯 originalType: ${question.originalType}');
    print('🎯 type: ${question.type}');
    print('🎯 allowsMultipleAnswers: ${question.allowsMultipleAnswers}');

    // Questions nécessitant une saisie de texte
    if (question.requiresTextInput) {
      print('🎯 → Utilisation _buildTextAnswerInput');
      return _buildTextAnswerInput(question, quizProvider);
    }

    // Questions d'association (MATCHING)
    if (question.originalType == 'MATCHING') {
      print('🎯 → Utilisation _buildMatchingQuestion');
      return _buildMatchingQuestion(question, quizProvider);
    }

    // Questions Vrai/Faux
    if (question.originalType == 'TRUE_FALSE') {
      print('🎯 → Utilisation _buildTrueFalseQuestion');
      return _buildTrueFalseQuestion(question, quizProvider);
    }

    // Questions à choix multiples (MCQ) - permet plusieurs sélections
    if (question.originalType == 'MCQ') {
      print('🎯 → Utilisation _buildMultipleChoiceQuestion (MCQ)');
      return _buildMultipleChoiceQuestion(question, quizProvider);
    }

    // Questions à choix unique (SCQ et autres) - une seule sélection
    print('🎯 → Utilisation _buildSingleChoiceQuestion (SCQ ou défaut)');
    return _buildSingleChoiceQuestion(question, quizProvider);
  }

  // Widget pour les questions à choix unique (SCQ)
  Widget _buildSingleChoiceQuestion(
      Question question, QuizProvider quizProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orange.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.radio_button_on,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Choisissez une seule réponse correcte :',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...question.answers.map((answer) {
          final isSelected =
              quizProvider.isAnswerSelected(question.id, answer.id);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.withOpacity(0.15),
                        Colors.orange.withOpacity(0.1),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey.withOpacity(0.02),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => _selectSingleAnswer(question, answer, quizProvider),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.orange : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        answer.text,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? Colors.orange[800]
                              : Colors.grey[800],
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        // Indicateur de sélection unique
        if (quizProvider
                .getStudentAnswer(question.id)
                ?.selectedAnswerIds
                .isNotEmpty ==
            true)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 6),
                Text(
                  'Réponse sélectionnée',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Widget pour les questions à choix multiples (MCQ)
  Widget _buildMultipleChoiceQuestion(
      Question question, QuizProvider quizProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_box_outlined,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Choisissez une ou plusieurs réponses correctes :',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...question.answers.map((answer) {
          final isSelected =
              quizProvider.isAnswerSelected(question.id, answer.id);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.withOpacity(0.15),
                        Colors.blue.withOpacity(0.1),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey.withOpacity(0.02),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () =>
                  _toggleMultipleAnswer(question, answer, quizProvider),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: isSelected ? Colors.blue : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        answer.text,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color:
                              isSelected ? Colors.blue[800] : Colors.grey[800],
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        // Indicateur du nombre de réponses sélectionnées
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                '${quizProvider.getStudentAnswer(question.id)?.selectedAnswerIds.length ?? 0} réponse(s) sélectionnée(s)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget pour les questions Vrai/Faux
  Widget _buildTrueFalseQuestion(Question question, QuizProvider quizProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.purple.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.quiz,
                color: Colors.purple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Choisissez Vrai ou Faux :',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.purple[800],
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: question.answers.map((answer) {
            final isSelected =
                quizProvider.isAnswerSelected(question.id, answer.id);
            final isTrue = answer.text.toLowerCase().contains('vrai') ||
                answer.text.toLowerCase().contains('true');

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            (isTrue ? Colors.green : Colors.red)
                                .withOpacity(0.15),
                            (isTrue ? Colors.green : Colors.red)
                                .withOpacity(0.1),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.grey.withOpacity(0.02),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (isTrue ? Colors.green : Colors.red)
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? (isTrue ? Colors.green : Colors.red)
                              .withOpacity(0.2)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () =>
                      _selectSingleAnswer(question, answer, quizProvider),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    child: Column(
                      children: [
                        Icon(
                          isTrue ? Icons.check_circle : Icons.cancel,
                          color: isSelected
                              ? (isTrue ? Colors.green : Colors.red)
                              : Colors.grey[600],
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          answer.text,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? (isTrue ? Colors.green[800] : Colors.red[800])
                                : Colors.grey[800],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Indicateur de sélection
        if (quizProvider
                .getStudentAnswer(question.id)
                ?.selectedAnswerIds
                .isNotEmpty ==
            true)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: Colors.purple[600],
                ),
                const SizedBox(width: 6),
                Text(
                  'Réponse sélectionnée',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.purple[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Widget pour les questions d'association (MATCHING)
  Widget _buildMatchingQuestion(Question question, QuizProvider quizProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec instructions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[50]!, Colors.purple[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple[600],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shuffle,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Question d\'Association',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Sélectionnez tous les éléments qui correspondent ou s\'associent correctement. Vous pouvez choisir plusieurs réponses.',
                style: TextStyle(
                  color: Colors.purple[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: Colors.purple[600], size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Astuce: Lisez attentivement chaque option',
                        style: TextStyle(
                          color: Colors.purple[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Compteur de sélections
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.checklist, color: Colors.grey[600], size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${_getSelectedAnswersCount(question, quizProvider)} sélectionnée(s)',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Liste des réponses avec design amélioré
        ...question.answers.asMap().entries.map((entry) {
          final index = entry.key;
          final answer = entry.value;
          final isSelected =
              quizProvider.isAnswerSelected(question.id, answer.id);

          return _buildMatchingAnswerCard(
            answer,
            question,
            quizProvider,
            index,
            isSelected,
          );
        }),
      ],
    );
  }

  int _getSelectedAnswersCount(Question question, QuizProvider quizProvider) {
    return question.answers
        .where(
            (answer) => quizProvider.isAnswerSelected(question.id, answer.id))
        .length;
  }

  Widget _buildMatchingAnswerCard(
    Answer answer,
    Question question,
    QuizProvider quizProvider,
    int index,
    bool isSelected,
  ) {
    // Couleurs alternées pour les cartes
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
      Colors.red,
    ];
    final cardColor = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: isSelected ? 4 : 1,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            print('🔄 Clic sur réponse d\'association: ${answer.text}');
            _toggleMultipleAnswer(question, answer, quizProvider);
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? cardColor[600]! : Colors.grey[300]!,
                width: isSelected ? 3 : 1,
              ),
              color: isSelected ? cardColor[50] : Colors.white,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: cardColor[200]!,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Indicateur de sélection animé
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? cardColor[600] : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? cardColor[600]! : Colors.grey[400]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),

                const SizedBox(width: 16),

                // Numéro de l'option
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected ? cardColor[600] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D...
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Texte de la réponse
                Expanded(
                  child: Text(
                    answer.text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? cardColor[800] : Colors.grey[800],
                      height: 1.3,
                    ),
                  ),
                ),

                // Icône de statut
                const SizedBox(width: 12),
                AnimatedRotation(
                  turns: isSelected ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? Icons.link : Icons.link_off,
                    color: isSelected ? cardColor[600] : Colors.grey[400],
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextAnswerInput(Question question, QuizProvider quizProvider) {
    final currentAnswer = quizProvider.getTextAnswer(question.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.isEssay
                  ? 'Votre réponse (dissertation):'
                  : 'Votre réponse:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: currentAnswer,
              maxLines: question.isEssay ? 8 : 3,
              decoration: InputDecoration(
                hintText: question.isEssay
                    ? 'Rédigez votre réponse détaillée...'
                    : 'Tapez votre réponse...',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              onChanged: (value) {
                quizProvider.saveAnswer(
                  question.id,
                  '', // Pas d'answerId pour les questions texte
                  textAnswer: value,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(QuizProvider quizProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton Précédent
          if (!quizProvider.isFirstQuestion)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: quizProvider.previousQuestion,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Précédent'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

          if (!quizProvider.isFirstQuestion && !quizProvider.isLastQuestion)
            const SizedBox(width: 16),

          // Bouton Suivant ou Terminer
          Expanded(
            child: ElevatedButton.icon(
              onPressed: quizProvider.isLastQuestion
                  ? () => _showSubmitDialog(quizProvider)
                  : quizProvider.nextQuestion,
              icon: Icon(
                quizProvider.isLastQuestion ? Icons.check : Icons.arrow_forward,
              ),
              label: Text(
                quizProvider.isLastQuestion ? 'Terminer le quiz' : 'Suivant',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: quizProvider.isLastQuestion
                    ? Colors.green
                    : Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectSingleAnswer(
      Question question, Answer answer, QuizProvider quizProvider) async {
    print('🎯 _selectSingleAnswer appelé');
    print('🎯 Question ID: ${question.id}');
    print('🎯 Question Type: ${question.originalType}');
    print('🎯 Answer ID: ${answer.id}');
    print('🎯 Answer text: ${answer.text}');

    // Pour les questions à choix unique, utiliser la nouvelle méthode simplifiée
    await quizProvider.saveAnswer(
      question.id,
      answer.id,
    );
  }

  void _toggleMultipleAnswer(
      Question question, Answer answer, QuizProvider quizProvider) async {
    print('🎯 _toggleMultipleAnswer appelé');
    print('🎯 Question ID: ${question.id}');
    print('🎯 Question Type: ${question.originalType}');
    print('🎯 Answer ID: ${answer.id}');
    print('🎯 Answer text: ${answer.text}');

    final currentAnswers =
        quizProvider.getStudentAnswer(question.id)?.selectedAnswerIds ?? [];
    print('🎯 Réponses actuelles: $currentAnswers');

    List<String> selectedAnswers = List.from(currentAnswers);

    if (selectedAnswers.contains(answer.id)) {
      selectedAnswers.remove(answer.id);
      print('🎯 Réponse retirée: ${answer.id}');
    } else {
      selectedAnswers.add(answer.id);
      print('🎯 Réponse ajoutée: ${answer.id}');
    }

    print('🎯 Nouvelles réponses: $selectedAnswers');

    // Utiliser la nouvelle méthode simplifiée pour les MCQ
    await quizProvider.saveMultipleChoiceAnswer(
      question.id,
      selectedAnswers,
    );
  }

  void _showSubmitDialog(QuizProvider quizProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Terminer le quiz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir terminer ce quiz ?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Questions répondues: ${quizProvider.answeredQuestions}/${quizProvider.totalQuestions}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (quizProvider.answeredQuestions < quizProvider.totalQuestions)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Attention: ${quizProvider.totalQuestions - quizProvider.answeredQuestions} question(s) non répondue(s)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _submitQuiz(quizProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitQuiz(QuizProvider quizProvider) async {
    try {
      await quizProvider.submitQuiz();

      if (mounted) {
        // Afficher les résultats
        _showResultsDialog(quizProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la soumission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResultsDialog(QuizProvider quizProvider) {
    final currentAttempt = quizProvider.currentAttempt;
    if (currentAttempt == null) return;

    // Calculer le nombre de questions correctes en regardant le score de chaque réponse
    final correctQuestions =
        quizProvider.studentAnswers.where((answer) => answer.score > 0).length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('Quiz terminé !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.withOpacity(0.1),
                    Colors.green.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Score obtenu:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${_formatScore(currentAttempt.score)} / ${_formatScore(quizProvider.currentQuiz?.maxScore ?? 0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pourcentage:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${((currentAttempt.score / (quizProvider.currentQuiz?.maxScore ?? 1)) * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Questions correctes:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '$correctQuestions / ${quizProvider.totalQuestions}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Temps utilisé:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${(quizProvider.timeSpentInSeconds ~/ 60)}:${(quizProvider.timeSpentInSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Félicitations ! Votre quiz a été soumis avec succès.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            // Afficher les réponses correctes si l'option est activée
            if (quizProvider.currentQuiz?.showCorrectAnswers == true) ...[
              const SizedBox(height: 16),
              Text(
                'Résultats détaillés:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    children: quizProvider.studentAnswers
                        .asMap()
                        .entries
                        .map((entry) {
                      final index = entry.key;
                      final answer = entry.value;
                      final question =
                          quizProvider.currentQuiz!.questions.firstWhere(
                        (q) => q.id == answer.questionId,
                      );
                      // Utiliser le score pour déterminer si c'est correct
                      final isCorrect = answer.score > 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCorrect
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.cancel,
                                  color: isCorrect ? Colors.green : Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Question ${index + 1}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isCorrect
                                          ? Colors.green[800]
                                          : Colors.red[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_formatScore(answer.score)}/${_formatScore(question.points)} pts',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isCorrect
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              question.text,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (answer.selectedAnswerIds.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Votre réponse: ${_getAnswerText(question, answer)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isCorrect
                                      ? Colors.green[600]
                                      : Colors.red[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialog
              Navigator.pop(context); // Retourner à l'écran précédent
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  // Formater les scores pour afficher les entiers sans décimales
  String _formatScore(double score) {
    if (score == score.roundToDouble()) {
      return score.round().toString();
    } else {
      return score.toStringAsFixed(1);
    }
  }

  // Obtenir le texte de la réponse sélectionnée
  String _getAnswerText(Question question, dynamic studentAnswer) {
    if (studentAnswer.textAnswer != null &&
        studentAnswer.textAnswer.isNotEmpty) {
      return studentAnswer.textAnswer;
    }

    if (studentAnswer.selectedAnswerIds != null &&
        studentAnswer.selectedAnswerIds.isNotEmpty) {
      final answerId = studentAnswer.selectedAnswerIds.first;
      final answer = question.answers.firstWhere(
        (a) => a.id == answerId,
        orElse: () => question.answers.first,
      );
      return answer.text;
    }

    return 'Aucune réponse';
  }
}
