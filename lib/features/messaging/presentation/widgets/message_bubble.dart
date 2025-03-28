import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/message.dart';
import 'attachment_viewer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isPending;
  final bool isError;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isPending = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) _buildAvatar(),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: isMe
                        ? Theme.of(context)
                            .primaryColor
                            .withOpacity(isPending ? 0.7 : 1.0)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (message.content.isNotEmpty)
                        Text(
                          message.content,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      if (message.attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildAttachments(context),
                      ],
                      const SizedBox(height: 4),
                      _buildTimeAndStatus(context),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isMe) _buildAvatar(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return isMe
        ? const SizedBox(width: 32, height: 32) // Placeholder pour l'alignement
        : CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey,
            child: Text(
              message.sender?.firstName.substring(0, 1).toUpperCase() ?? '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          );
  }

  Widget _buildAttachments(BuildContext context) {
    final attachments = message.attachments;
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: attachments.map((attachment) {
        return GestureDetector(
          onTap: () {
            // Ouvrir la visualisation de la pièce jointe
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AttachmentViewer(attachment: attachment),
              ),
            );
          },
          child: _buildAttachmentThumbnail(attachment),
        );
      }).toList(),
    );
  }

  Widget _buildAttachmentThumbnail(MessageAttachment attachment) {
    if (attachment.isImage) {
      // Afficher une miniature de l'image
      if (attachment.isLocal) {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            image: DecorationImage(
              image: FileImage(File(attachment.localPath!)),
              fit: BoxFit.cover,
            ),
          ),
        );
      } else {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            image: DecorationImage(
              image: NetworkImage(
                  "${dotenv.env['SERVER_URL']!}${attachment.fileUrl}"),
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    } else {
      // Afficher une icône pour les autres types de fichiers
      IconData iconData;
      Color iconColor;

      if (attachment.isPdf) {
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
      } else if (attachment.mimeType.contains('word')) {
        iconData = Icons.description;
        iconColor = Colors.blue;
      } else if (attachment.mimeType.contains('excel') ||
          attachment.mimeType.contains('sheet')) {
        iconData = Icons.table_chart;
        iconColor = Colors.green;
      } else if (attachment.mimeType.contains('presentation') ||
          attachment.mimeType.contains('powerpoint')) {
        iconData = Icons.slideshow;
        iconColor = Colors.orange;
      } else {
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
      }

      return Container(
        width: 120,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              color: iconColor,
              size: 40,
            ),
            const SizedBox(height: 4),
            Text(
              attachment.filename,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              _formatFileSize(attachment.fileSize),
              style: TextStyle(
                fontSize: 8,
                color: isMe ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTimeAndStatus(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final time = timeFormat.format(message.createdAt);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: TextStyle(
            fontSize: 10,
            color: isMe ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(width: 4),
        if (isMe) ...[
          if (isPending)
            const Icon(
              Icons.access_time,
              size: 12,
              color: Colors.white70,
            )
          else if (isError)
            const Icon(
              Icons.error_outline,
              size: 12,
              color: Colors.redAccent,
            )
          else if (message.readAt != null)
            const Icon(
              Icons.done_all,
              size: 12,
              color: Colors.white,
            )
          else
            const Icon(
              Icons.done,
              size: 12,
              color: Colors.white70,
            ),
        ],
      ],
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
