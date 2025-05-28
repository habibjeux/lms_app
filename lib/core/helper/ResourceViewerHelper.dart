import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

import '../viewers/document_viewer_page.dart';
import '../viewers/image_viewer_page.dart';
import '../viewers/pdf_viewer_page.dart';
import '../viewers/video_viewer_page.dart';

enum ResourceType {
  pdf,
  image,
  video,
  document, // Word documents (.doc, .docx)
  other // Tous les autres types seront ouverts avec le système
}

class ResourceViewerHelper {
  static final Dio _dio = Dio();

  /// Détermine le type de ressource basé sur l'extension ou le type MIME
  static ResourceType getResourceType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    final mimeType = lookupMimeType(filePath);

    // Images
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg']
            .contains(extension) ||
        (mimeType?.startsWith('image/') ?? false)) {
      return ResourceType.image;
    }

    // PDFs
    if (extension == '.pdf' || mimeType == 'application/pdf') {
      return ResourceType.pdf;
    }

    // Vidéos
    if (['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm', '.mkv']
            .contains(extension) ||
        (mimeType?.startsWith('video/') ?? false)) {
      return ResourceType.video;
    }

    // Documents Word
    if (['.doc', '.docx'].contains(extension) ||
        [
          'application/msword',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        ].contains(mimeType)) {
      return ResourceType.document;
    }

    // Tous les autres types (Excel, PowerPoint, audio, etc.) seront ouverts avec le système
    return ResourceType.other;
  }

  static bool _hasFileExtension(String url) {
    final extensions = [
      '.pdf',
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.mp4',
      '.avi',
      '.mov',
      '.doc',
      '.docx'
    ];
    return extensions.any((ext) => url.toLowerCase().contains(ext));
  }

  /// Ouvre une ressource (locale ou réseau)
  static Future<void> openResource({
    required BuildContext context,
    required String resourcePath,
    String? title,
    bool forceDownload = false,
  }) async {
    try {
      final resourceType = getResourceType(resourcePath);

      // Si c'est une URL réseau
      if (resourcePath.startsWith('http')) {
        await _openNetworkResource(
          context: context,
          url: resourcePath,
          resourceType: resourceType,
          title: title,
          forceDownload: forceDownload,
        );
      } else {
        // Si c'est un fichier local
        await _openLocalResource(
          context: context,
          filePath: resourcePath,
          resourceType: resourceType,
          title: title,
        );
      }
    } catch (e) {
      _showErrorDialog(
          context, 'Erreur lors de l\'ouverture de la ressource: $e');
    }
  }

  /// Ouvre une ressource réseau
  static Future<void> _openNetworkResource({
    required BuildContext context,
    required String url,
    required ResourceType resourceType,
    String? title,
    bool forceDownload = false,
  }) async {
    switch (resourceType) {
      case ResourceType.pdf:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerPage(
              url: url,
              title: title ?? 'Document PDF',
              isNetwork: true,
            ),
          ),
        );
        break;

      case ResourceType.image:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageViewerPage(
              imageUrl: url,
              title: title ?? 'Image',
              isNetwork: true,
            ),
          ),
        );
        break;

      case ResourceType.video:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoViewerPage(
              videoUrl: url,
              title: title ?? 'Vidéo',
              isNetwork: true,
            ),
          ),
        );
        break;

      case ResourceType.document:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentViewerPage(
              url: url,
              title: title ?? 'Document Word',
              isNetwork: true,
            ),
          ),
        );
        break;

      default:
        // Pour tous les autres types, télécharger puis ouvrir avec le système
        await _downloadAndOpen(context, url, title);
    }
  }

  /// Ouvre une ressource locale
  static Future<void> _openLocalResource({
    required BuildContext context,
    required String filePath,
    required ResourceType resourceType,
    String? title,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      _showErrorDialog(context, 'Le fichier n\'existe pas: $filePath');
      return;
    }

    switch (resourceType) {
      case ResourceType.pdf:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerPage(
              filePath: filePath,
              title: title ?? 'Document PDF',
              isNetwork: false,
            ),
          ),
        );
        break;

      case ResourceType.image:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageViewerPage(
              filePath: filePath,
              title: title ?? 'Image',
              isNetwork: false,
            ),
          ),
        );
        break;

      case ResourceType.video:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoViewerPage(
              filePath: filePath,
              title: title ?? 'Vidéo',
              isNetwork: false,
            ),
          ),
        );
        break;

      case ResourceType.document:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentViewerPage(
              filePath: filePath,
              title: title ?? 'Document Word',
              isNetwork: false,
            ),
          ),
        );
        break;

      default:
        // Pour tous les autres types, ouvrir avec l'application système
        await _openWithSystemApp(filePath);
    }
  }

  /// Télécharge un fichier et l'ouvre
  static Future<void> _downloadAndOpen(
      BuildContext context, String url, String? title) async {
    try {
      // Demander permission de stockage
      final permission = await Permission.storage.request();
      if (permission != PermissionStatus.granted) {
        _showErrorDialog(context, 'Permission de stockage requise');
        return;
      }

      // Afficher dialogue de progression
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Téléchargement...'),
            ],
          ),
        ),
      );

      // Obtenir le répertoire de téléchargement
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(url);
      final filePath = path.join(directory.path, fileName);

      // Télécharger le fichier
      await _dio.download(url, filePath);

      // Fermer le dialogue de progression
      Navigator.pop(context);

      // Ouvrir le fichier téléchargé
      await _openWithSystemApp(filePath);
    } catch (e) {
      Navigator.pop(context); // Fermer le dialogue de progression
      _showErrorDialog(context, 'Erreur lors du téléchargement: $e');
    }
  }

  /// Ouvre un fichier avec l'application système par défaut
  static Future<void> _openWithSystemApp(String filePath) async {
    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done) {
      throw Exception('Impossible d\'ouvrir le fichier: ${result.message}');
    }
  }

  /// Lance une URL dans le navigateur par défaut
  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Impossible d\'ouvrir l\'URL: $url');
    }
  }

  /// Affiche un dialogue d'erreur
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Vérifie si une URL/fichier est accessible
  static Future<bool> isResourceAccessible(String resourcePath) async {
    try {
      if (resourcePath.startsWith('http')) {
        final response = await _dio.head(resourcePath);
        return response.statusCode == 200;
      } else {
        return await File(resourcePath).exists();
      }
    } catch (e) {
      return false;
    }
  }

  /// Obtient les informations sur une ressource
  static Future<Map<String, dynamic>> getResourceInfo(
      String resourcePath) async {
    final resourceType = getResourceType(resourcePath);

    if (resourcePath.startsWith('http')) {
      try {
        final response = await _dio.head(resourcePath);
        return {
          'type': resourceType,
          'size': response.headers.value('content-length'),
          'mimeType': response.headers.value('content-type'),
          'lastModified': response.headers.value('last-modified'),
        };
      } catch (e) {
        return {'type': resourceType, 'error': e.toString()};
      }
    } else {
      final file = File(resourcePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return {
          'type': resourceType,
          'size': stat.size,
          'lastModified': stat.modified,
          'path': resourcePath,
        };
      }
    }

    return {'type': resourceType, 'exists': false};
  }
}
