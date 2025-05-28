import 'dart:io';
import 'package:flutter/material.dart';
import 'package:docx_viewer/docx_viewer.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:open_file/open_file.dart';

class DocumentViewerPage extends StatefulWidget {
  final String? filePath;
  final String? url;
  final String title;
  final bool isNetwork;

  const DocumentViewerPage({
    super.key,
    this.filePath,
    this.url,
    required this.title,
    required this.isNetwork,
  });

  @override
  State<DocumentViewerPage> createState() => _DocumentViewerPageState();
}

class _DocumentViewerPageState extends State<DocumentViewerPage> {
  final Dio _dio = Dio();
  bool _isLoading = true;
  String? _errorMessage;
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      if (widget.isNetwork) {
        await _downloadDocument();
      } else {
        await _loadLocalDocument();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _downloadDocument() async {
    try {
      // Afficher le progrès de téléchargement
      setState(() {
        _isLoading = true;
      });

      // Créer un fichier temporaire
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(widget.url!);
      _localFilePath = path.join(tempDir.path, fileName);

      // Télécharger le document
      await _dio.download(
        widget.url!,
        _localFilePath!,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            debugPrint('Téléchargement: $progress%');
          }
        },
      );

      // Vérifier que le fichier existe
      if (await File(_localFilePath!).exists()) {
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('Le fichier téléchargé n\'existe pas');
      }
    } catch (e) {
      throw Exception('Erreur lors du téléchargement: $e');
    }
  }

  Future<void> _loadLocalDocument() async {
    try {
      final file = File(widget.filePath!);
      if (await file.exists()) {
        _localFilePath = widget.filePath;
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('Le fichier n\'existe pas');
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (!_isLoading &&
              _errorMessage == null &&
              _localFilePath != null) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareDocument,
            ),
            if (widget.isNetwork)
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: _saveToDevice,
              ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'open_external',
                  child: Row(
                    children: [
                      Icon(Icons.open_in_new),
                      SizedBox(width: 8),
                      Text('Ouvrir avec une autre app'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('Actualiser'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement du document...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _retryLoading,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (widget.isNetwork)
                TextButton(
                  onPressed: _openExternalBrowser,
                  child: const Text('Ouvrir dans le navigateur'),
                ),
            ],
          ),
        ),
      );
    }

    if (_localFilePath != null) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: DocxView(
          filePath: _localFilePath!,
        ),
      );
    }

    return const Center(
      child: Text('Aucun document à afficher'),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'open_external':
        _openWithSystemApp();
        break;
      case 'refresh':
        _retryLoading();
        break;
    }
  }

  void _retryLoading() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _loadDocument();
  }

  void _shareDocument() {
    if (_localFilePath != null) {
      Share.shareXFiles([XFile(_localFilePath!)], subject: widget.title);
    } else if (widget.isNetwork && widget.url != null) {
      Share.share(widget.url!, subject: widget.title);
    }
  }

  Future<void> _saveToDevice() async {
    if (_localFilePath == null) return;

    try {
      // Afficher dialogue de sauvegarde
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Sauvegarde...'),
            ],
          ),
        ),
      );

      // Obtenir le répertoire de documents
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${widget.title.replaceAll(RegExp(r'[^\w\s-]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.docx';
      final newFilePath = path.join(directory.path, fileName);

      // Copier le fichier
      await File(_localFilePath!).copy(newFilePath);

      // Fermer le dialogue
      Navigator.pop(context);

      // Afficher confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document sauvegardé: $fileName'),
            action: SnackBarAction(
              label: 'Ouvrir',
              onPressed: () => _openWithSystemApp(newFilePath),
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Fermer le dialogue
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openWithSystemApp([String? specificPath]) async {
    try {
      final pathToOpen = specificPath ?? _localFilePath;
      if (pathToOpen != null) {
        final result = await OpenFile.open(pathToOpen);
        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Impossible d\'ouvrir: ${result.message}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openExternalBrowser() async {
    if (widget.url != null) {
      try {
        Uri.parse(widget.url!);
        // Vous pouvez utiliser url_launcher ici
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ouverture dans le navigateur...'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Nettoyer les fichiers temporaires si nécessaire
    if (widget.isNetwork && _localFilePath != null) {
      File(_localFilePath!).delete().catchError((e) {
        debugPrint('Erreur lors de la suppression du fichier temporaire: $e');
      });
    }
    super.dispose();
  }
}
