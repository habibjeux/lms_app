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
  static const int _pageSize = 20;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessageChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadMessages();
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;

    setState(() {
      _isLoadingMore = true;
    });

    final provider = Provider.of<MessagingProvider>(context, listen: false);
    await provider.loadMoreMessages(widget.discussionId, _currentPage + 1);

    setState(() {
      _currentPage++;
      _isLoadingMore = false;
      _hasMoreMessages = provider.messages.length >= _pageSize * _currentPage;
    });
  }

  // Séparer la logique de changement de texte pour réduire les reconstructions
  void _onMessageChanged() {
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

    if (!mounted) return;

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

    // Mettre à jour l'état avant l'envoi
    if (mounted) {
      setState(() {
        _selectedFiles.clear();
        _isComposing = false;
      });
    }

    final provider = Provider.of<MessagingProvider>(context, listen: false);

    try {
      if (filesToSend.isNotEmpty) {
        await provider.sendMessageWithAttachments(
          widget.discussionId,
          textContent,
          filesToSend,
        );
      } else {
        await provider.sendMessage(
          widget.discussionId,
          textContent,
        );
      }

      // Attendre que le message soit envoyé avant de recharger
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        await provider.loadMessages(widget.discussionId);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi du message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  void _showModernAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ajouter une pièce jointe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildModernAttachmentOption(
              icon: Icons.photo_camera_rounded,
              title: 'Prendre une photo',
              subtitle: 'Utiliser l\'appareil photo',
              color: Colors.green[600]!,
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            _buildModernAttachmentOption(
              icon: Icons.photo_library_rounded,
              title: 'Choisir une image',
              subtitle: 'Depuis la galerie',
              color: Colors.blue[600]!,
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            _buildModernAttachmentOption(
              icon: Icons.attach_file_rounded,
              title: 'Joindre un document',
              subtitle: 'PDF, Word, Excel...',
              color: Colors.orange[600]!,
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAttachmentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[50],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagingProvider>(
      builder: (context, provider, child) {
        final messages = provider.messages;

        return Scaffold(
          appBar: AppBar(
            title: Text(_getOtherParticipantName(context)),
          ),
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      cacheExtent: 1000,
                      itemCount: messages.length + (_hasMoreMessages ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        // Inverser l'index pour afficher les messages du plus récent au plus ancien
                        final reversedIndex = messages.length - 1 - index;
                        final message = messages[reversedIndex];

                        final isMe = message.senderId ==
                            Provider.of<AuthProvider>(context, listen: false)
                                .user
                                ?.id;
                        final showDate = reversedIndex == 0 ||
                            !_isSameDay(message.createdAt,
                                messages[reversedIndex - 1].createdAt);

                        return Column(
                          children: [
                            if (showDate)
                              _buildDateSeparator(message.createdAt),
                            MessageBubble(
                              key: ValueKey(message.id),
                              message: message,
                              isMe: isMe,
                              isPending: message.status == 'pending',
                              isError: message.status == 'error',
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              _buildMessageComposer(),
            ],
          ),
        );
      },
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

  Widget _buildMessageComposer() {
    return Consumer<MessagingProvider>(
      builder: (context, provider, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
                spreadRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                if (_selectedFiles.isNotEmpty) _buildModernAttachmentPreview(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildAttachmentButton(provider),
                    const SizedBox(width: 12),
                    Expanded(child: _buildModernTextField()),
                    const SizedBox(width: 12),
                    _buildModernSendButton(provider),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentButton(MessagingProvider provider) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap:
              provider.isSendingMessage ? null : _showModernAttachmentOptions,
          child: Icon(
            Icons.attach_file_rounded,
            color: provider.isSendingMessage
                ? Colors.grey[400]
                : Theme.of(context).primaryColor,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField() {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isComposing
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: ExpandableTextField(
        controller: _messageController,
        minLines: 1,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'Écrire un message...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 12.0,
          ),
        ),
      ),
    );
  }

  Widget _buildModernSendButton(MessagingProvider provider) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      width: _isComposing ? 44 : 0,
      height: 44,
      child: _isComposing
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: provider.isSendingMessage ? null : _sendMessage,
                  child: Center(
                    child: provider.isSendingMessage
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildModernAttachmentPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedFiles.length} pièce${_selectedFiles.length > 1 ? 's' : ''} jointe${_selectedFiles.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedFiles.clear();
                    _isComposing = _messageController.text.trim().isNotEmpty;
                  });
                },
                icon: Icon(
                  Icons.clear_rounded,
                  size: 16,
                  color: Colors.red[400],
                ),
                label: Text(
                  'Supprimer tout',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedFiles.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) =>
                  _buildModernAttachmentItem(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAttachmentItem(int index) {
    final file = _selectedFiles[index];
    final fileName = file.path.split('/').last;
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp']
        .contains(fileName.split('.').last.toLowerCase());

    return Container(
      width: 70,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isImage
                ? Image.file(
                    file,
                    width: 70,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildFileIcon(fileName),
                  )
                : _buildFileIcon(fileName),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeFile(index),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red[400],
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
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

  Widget _buildFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    IconData iconData;
    Color iconColor;

    switch (extension) {
      case 'pdf':
        iconData = Icons.picture_as_pdf_rounded;
        iconColor = Colors.red[600]!;
        break;
      case 'doc':
      case 'docx':
        iconData = Icons.description_rounded;
        iconColor = Colors.blue[600]!;
        break;
      case 'xls':
      case 'xlsx':
        iconData = Icons.table_chart_rounded;
        iconColor = Colors.green[600]!;
        break;
      default:
        iconData = Icons.attach_file_rounded;
        iconColor = Colors.grey[600]!;
    }

    return Container(
      width: 70,
      height: 80,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, color: iconColor, size: 24),
          const SizedBox(height: 4),
          Text(
            extension.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getOtherParticipantName(BuildContext context) {
    final discussion =
        Provider.of<MessagingProvider>(context).currentDiscussion;
    if (discussion == null) return 'Chargement...';

    final otherParticipant = discussion.getOtherParticipant(
        Provider.of<AuthProvider>(context, listen: false).user?.id ?? '');
    return '${otherParticipant['firstName']} ${otherParticipant['lastName']}';
  }
}
