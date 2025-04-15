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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleTextChange);
    // Utiliser un Future.microtask pour éviter les appels d'état pendant le build
    Future.microtask(() => _loadMessages());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger les messages à chaque changement de dépendances (navigation)
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleTextChange);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Séparer la logique de changement de texte pour réduire les reconstructions
  void _handleTextChange() {
    final newIsComposing =
        _messageController.text.trim().isNotEmpty || _selectedFiles.isNotEmpty;
    if (_isComposing != newIsComposing) {
      setState(() {
        _isComposing = newIsComposing;
      });
    }
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;

    final provider = Provider.of<MessagingProvider>(context, listen: false);
    await provider.loadMessages(widget.discussionId);

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }

    // Utiliser un délai plus long pour s'assurer que le rendu est complet
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _scrollToBottom(animate: false);
      }
    });
  }

  // Méthode séparée pour défiler vers le bas
  void _scrollToBottom({bool animate = true}) {
    if (!mounted) return;

    // Assurez-vous que le widget est construit avant de tenter de défiler
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      try {
        // S'assurer que nous sommes au maximum du défilement
        final maxScroll = _scrollController.position.maxScrollExtent;

        if (animate) {
          _scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(maxScroll);
        }
      } catch (e) {
        // Gérer silencieusement les erreurs de défilement
        print('Erreur de défilement: $e');
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty && _selectedFiles.isEmpty) return;

    // Effacer le contenu du message immédiatement pour une meilleure expérience utilisateur
    final textContent = content;
    _messageController.clear();

    // Capturer les fichiers actuels et effacer la liste avant d'envoyer
    final filesToSend = List<File>.from(_selectedFiles);
    setState(() {
      _selectedFiles.clear();
      _isComposing = false;
    });

    final provider = Provider.of<MessagingProvider>(context, listen: false);

    try {
      if (filesToSend.isNotEmpty) {
        // Envoyer un message avec pièces jointes
        await provider.sendMessageWithAttachments(
          widget.discussionId,
          textContent,
          filesToSend,
        );
      } else {
        // Envoyer un message texte
        await provider.sendMessage(
          widget.discussionId,
          textContent,
        );
      }

      // Forcer un reload des messages pour s'assurer que l'UI est à jour
      if (mounted) {
        // Délai légèrement plus long pour s'assurer que le backend a traité le message
        Future.delayed(const Duration(milliseconds: 500), () async {
          if (mounted) {
            // Recharger les messages pour s'assurer qu'ils sont à jour
            await provider.loadMessages(widget.discussionId);

            // Attendre encore un peu que l'UI se mette à jour avant de défiler
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) {
                _scrollToBottom();
              }
            });
          }
        });
      }
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
        _isComposing = true;
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
        _isComposing = _selectedFiles.isNotEmpty;
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      _isComposing = _messageController.text.trim().isNotEmpty ||
          _selectedFiles.isNotEmpty;
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
                if (provider.isLoadingMessages && !_isInitialized) {
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
                if (messages.isEmpty && !provider.isLoadingMessages) {
                  return const Center(
                    child: Text('Aucun message. Commencez la conversation!'),
                  );
                }

                final currentUserId =
                    Provider.of<AuthProvider>(context, listen: false)
                            .user
                            ?.id ??
                        '';

                // Défiler vers le bas si des messages ont été ajoutés
                // Supprimer le défilement automatique ici car il peut interférer
                // avec les autres mécanismes de défilement

                return GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Stack(
                      children: [
                        RefreshIndicator(
                          onRefresh: _loadMessages,
                          child: ListView.builder(
                            controller: _scrollController,
                            reverse: false,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isMe = message.senderId == currentUserId;

                              // Vérifier si on doit afficher la date - correction de la logique
                              bool showDate = true;
                              if (index > 0) {
                                final prevMessage = messages[index - 1];

                                // S'assurer que les dates sont valides
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
                                showDate =
                                    !prevDate.isAtSameMomentAs(currentDate);
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
                        if (provider.isLoadingMessages && _isInitialized)
                          const Positioned(
                            top: 8,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.0),
                              ),
                            ),
                          ),
                      ],
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
                    _isComposing = _messageController.text.trim().isNotEmpty;
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
                    // Suppression de onChanged ici car nous utilisons un listener sur le contrôleur
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
