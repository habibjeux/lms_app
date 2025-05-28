import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';

class PDFViewerPage extends StatefulWidget {
  final String? filePath;
  final String? url;
  final String title;
  final bool isNetwork;

  const PDFViewerPage({
    super.key,
    this.filePath,
    this.url,
    required this.title,
    required this.isNetwork,
  });

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => _pdfViewerController.zoomLevel += 0.5,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () => _pdfViewerController.zoomLevel -= 0.5,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareDocument,
          ),
        ],
      ),
      body: Stack(
        children: [
          widget.isNetwork
              ? SfPdfViewer.network(
                  widget.url!,
                  controller: _pdfViewerController,
                  onDocumentLoaded: (details) {
                    setState(() => _isLoading = false);
                  },
                  onDocumentLoadFailed: (details) {
                    setState(() {
                      _isLoading = false;
                      _errorMessage = details.error;
                    });
                  },
                )
              : SfPdfViewer.file(
                  File(widget.filePath!),
                  controller: _pdfViewerController,
                  onDocumentLoaded: (details) {
                    setState(() => _isLoading = false);
                  },
                  onDocumentLoadFailed: (details) {
                    setState(() {
                      _isLoading = false;
                      _errorMessage = details.error;
                    });
                  },
                ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: $_errorMessage'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => _buildControlPanel(),
          );
        },
        child: const Icon(Icons.settings),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.first_page),
            title: const Text('Première page'),
            onTap: () {
              _pdfViewerController.firstPage();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.last_page),
            title: const Text('Dernière page'),
            onTap: () {
              _pdfViewerController.lastPage();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Rechercher'),
            onTap: () {
              _pdfViewerController.searchText('');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _shareDocument() {
    if (widget.isNetwork && widget.url != null) {
      Share.share(widget.url!, subject: widget.title);
    } else if (widget.filePath != null) {
      Share.shareXFiles([XFile(widget.filePath!)], subject: widget.title);
    }
  }
}
