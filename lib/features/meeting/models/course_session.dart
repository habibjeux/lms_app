class CourseSession {
  final String id;
  final String title;
  final String description;
  final String type;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> teaching;

  CourseSession({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.teaching,
  });

  factory CourseSession.fromJson(Map<String, dynamic> json) {
    return CourseSession(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      type: json['type'],
      status: json['status'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      teaching: json['teaching'],
    );
  }

  String get moduleTitle => teaching['module']['title'] ?? 'Module inconnu';
  String get levelTitle =>
      teaching['courseLevel']['level']['title'] ?? 'Niveau inconnu';
  String get courseTitle =>
      teaching['courseLevel']['course']['title'] ?? 'Cours inconnu';

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate.subtract(const Duration(minutes: 10))) &&
        now.isBefore(endDate);
  }

  bool get isPast {
    return DateTime.now().isAfter(endDate);
  }

  bool get isUpcoming {
    return DateTime.now()
        .isBefore(startDate.subtract(const Duration(minutes: 10)));
  }

  String formatSessionType() {
    switch (type) {
      case 'LIVE_COURSE':
        return 'Cours magistral';
      case 'TUTORIAL':
        return 'TD';
      case 'LAB':
        return 'TP';
      case 'Q_AND_A':
        return 'Questions/Réponses';
      default:
        return type;
    }
  }
}
