import '../../modules/models/enums/activity_type.dart';
import '../../modules/models/enums/activity_scope.dart';
import '../../modules/models/activity.dart';
import 'question.dart';

class Quiz extends Activity {
  final int duration; // en minutes
  final int maxAttempts;
  final double passingScore; // en pourcentage (0-1)
  final double maxScore;
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
    required this.maxScore,
    required this.shuffleQuestions,
    required this.showCorrectAnswers,
    required this.questions,
    this.isDownloaded = false,
  }) : super(type: ActivityType.QUIZ);

  factory Quiz.fromJson(Map<String, dynamic> json) {
    try {
      List<Question> questions = [];

      if (json['questions'] != null) {
        questions = (json['questions'] as List)
            .map((question) {
              try {
                Map<String, dynamic> questionCopy =
                    Map<String, dynamic>.from(question);
                questionCopy['quizId'] = json['id'];
                return Question.fromJson(questionCopy);
              } catch (e) {
                print("Erreur lors du traitement d'une question: $e");
                // Retourner une question par défaut ou null si nécessaire
                return null;
              }
            })
            .whereType<Question>()
            .toList(); // Filtre les valeurs null
      }

      // Validation/conversion des valeurs avec des valeurs par défaut explicites
      DateTime? createdAt;
      try {
        createdAt = json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now();
      } catch (e) {
        print("Erreur de parsing de createdAt: $e");
        createdAt = DateTime.now();
      }

      DateTime? updatedAt;
      try {
        updatedAt = json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now();
      } catch (e) {
        print("Erreur de parsing de updatedAt: $e");
        updatedAt = DateTime.now();
      }

      DateTime? deletedAt;
      try {
        deletedAt = json['deletedAt'] != null
            ? DateTime.parse(json['deletedAt'])
            : null;
      } catch (e) {
        print("Erreur de parsing de deletedAt: $e");
        deletedAt = null;
      }

      DateTime? startDate;
      try {
        startDate = json['startDate'] != null
            ? DateTime.parse(json['startDate'])
            : null;
      } catch (e) {
        print("Erreur de parsing de startDate: $e");
        startDate = null;
      }

      DateTime? endDate;
      try {
        endDate =
            json['endDate'] != null ? DateTime.parse(json['endDate']) : null;
      } catch (e) {
        print("Erreur de parsing de endDate: $e");
        endDate = null;
      }

      // Conversion sécurisée des valeurs numériques
      double passingScore = 0.6;
      if (json['passingScore'] != null) {
        if (json['passingScore'] is int) {
          passingScore = (json['passingScore'] as int) / 100.0;
        } else if (json['passingScore'] is double) {
          passingScore = json['passingScore'];
        }
      }

      double maxScore = 100.0;
      if (json['maxScore'] != null) {
        if (json['maxScore'] is int) {
          maxScore = (json['maxScore'] as int).toDouble();
        } else if (json['maxScore'] is double) {
          maxScore = json['maxScore'];
        }
      }

      return Quiz(
        id: json['id'] ?? '',
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
        active: json['active'] ?? true,
        title: json['title'] ?? '',
        visible: json['visible'] ?? true,
        order: json['order'] ?? 0,
        moduleId: json['moduleId'] ?? '',
        chapterId: json['chapterId'],
        scope: json['scope'] != null
            ? activityScopeFromString(json['scope'])
            : ActivityScope.MODULE,
        startDate: startDate,
        endDate: endDate,
        duration: json['duration'] ?? 60,
        maxAttempts: json['maxAttempts'] ?? 1,
        passingScore: passingScore,
        maxScore: maxScore,
        shuffleQuestions: json['shuffleQuestions'] ?? false,
        showCorrectAnswers: json['showCorrectAnswers'] ?? true,
        questions: questions,
        isDownloaded: json['isDownloaded'] ?? false,
      );
    } catch (e) {
      print("Erreur lors de la conversion du quiz: $e");
      // Si tout échoue, peut-être retourner un quiz "vide" ou relancer l'exception
      rethrow; // ou retourner un Quiz par défaut
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
      'maxScore': maxScore,
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
    double? maxScore,
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
      maxScore: maxScore ?? this.maxScore,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      showCorrectAnswers: showCorrectAnswers ?? this.showCorrectAnswers,
      questions: questions ?? List.from(this.questions),
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

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

  double get totalPoints {
    return questions.fold(0, (sum, question) => sum + question.points);
  }
}
