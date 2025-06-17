import '../../modules/models/activity.dart';
import '../../modules/models/enums/activity_type.dart';
import '../../modules/models/enums/activity_scope.dart';
import 'question.dart';

class Quiz extends Activity {
  final int duration; // en minutes
  final int maxAttempts;
  final double passingScore; // en pourcentage (0-1)
  final bool shuffleQuestions;
  final bool showCorrectAnswers;
  final List<Question> questions;
  final bool isDownloaded;

  Quiz({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required super.active,
    required super.title,
    required super.visible,
    required super.order,
    required super.moduleId,
    super.chapterId,
    required super.scope,
    super.startDate,
    super.endDate,
    required this.duration,
    required this.maxAttempts,
    required this.passingScore,
    required this.shuffleQuestions,
    required this.showCorrectAnswers,
    required this.questions,
    this.isDownloaded = false,
  }) : super(type: ActivityType.QUIZ);

  factory Quiz.fromJson(Map<String, dynamic> json) {
    try {
      if (json == null) {
        throw Exception('Les données JSON sont nulles');
      }

      List<Question> questions = [];
      if (json['questions'] != null) {
        if (json['questions'] is! List) {
          throw Exception('Le champ questions doit être une liste');
        }

        questions = (json['questions'] as List)
            .map((question) {
              try {
                if (question == null) {
                  return null;
                }
                Map<String, dynamic> questionCopy =
                    Map<String, dynamic>.from(question);
                questionCopy['quizId'] = json['id'];

                // Conserver le type original avant conversion
                String originalType = questionCopy['type'] ?? 'SCQ';

                // Convertir le type de question selon les codes API
                switch (originalType) {
                  case 'SCQ':
                  case 'MCQ':
                    questionCopy['type'] = 'MULTIPLE_CHOICE';
                    break;
                  case 'TRUE_FALSE':
                    questionCopy['type'] = 'TRUE_FALSE';
                    break;
                  case 'SHORT_ANSWER':
                    questionCopy['type'] = 'SHORT_ANSWER';
                    break;
                  case 'MATCHING':
                    questionCopy['type'] = 'MATCHING';
                    break;
                  default:
                    questionCopy['type'] = 'MULTIPLE_CHOICE';
                }

                return Question.fromJson(questionCopy);
              } catch (e) {
                print("Erreur lors du traitement d'une question: $e");
                return null;
              }
            })
            .whereType<Question>()
            .toList();
      }

      // Validation/conversion des valeurs avec des valeurs par défaut explicites
      DateTime? createdAt;
      try {
        createdAt = json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now();
      } catch (e) {
        createdAt = DateTime.now();
      }

      DateTime? updatedAt;
      try {
        updatedAt = json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now();
      } catch (e) {
        updatedAt = DateTime.now();
      }

      DateTime? deletedAt;
      try {
        deletedAt = json['deletedAt'] != null
            ? DateTime.parse(json['deletedAt'])
            : null;
      } catch (e) {
        deletedAt = null;
      }

      DateTime? startDate;
      try {
        startDate = json['startDate'] != null
            ? DateTime.parse(json['startDate'])
            : null;
      } catch (e) {
        startDate = null;
      }

      DateTime? endDate;
      try {
        endDate =
            json['endDate'] != null ? DateTime.parse(json['endDate']) : null;
      } catch (e) {
        endDate = null;
      }

      // Conversion sécurisée des valeurs numériques
      double passingScore = 0.6;
      if (json['passingScore'] != null) {
        if (json['passingScore'] is String) {
          passingScore = double.parse(json['passingScore']);
        } else if (json['passingScore'] is int) {
          passingScore = (json['passingScore'] as int) / 100.0;
        } else if (json['passingScore'] is double) {
          passingScore = json['passingScore'];
        }
      }

      return Quiz(
        id: json['id']?.toString() ?? '',
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
        active: json['active'] ?? true,
        title: json['title']?.toString() ?? '',
        visible: json['visible'] ?? true,
        order: json['order'] is int ? json['order'] : 0,
        moduleId: json['moduleId']?.toString() ?? '',
        chapterId: json['chapterId']?.toString(),
        scope: json['scope'] != null
            ? ActivityScope.values.firstWhere(
                (e) => e.toString() == 'ActivityScope.${json['scope']}',
                orElse: () => ActivityScope.MODULE,
              )
            : ActivityScope.MODULE,
        startDate: startDate,
        endDate: endDate,
        duration: json['duration'] is int ? json['duration'] : 60,
        maxAttempts: json['maxAttempts'] is int ? json['maxAttempts'] : 1,
        passingScore: passingScore,
        shuffleQuestions: json['shuffleQuestions'] ?? false,
        showCorrectAnswers: json['showCorrectAnswers'] ?? true,
        questions: questions,
        isDownloaded: json['isDownloaded'] ?? false,
      );
    } catch (e) {
      print("Erreur lors de la conversion du quiz: $e");
      rethrow;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'duration': duration,
      'maxAttempts': maxAttempts,
      'passingScore': passingScore,
      'shuffleQuestions': shuffleQuestions,
      'showCorrectAnswers': showCorrectAnswers,
      'questions': questions.map((question) => question.toJson()).toList(),
      'isDownloaded': isDownloaded,
    };
  }

  // Méthode pour créer une copie d'un quiz avec des paramètres modifiés
  Quiz copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? active,
    String? title,
    bool? visible,
    int? order,
    String? moduleId,
    String? chapterId,
    ActivityScope? scope,
    DateTime? startDate,
    DateTime? endDate,
    int? duration,
    int? maxAttempts,
    double? passingScore,
    bool? shuffleQuestions,
    bool? showCorrectAnswers,
    List<Question>? questions,
    bool? isDownloaded,
  }) {
    return Quiz(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      active: active ?? this.active,
      title: title ?? this.title,
      visible: visible ?? this.visible,
      order: order ?? this.order,
      moduleId: moduleId ?? this.moduleId,
      chapterId: chapterId ?? this.chapterId,
      scope: scope ?? this.scope,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      duration: duration ?? this.duration,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      passingScore: passingScore ?? this.passingScore,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      showCorrectAnswers: showCorrectAnswers ?? this.showCorrectAnswers,
      questions: questions ?? List.from(this.questions),
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  // Getters utiles
  bool get isAvailable {
    final now = DateTime.now();

    if (startDate != null && now.isBefore(startDate!)) {
      return false;
    }

    if (endDate != null && now.isAfter(endDate!)) {
      return false;
    }

    return visible;
  }

  bool get isExpired {
    return endDate != null && DateTime.now().isAfter(endDate!);
  }

  String get durationText {
    if (duration < 60) {
      return '$duration minutes';
    } else {
      final hours = duration ~/ 60;
      final minutes = duration % 60;

      if (minutes == 0) {
        return '$hours heure${hours > 1 ? 's' : ''}';
      } else {
        return '$hours heure${hours > 1 ? 's' : ''} $minutes minute${minutes > 1 ? 's' : ''}';
      }
    }
  }

  int get questionCount => questions.length;

  double get maxScore {
    return questions.fold(0.0, (sum, question) => sum + question.points);
  }
}
