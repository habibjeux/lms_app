import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';

class FileHelper {
  static Future<void> openResource(
      String? localPath, String? url, String mimeType) async {
    if (localPath != null) {
      try {
        final result = await OpenFile.open(localPath);
        if (result.type != ResultType.done) {
          throw Exception('Impossible d\'ouvrir le fichier: ${result.message}');
        }
      } catch (e) {
        throw Exception('Erreur lors de l\'ouverture du fichier: $e');
      }
    } else if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Impossible d\'ouvrir l\'URL: $url');
      }
    } else {
      throw Exception('Aucun chemin ou URL fourni');
    }
  }
}
