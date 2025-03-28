import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/message.dart';

class AttachmentViewer extends StatefulWidget {
  final MessageAttachment attachment;

  const AttachmentViewer({super.key, required this.attachment});

  @override
  State<AttachmentViewer> createState() => _AttachmentViewerState();
}

class _AttachmentViewerState extends State<AttachmentViewer> {
  bool _isLoading = false;
  String? _localPath;
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _prepareAttachment();
  }

  Future<void> _prepareAttachment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.attachment.isLocal) {
        // Si l'attachement est déjà local, utiliser directement son chemin
        _localPath = widget.attachment.localPath;
      } else {
        // Sinon, télécharger le fichier
        _localPath = await _downloadAttachment();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _downloadAttachment() async {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/${widget.attachment.filename}';

    // Vérifier si le fichier existe déjà
    final file = File(filePath);
    if (await file.exists()) {
      return filePath;
    }

    // Télécharger le fichier
    await _dio.download(
      widget.attachment.fileUrl,
      filePath,
      onReceiveProgress: (received, total) {
        // Option: Afficher une progress bar
      },
    );

    return filePath;
  }

  Future<void> _shareAttachment() async {
    if (_localPath == null) return;

    await Share.shareXFiles(
      [XFile(_localPath!)],
      text: 'Partager ${widget.attachment.filename}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.attachment.filename),
        actions: [
          if (_localPath != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareAttachment,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAttachmentView(),
    );
  }

  Widget _buildAttachmentView() {
    if (_localPath == null) {
      return const Center(
        child: Text('Impossible de charger la pièce jointe'),
      );
    }

    if (widget.attachment.isImage) {
      return _buildImageViewer();
    } else if (widget.attachment.isPdf) {
      return _buildPdfViewer();
    } else {
      return _buildGenericFileViewer();
    }
  }

  Widget _buildImageViewer() {
    final imageFile = File(_localPath!);

    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 3.0,
        child: Image.file(imageFile),
      ),
    );
  }

  Widget _buildPdfViewer() {
    return PDFView(
      filePath: _localPath!,
      enableSwipe: true,
      swipeHorizontal: true,
      autoSpacing: false,
      pageFling: false,
      pageSnap: true,
      defaultPage: 0,
      fitPolicy: FitPolicy.BOTH,
      preventLinkNavigation: false,
      onError: (error) {
        print('Error: $error');
      },
      onPageError: (page, error) {
        print('Error on page $page: $error');
      },
    );
  }

  Widget _buildGenericFileViewer() {
    // Pour les fichiers qui ne peuvent pas être prévisualisés directement
    IconData iconData;
    Color iconColor;

    if (widget.attachment.mimeType.contains('word')) {
      iconData = Icons.description;
      iconColor = Colors.blue;
    } else if (widget.attachment.mimeType.contains('excel') ||
        widget.attachment.mimeType.contains('sheet')) {
      iconData = Icons.table_chart;
      iconColor = Colors.green;
    } else if (widget.attachment.mimeType.contains('presentation') ||
        widget.attachment.mimeType.contains('powerpoint')) {
      iconData = Icons.slideshow;
      iconColor = Colors.orange;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 120,
            color: iconColor,
          ),
          const SizedBox(height: 16),
          Text(
            widget.attachment.filename,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _formatFileSize(widget.attachment.fileSize),
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _shareAttachment,
            child: const Text('Partager le fichier'),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
