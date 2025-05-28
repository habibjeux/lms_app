import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

class ImageViewerPage extends StatefulWidget {
  final String? filePath;
  final String? imageUrl;
  final String title;
  final bool isNetwork;

  const ImageViewerPage({
    super.key,
    this.filePath,
    this.imageUrl,
    required this.title,
    required this.isNetwork,
  });

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  final TransformationController _transformationController =
      TransformationController();
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showControls
          ? AppBar(
              title: Text(widget.title),
              backgroundColor: Colors.black.withOpacity(0.7),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareImage,
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_in),
                  onPressed: _zoomIn,
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_out),
                  onPressed: _zoomOut,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _resetZoom,
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: InteractiveViewer(
          transformationController: _transformationController,
          panEnabled: true,
          scaleEnabled: true,
          minScale: 0.1,
          maxScale: 5.0,
          child: Center(
            child: widget.isNetwork
                ? CachedNetworkImage(
                    imageUrl: widget.imageUrl!,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur de chargement',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Retour'),
                        ),
                      ],
                    ),
                  )
                : Image.file(
                    File(widget.filePath!),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur de chargement',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Retour'),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale < 5.0) {
      _transformationController.value = Matrix4.identity()
        ..scale(currentScale * 1.2);
    }
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 0.1) {
      _transformationController.value = Matrix4.identity()
        ..scale(currentScale * 0.8);
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _shareImage() {
    if (widget.isNetwork && widget.imageUrl != null) {
      Share.share(widget.imageUrl!, subject: widget.title);
    } else if (widget.filePath != null) {
      Share.shareXFiles([XFile(widget.filePath!)], subject: widget.title);
    }
  }
}
