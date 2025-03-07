import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../../models/enums/question_type.dart';

class QuestionCard extends StatefulWidget {
  final Question question;
  final int index;
  final String? selectedAnswerId;
  final String? textAnswer;
  final Function(String)? onAnswerSelected;
  final Function(String)? onTextAnswerChanged;

  const QuestionCard({
    super.key,
    required this.question,
    required this.index,
    this.selectedAnswerId,
    this.textAnswer,
    this.onAnswerSelected,
    this.onTextAnswerChanged,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.text = widget.textAnswer ?? '';
  }

  @override
  void didUpdateWidget(QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.textAnswer != oldWidget.textAnswer) {
      _textController.text = widget.textAnswer ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type de question et points
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuestionTypeBadge(),
                Text(
                  '${widget.question.points} ${widget.question.points > 1 ? 'points' : 'point'}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Texte de la question
            Text(
              widget.question.text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Réponses
            _buildAnswersWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionTypeBadge() {
    String text;
    Color color;

    switch (widget.question.type) {
      case QuestionType.MCQ:
        text = 'Choix multiple';
        color = Colors.blue;
        break;
      case QuestionType.SCQ:
        text = 'Choix unique';
        color = Colors.green;
        break;
      case QuestionType.TRUE_FALSE:
        text = 'Vrai/Faux';
        color = Colors.orange;
        break;
      case QuestionType.SHORT_ANSWER:
        text = 'Réponse courte';
        color = Colors.purple;
        break;
      case QuestionType.MATCHING:
        text = 'Association';
        color = Colors.teal;
        break;
    }

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

  Widget _buildAnswersWidget() {
    if (widget.question.isShortAnswer) {
      return _buildShortAnswerWidget();
    } else if (widget.question.type == QuestionType.MATCHING) {
      return _buildMatchingWidget();
    } else {
      return _buildChoiceQuestionsWidget();
    }
  }

  Widget _buildChoiceQuestionsWidget() {
    return Column(
      children: [
        for (final answer in widget.question.answers)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: widget.selectedAnswerId == answer.id
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: widget.selectedAnswerId == answer.id
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withOpacity(0.3),
                width: widget.selectedAnswerId == answer.id ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: () {
                if (widget.onAnswerSelected != null) {
                  widget.onAnswerSelected!(answer.id);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    widget.question.isSingleChoice ||
                            widget.question.isTrueFalse
                        ? Radio<String>(
                            value: answer.id,
                            groupValue: widget.selectedAnswerId,
                            onChanged: (value) {
                              if (value != null &&
                                  widget.onAnswerSelected != null) {
                                widget.onAnswerSelected!(value);
                              }
                            },
                          )
                        : Checkbox(
                            value: widget.selectedAnswerId == answer.id,
                            onChanged: (value) {
                              if (value == true &&
                                  widget.onAnswerSelected != null) {
                                widget.onAnswerSelected!(answer.id);
                              }
                            },
                          ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(answer.text),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShortAnswerWidget() {
    return TextField(
      controller: _textController,
      decoration: const InputDecoration(
        hintText: 'Tapez votre réponse ici...',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      onChanged: widget.onTextAnswerChanged,
    );
  }

  Widget _buildMatchingWidget() {
    // Cas spécial pour les questions d'association
    return Column(
      children: [
        for (int i = 0; i < widget.question.answers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(widget.question.answers[i].text),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    value: widget.selectedAnswerId,
                    items: widget.question.answers.map((answer) {
                      return DropdownMenuItem<String>(
                        value: answer.id,
                        child: Text(
                          answer.text,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null && widget.onAnswerSelected != null) {
                        widget.onAnswerSelected!(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
