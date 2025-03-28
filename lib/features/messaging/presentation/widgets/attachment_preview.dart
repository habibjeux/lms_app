import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class AttachmentPreview extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;

  const AttachmentPreview({
    super.key,
    required this.file,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    path.basename(file.path);
    final extension = path.extension(file.path).toLowerCase();
    final isImage = ['.jpg', '.jpeg', '.png', '.gif'].contains(extension);

    return Container(
      margin: const EdgeInsets.only(right: 8.0),
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Stack(
        children: [
          if (isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(7.0),
              child: Image.file(
                file,
                fit: BoxFit.cover,
                width: 80,
                height: 80,
              ),
            )
          else
            _buildFileIcon(),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileIcon() {
    final extension = path.extension(file.path).toLowerCase();
    IconData iconData;
    Color backgroundColor;

    if (['.pdf'].contains(extension)) {
      iconData = Icons.picture_as_pdf;
      backgroundColor = Colors.red[50]!;
    } else if (['.doc', '.docx'].contains(extension)) {
      iconData = Icons.description;
      backgroundColor = Colors.blue[50]!;
    } else if (['.xls', '.xlsx', '.csv'].contains(extension)) {
      iconData = Icons.table_chart;
      backgroundColor = Colors.green[50]!;
    } else if (['.ppt', '.pptx'].contains(extension)) {
      iconData = Icons.slideshow;
      backgroundColor = Colors.orange[50]!;
    } else if (['.zip', '.rar'].contains(extension)) {
      iconData = Icons.archive;
      backgroundColor = Colors.purple[50]!;
    } else {
      iconData = Icons.insert_drive_file;
      backgroundColor = Colors.grey[50]!;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(7.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 32,
            color: backgroundColor == Colors.grey[50]
                ? Colors.grey
                : backgroundColor.withAlpha(255),
          ),
          const SizedBox(height: 4),
          Text(
            extension.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
