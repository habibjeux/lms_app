import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class DateHelper {
  static String getFormattedActivityDate(DateTime? date,
      {bool isEndDate = false}) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = date.difference(now);

    // Pour les dates plus éloignées, afficher la date absolue
    final formatter = DateFormat('dd/MM/yyyy à HH:mm', 'fr');
    if (isEndDate) {
      return difference.isNegative
          ? 'Terminé le ${formatter.format(date)}'
          : 'Se termine le ${formatter.format(date)}';
    } else {
      return difference.isNegative
          ? 'Commencé le ${formatter.format(date)}'
          : 'Commence le ${formatter.format(date)}';
    }
  }

  // Alternative plus simple si vous voulez juste des dates absolues
  static String getSimpleFormattedDate(DateTime? date,
      {bool isEndDate = false}) {
    if (date == null) return '';

    final formatter = DateFormat('dd/MM/yyyy à HH:mm', 'fr');
    final now = DateTime.now();
    final isPast = date.isBefore(now);

    if (isEndDate) {
      return isPast
          ? 'Terminé le ${formatter.format(date)}'
          : 'Se termine le ${formatter.format(date)}';
    } else {
      return isPast
          ? 'Commencé le ${formatter.format(date)}'
          : 'Commence le ${formatter.format(date)}';
    }
  }
}
