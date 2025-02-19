import 'package:flutter/material.dart';
import '../../models/forum.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReplyItem extends StatelessWidget {
  final Reply reply;
  final bool isChild;
  final Function(Reply) onReply;
  final Function(Reply) onViewReplies;

  const ReplyItem({
    super.key,
    required this.reply,
    this.isChild = false,
    required this.onReply,
    required this.onViewReplies,
  });

  @override
  Widget build(BuildContext context) {
    final hasChildReplies = (reply.childReplies?.length ?? 0) > 0;

    return Card(
      margin: EdgeInsets.only(
        left: isChild ? 32.0 : 0,
        bottom: 8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.person, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reply.author.fullName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        timeago.format(reply.createdAt, locale: 'fr'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (!isChild)
                  IconButton(
                    icon: const Icon(Icons.reply, size: 20),
                    onPressed: () => onReply(reply),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(reply.content),
            if (hasChildReplies) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => onViewReplies(reply),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.forum_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${reply.childReplies!.length} réponses',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                      const Icon(Icons.chevron_right, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
