import 'package:flutter/material.dart';
import '../../models/forum.dart';
import '../widgets/reply_item.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReplyDetailScreen extends StatelessWidget {
  final Reply parentReply;
  final Function(Reply) onReply;

  const ReplyDetailScreen({
    super.key,
    required this.parentReply,
    required this.onReply,
  });

  void _showNestedReplies(BuildContext context, Reply reply) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReplyDetailScreen(
          parentReply: reply,
          onReply: onReply,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réponses'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Réponse parent
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
                              parentReply.author.fullName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              timeago.format(parentReply.createdAt,
                                  locale: 'fr'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(parentReply.content),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // En-tête des réponses
          if (parentReply.childReplies?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${parentReply.childReplies!.length} Réponses',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

          // Liste des réponses
          ...?parentReply.childReplies?.map(
            (reply) => ReplyItem(
              reply: reply,
              isChild: true,
              onReply: onReply,
              onViewReplies: (reply) => _showNestedReplies(context, reply),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => onReply(parentReply),
        icon: const Icon(Icons.reply),
        label: const Text('Répondre'),
      ),
    );
  }
}
