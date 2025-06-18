import 'package:dio/dio.dart';

class ErrorHelper {
  /// Extrait un message d'erreur propre à partir d'une exception
  static String getCleanErrorMessage(dynamic error, [String? fallbackMessage]) {
    String defaultMessage = fallbackMessage ?? 'Une erreur est survenue';

    print('🧹 ErrorHelper: Nettoyage de l\'erreur: $error');

    // Si c'est une DioException, essayer d'extraire le message du serveur
    if (error is DioException && error.response?.data != null) {
      final responseData = error.response!.data;

      if (responseData is Map<String, dynamic>) {
        return responseData['error'] ??
            responseData['message'] ??
            responseData['detail'] ??
            defaultMessage;
      } else if (responseData is String) {
        return responseData;
      }
    }

    // Si c'est une Exception normale
    if (error is Exception) {
      final exceptionMessage = error.toString();
      if (exceptionMessage.startsWith('Exception: ')) {
        return exceptionMessage.substring(11); // Enlever "Exception: "
      } else {
        return exceptionMessage;
      }
    }

    // Pour tout autre type d'erreur
    final errorString = error.toString();

    // Nettoyer les préfixes communs indésirables
    if (errorString.startsWith('DioException')) {
      // Cas spécial : si le DioException contient "Error: MESSAGE", extraire juste MESSAGE
      // Utiliser DOTALL pour gérer les retours à la ligne
      final errorPattern = RegExp(r'Error:\s*(.+)', dotAll: true);
      final match = errorPattern.firstMatch(errorString);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }

      // Si on ne peut pas extraire un message propre de DioException,
      // utiliser le message par défaut
      return defaultMessage;
    }

    String cleanMessage = errorString.isNotEmpty ? errorString : defaultMessage;
    print('🧹 ErrorHelper: Message nettoyé: $cleanMessage');
    return cleanMessage;
  }
}
