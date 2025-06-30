import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/message.dart';
import '../../providers/messaging_provider.dart';
import 'attachment_viewer.dart';
import '../../../auth/models/user.dart';
import 'dart:math' as math;

class MessageBubble extends StatefulWidget {
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
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: widget.isMe ? const Offset(0.3, 0) : const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Déclencher les animations avec un délai
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _slideController.forward();
        _scaleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Row(
            mainAxisAlignment:
                widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isMe) ...[
                _buildModernAvatar(),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: widget.isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onLongPress:
                          widget.isMe && !widget.isPending && !widget.isError
                              ? () => _showDeleteDialog(context)
                              : null,
                      child: _buildModernMessageContent(context),
                    ),
                    if (widget.isPending || widget.isError)
                      _buildModernStatusIndicator(),
                    _buildTimestamp(),
                  ],
                ),
              ),
              if (widget.isMe) ...[
                const SizedBox(width: 12),
                _buildModernAvatar(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAvatar() {
    final user = widget.message.sender;
    final initials = _getInitials(user);
    final color = _getUserColor(user);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildModernMessageContent(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        gradient: widget.isMe
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.8),
                ],
              )
            : null,
        color: widget.isMe ? null : Colors.grey[100],
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: widget.isMe
              ? const Radius.circular(20)
              : const Radius.circular(4),
          bottomRight: widget.isMe
              ? const Radius.circular(4)
              : const Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isMe
                ? theme.primaryColor.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.message.attachments.isNotEmpty)
              _buildModernAttachments(context),
            if (widget.message.content.isNotEmpty) ...[
              if (widget.message.attachments.isNotEmpty)
                const SizedBox(height: 8),
              Text(
                widget.message.content,
                style: TextStyle(
                  color: widget.isMe ? Colors.white : Colors.grey[800],
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimestamp() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        _formatTime(widget.message.createdAt),
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[500],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildModernStatusIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isPending)
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 6),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ),
              ),
            )
          else if (widget.isError)
            Container(
              margin: const EdgeInsets.only(right: 6),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red[400],
                size: 14,
              ),
            ),
          Text(
            widget.isPending ? 'Envoi en cours...' : 'Échec de l\'envoi',
            style: TextStyle(
              color: widget.isError ? Colors.red[400] : Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAttachments(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.message.attachments.map((attachment) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildModernAttachmentPreview(attachment, context),
        );
      }).toList(),
    );
  }

  Widget _buildModernAttachmentPreview(
      MessageAttachment attachment, BuildContext context) {
    if (attachment.isImage) {
      return _buildModernImage(attachment);
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              widget.isMe ? Colors.white.withOpacity(0.15) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                widget.isMe ? Colors.white.withOpacity(0.2) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: attachment.isPdf ? Colors.red[50] : Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                attachment.isPdf
                    ? Icons.picture_as_pdf_rounded
                    : Icons.attach_file_rounded,
                color: attachment.isPdf ? Colors.red[600] : Colors.blue[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.filename,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.isMe ? Colors.white : Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatFileSize(attachment.fileSize),
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.isMe
                          ? Colors.white.withOpacity(0.8)
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
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

  Widget _buildModernImage(MessageAttachment attachment) {
    return FutureBuilder<bool>(
      future: _checkFileExists(attachment.localPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildModernLoadingContainer();
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
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 250,
              maxHeight: 300,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildModernLoadingContainer();
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Erreur de chargement de l\'image: $error');
                  return _buildModernErrorContainer();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernErrorContainer() {
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Image non disponible',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernLoadingContainer() {
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Color _getUserColor(User? user) {
    if (user == null) return Colors.grey;

    // Génère une couleur basée sur l'ID de l'utilisateur pour la cohérence
    final colors = [
      Colors.blue[600]!,
      Colors.green[600]!,
      Colors.orange[600]!,
      Colors.purple[600]!,
      Colors.red[600]!,
      Colors.teal[600]!,
      Colors.indigo[600]!,
      Colors.pink[600]!,
    ];

    final hash = user.id.hashCode;
    return colors[hash.abs() % colors.length];
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
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
      await provider.deleteMessage(
          widget.message.discussionId, widget.message.id);
    }
  }
}
