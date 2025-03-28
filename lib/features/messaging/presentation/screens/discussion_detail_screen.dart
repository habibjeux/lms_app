import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/messaging_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/attachment_preview.dart';
import '../../../../core/widgets/connectivity/offline_banner.dart';
import '../../../../core/widgets/inputs/expandable_text_field.dart';

class DiscussionDetailScreen extends StatefulWidget {
  final String discussionId;

  const DiscussionDetailScreen({super.key, required this.discussionId});

  @override
  State<DiscussionDetailScreen> createState() => _DiscussionDetailScreenState();
}

class _DiscussionDetailScreenState extends State<DiscussionDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final List<File> _selectedFiles = [];
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final provider = Provider.of<MessagingProvider>(context, listen: false);
    await provider.loadMessages(widget.discussionId);

    // Scroll to bottom after messages are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty && _selectedFiles.isEmpty) return;

    final provider = Provider.of<MessagingProvider>(context, listen: false);

    try {
      if (_selectedFiles.isNotEmpty) {
        // Envoyer un message avec pièces jointes
        await provider.sendMessageWithAttachments(
          widget.discussionId,
          content,
          _selectedFiles,
        );
      } else {
        // Envoyer un message texte
        await provider.sendMessage(
          widget.discussionId,
          content,
        );
      }

      // Effacer le contenu du message et les fichiers sélectionnés
      _messageController.clear();
      setState(() {
        _selectedFiles.clear();
        _isComposing = false;
      });

      // Scroll vers le bas pour voir le nouveau message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          try {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          } catch (e) {
            // Gestion des erreurs silencieuse
          }
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi du message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedFiles.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'txt',
        'zip'
      ],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (final file in result.files) {
          if (file.path != null) {
            _selectedFiles.add(File(file.path!));
          }
        }
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Prendre une photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choisir une image'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_file),
            title: const Text('Joindre un document'),
            onTap: () {
              Navigator.pop(context);
              _pickFile();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<MessagingProvider>(
          builder: (context, provider, child) {
            final discussion = provider.currentDiscussion;
            if (discussion == null) return const Text('Chargement...');

            final otherParticipant = discussion.getOtherParticipant(
                Provider.of<AuthProvider>(context, listen: false).user?.id ??
                    '');
            return Text(
                '${otherParticipant['firstName']} ${otherParticipant['lastName']}');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  final discussion =
                      Provider.of<MessagingProvider>(context).currentDiscussion;
                  if (discussion == null) return const SizedBox();

                  final otherParticipant = discussion.getOtherParticipant(
                      Provider.of<AuthProvider>(context, listen: false)
                              .user
                              ?.id ??
                          '');
                  return ListTile(
                    title: Text(
                        '${otherParticipant['firstName']} ${otherParticipant['lastName']}'),
                    subtitle: Text(otherParticipant['email']),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: Consumer<MessagingProvider>(
              builder: (context, provider, child) {
                if (provider.isLoadingMessages) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          provider.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadMessages,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                final messages = provider.messages;
                final currentUserId =
                    Provider.of<AuthProvider>(context, listen: false)
                            .user
                            ?.id ??
                        '';

                return GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: RefreshIndicator(
                      onRefresh: _loadMessages,
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: false,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == currentUserId;

                          // Vérifier si on doit afficher la date
                          bool showDate = true;
                          if (index > 0) {
                            final prevMessage = messages[index - 1];
                            final prevDate = DateTime(
                              prevMessage.createdAt.year,
                              prevMessage.createdAt.month,
                              prevMessage.createdAt.day,
                            );
                            final currentDate = DateTime(
                              message.createdAt.year,
                              message.createdAt.month,
                              message.createdAt.day,
                            );
                            showDate = prevDate != currentDate;
                          }

                          return Column(
                            children: [
                              if (showDate)
                                _buildDateSeparator(message.createdAt),
                              MessageBubble(
                                message: message,
                                isMe: isMe,
                                isPending: message.status == 'pending',
                                isError: message.status == 'error',
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_selectedFiles.isNotEmpty) _buildAttachmentPreview(),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final formatter = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              formatter.format(date),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pièces jointes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFiles.clear();
                  });
                },
                child: const Text('Tout supprimer'),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                _selectedFiles.length,
                (index) => AttachmentPreview(
                  file: _selectedFiles[index],
                  onRemove: () => _removeFile(index),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Consumer<MessagingProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 4.0,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed:
                      provider.isSendingMessage ? null : _showAttachmentOptions,
                ),
                Expanded(
                  child: ExpandableTextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Écrire un message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                    ),
                    onChanged: (text) {
                      // Ne mettre à jour l'état que si l'état de composition change réellement
                      final newIsComposing =
                          text.trim().isNotEmpty || _selectedFiles.isNotEmpty;
                      if (_isComposing != newIsComposing) {
                        setState(() {
                          _isComposing = newIsComposing;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8.0),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: _isComposing ? 48.0 : 0.0,
                  height: 48.0,
                  child: _isComposing
                      ? IconButton(
                          icon: provider.isSendingMessage
                              ? const SizedBox(
                                  width: 24.0,
                                  height: 24.0,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.0),
                                )
                              : const Icon(Icons.send, color: Colors.blue),
                          onPressed:
                              provider.isSendingMessage ? null : _sendMessage,
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
