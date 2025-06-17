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
      appBar: AppBar(
        title: const Text('Session de Quiz'),
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

          final currentQuestion = quizProvider.currentQuestion;
          if (currentQuestion == null) {
            return const Center(
              child: Text('Aucune question disponible'),
            );
          }

          return Column(
            children: [
              // Bannière d'information pour le mode démonstration
              if (quizProvider.error != null &&
                  quizProvider.error!.contains('Mode démonstration'))
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.orange[100],
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mode démonstration - Vous pouvez naviguer dans le quiz mais vos réponses ne seront pas sauvegardées',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Progression',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Flexible(
                child: Text(
                  '${quizProvider.answeredQuestions}/${quizProvider.totalQuestions} répondues',
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
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
          child: Padding(
            padding: const EdgeInsets.all(16),
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
    print('🎯 isMCQ: ${question.isMCQ}');
    print('🎯 isSCQ: ${question.isSCQ}');
    print('🎯 isMatching: ${question.isMatching}');
    print('🎯 isTrueFalse: ${question.isTrueFalse}');
    print('🎯 allowsMultipleAnswers: ${question.allowsMultipleAnswers}');

    // Questions nécessitant une saisie de texte
    if (question.requiresTextInput) {
      print('🎯 → Utilisation _buildTextAnswerInput');
      return _buildTextAnswerInput(question, quizProvider);
    }

    // Questions d'association (MATCHING)
    if (question.isMatching) {
      print('🎯 → Utilisation _buildMatchingQuestion');
      return _buildMatchingQuestion(question, quizProvider);
    }

    // Questions Vrai/Faux
    if (question.isTrueFalse) {
      print('🎯 → Utilisation _buildTrueFalseQuestion');
      return _buildTrueFalseQuestion(question, quizProvider);
    }

    // Questions à choix multiples (MCQ)
    if (question.isMCQ) {
      print('🎯 → Utilisation _buildMultipleChoiceQuestion');
      return _buildMultipleChoiceQuestion(question, quizProvider);
    }

    // Questions à choix unique (SCQ) - par défaut
    print('🎯 → Utilisation _buildSingleChoiceQuestion (défaut)');
    return _buildSingleChoiceQuestion(question, quizProvider);
  }

  // Widget pour les questions à choix unique (SCQ)
  Widget _buildSingleChoiceQuestion(
      Question question, QuizProvider quizProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisissez une seule réponse :',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 12),
        ...question.answers.map((answer) {
          final isSelected =
              quizProvider.isAnswerSelected(question.id, answer.id);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _selectSingleAnswer(question, answer, quizProvider),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        answer.text,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // Widget pour les questions à choix multiples (MCQ)
  Widget _buildMultipleChoiceQuestion(
      Question question, QuizProvider quizProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisissez une ou plusieurs réponses :',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 12),
        ...question.answers.map((answer) {
          final isSelected =
              quizProvider.isAnswerSelected(question.id, answer.id);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () =>
                  _toggleMultipleAnswer(question, answer, quizProvider),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        answer.text,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // Widget pour les questions Vrai/Faux
  Widget _buildTrueFalseQuestion(Question question, QuizProvider quizProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisissez Vrai ou Faux :',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: question.answers.map((answer) {
            final isSelected =
                quizProvider.isAnswerSelected(question.id, answer.id);
            final isTrue = answer.text.toLowerCase().contains('vrai') ||
                answer.text.toLowerCase().contains('true');

            return Expanded(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () =>
                      _selectSingleAnswer(question, answer, quizProvider),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? (isTrue ? Colors.green : Colors.red)
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? (isTrue ? Colors.green : Colors.red)
                              .withOpacity(0.1)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isTrue ? Icons.check : Icons.close,
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
                                ? (isTrue ? Colors.green : Colors.red)
                                : Colors.grey[700],
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
        }).toList(),
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
                quizProvider.isLastQuestion
                    ? (quizProvider.error != null &&
                            quizProvider.error!.contains('Mode démonstration')
                        ? 'Terminer la démonstration'
                        : 'Terminer le quiz')
                    : 'Suivant',
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
    print('🎯 Answer ID: ${answer.id}');
    print('🎯 Answer text: ${answer.text}');

    await quizProvider.saveAnswer(
      question.id,
      selectedAnswerIds: [answer.id],
    );
  }

  void _toggleMultipleAnswer(
      Question question, Answer answer, QuizProvider quizProvider) async {
    print('🎯 _toggleMultipleAnswer appelé');
    print('🎯 Question ID: ${question.id}');
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

    await quizProvider.saveAnswer(
      question.id,
      selectedAnswerIds: selectedAnswers,
    );
  }

  void _showSubmitDialog(QuizProvider quizProvider) {
    final isDemoMode = quizProvider.error != null &&
        quizProvider.error!.contains('Mode démonstration');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title:
            Text(isDemoMode ? 'Terminer la démonstration' : 'Terminer le quiz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDemoMode
                  ? 'Voulez-vous terminer cette démonstration du quiz ?'
                  : 'Êtes-vous sûr de vouloir terminer ce quiz ?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (!isDemoMode) ...[
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
            ] else
              Text(
                'En mode démonstration, aucune réponse n\'est sauvegardée.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange[700],
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
              if (isDemoMode) {
                // En mode démonstration, on retourne simplement à l'écran précédent
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Démonstration terminée'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } else {
                await _submitQuiz(quizProvider);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDemoMode ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(isDemoMode ? 'Terminer' : 'Terminer'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitQuiz(QuizProvider quizProvider) async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Soumission en cours...'),
            ],
          ),
        ),
      );

      await quizProvider.submitQuiz();

      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement
        Navigator.pop(context); // Retourner à l'écran précédent

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz soumis avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la soumission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
