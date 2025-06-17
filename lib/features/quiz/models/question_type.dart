enum QuestionType {
  MULTIPLE_CHOICE,
  TRUE_FALSE,
  SHORT_ANSWER,
  ESSAY,
  MATCHING,
  FILL_BLANK
}

extension QuestionTypeExtension on QuestionType {
  String get displayName {
    switch (this) {
      case QuestionType.MULTIPLE_CHOICE:
        return 'Choix multiple';
      case QuestionType.TRUE_FALSE:
        return 'Vrai/Faux';
      case QuestionType.SHORT_ANSWER:
        return 'Réponse courte';
      case QuestionType.ESSAY:
        return 'Dissertation';
      case QuestionType.MATCHING:
        return 'Association';
      case QuestionType.FILL_BLANK:
        return 'Texte à trous';
    }
  }
}

QuestionType questionTypeFromString(String type) {
  return QuestionType.values.firstWhere(
    (e) => e.toString() == 'QuestionType.$type',
    orElse: () => QuestionType.MULTIPLE_CHOICE,
  );
}
