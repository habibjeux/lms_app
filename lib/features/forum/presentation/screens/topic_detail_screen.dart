import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/forum.dart';
import '../../providers/forums_provider.dart';
import '../widgets/reply_item.dart';
import '../widgets/reply_dialog.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'reply_detail_screen.dart';

class TopicDetailScreen extends StatelessWidget {
  final Topic topic;

  const TopicDetailScreen({
    super.key,
    required this.topic,
  });

  void _showReplyDialog(BuildContext context, {Reply? replyTo}) async {
    final content = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => ReplyDialog(
        replyToAuthor: replyTo?.author.fullName,
      ),
    );

    if (content != null && context.mounted) {
      final provider = context.read<ForumProvider>();
      try {
        await provider.createReply(
          topicId: topic.id,
          content: content,
          parentReplyId: replyTo?.id,
        );
        if (context.mounted) {
          provider.loadTopicDetail(topic.id);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'envoi de la réponse'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question'),
      ),
      body: Consumer<ForumProvider>(
        builder: (context, provider, child) {
          final currentTopic = provider.currentTopic ?? topic;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Question card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentTopic.author.fullName,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  timeago.format(currentTopic.createdAt,
                                      locale: 'fr'),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (currentTopic.pinned)
                            const Icon(Icons.push_pin, size: 16),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentTopic.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(currentTopic.content),
                    ],
                  ),
                ),
              ),

              if (currentTopic.replies?.isNotEmpty == true) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '${currentTopic.replies!.length} Réponses',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                // Liste des réponses principales (non imbriquées)
                ...currentTopic.replies!
                    .where((reply) => reply.parentReplyId == null)
                    .map((reply) => ReplyItem(
                          reply: reply,
                          onReply: (reply) => _showReplyDialog(
                            context,
                            replyTo: reply,
                          ),
                          onViewReplies: (reply) => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReplyDetailScreen(
                                parentReply: reply,
                                onReply: (replyTo) => _showReplyDialog(
                                  context,
                                  replyTo: replyTo,
                                ),
                              ),
                            ),
                          ),
                        )),
              ],

              // Espace pour le FAB
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReplyDialog(context),
        icon: const Icon(Icons.reply),
        label: const Text('Répondre'),
      ),
    );
  }
}
