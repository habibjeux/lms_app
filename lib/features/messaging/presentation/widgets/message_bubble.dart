import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/message.dart';
import '../../providers/messaging_provider.dart';
import 'attachment_viewer.dart';
import '../../../auth/models/user.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: isMe && !isPending && !isError
                      ? () => _showDeleteDialog(context)
                      : null,
                  child: _buildMessageContent(context),
                ),
                if (isPending || isError) _buildStatusIndicator(),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isMe) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final user = isMe ? message.sender : message.receiver;
    final initials = _getInitials(user);

    return CircleAvatar(
      radius: 16,
      backgroundColor: isMe ? Colors.blue : Colors.grey,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.attachments.isNotEmpty) _buildAttachments(context),
          if (message.content.isNotEmpty) ...[
            if (message.attachments.isNotEmpty) const SizedBox(height: 8),
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPending)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (isError)
            const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 4),
          Text(
            isPending ? 'Envoi...' : 'Erreur',
            style: TextStyle(
              color: isError ? Colors.red : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachments(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: message.attachments.map((attachment) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildAttachmentPreview(attachment, context),
        );
      }).toList(),
    );
  }

  Widget _buildAttachmentPreview(
      MessageAttachment attachment, BuildContext context) {
    if (attachment.isImage) {
      return _buildImage(attachment);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AttachmentViewer(attachment: attachment),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              attachment.isPdf ? Icons.picture_as_pdf : Icons.attach_file,
              color: attachment.isPdf ? Colors.red : Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.filename,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatFileSize(attachment.fileSize),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(MessageAttachment attachment) {
    return FutureBuilder<bool>(
      future: _checkFileExists(attachment.localPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingContainer();
        }

        final bool fileExists = snapshot.data ?? false;
        final String imageUrl = fileExists && attachment.localPath != null
            ? 'file://${attachment.localPath}'
            : attachment.fileUrl;

        return GestureDetector(
          onTap: () {
            if (attachment.localPath != null && fileExists) {
              _openAttachment(attachment);
            } else if (attachment.fileUrl.isNotEmpty) {
              _openAttachment(attachment);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildLoadingContainer();
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Erreur de chargement de l\'image: $error');
                return Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.error_outline, color: Colors.red),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorContainer() {
    return Container(
      width: 200,
      height: 150,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, size: 32, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            'Image non disponible',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContainer() {
    return Container(
      width: 200,
      height: 150,
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Future<bool> _checkFileExists(String? filePath) async {
    if (filePath == null) return false;
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      debugPrint('Erreur lors de la vérification du fichier: $e');
      return false;
    }
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

  String _getInitials(User? user) {
    if (user == null) return '?';

    final firstName = user.firstName;
    final lastName = user.lastName;

    if (firstName.isEmpty && lastName.isEmpty) return '?';
    if (firstName.isEmpty) return lastName[0].toUpperCase();
    if (lastName.isEmpty) return firstName[0].toUpperCase();

    return '${firstName[0]}${lastName[0]}'.toUpperCase();
  }

  void _openAttachment(MessageAttachment attachment) {
    // Implementation of _openAttachment method
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le message'),
        content: const Text('Voulez-vous vraiment supprimer ce message ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = Provider.of<MessagingProvider>(context, listen: false);
      await provider.deleteMessage(message.discussionId, message.id);
    }
  }
}
