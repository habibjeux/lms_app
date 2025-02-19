import 'package:flutter/material.dart';
import '../../models/forum.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReplyWidget extends StatelessWidget {
  final Reply reply;
  final VoidCallback? onReply;

  const ReplyWidget({
    super.key,
    required this.reply,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(
        left: reply.parentReplyId != null ? 32.0 : 0,
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
                if (onReply != null)
                  IconButton(
                    icon: const Icon(Icons.reply, size: 20),
                    onPressed: onReply,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(reply.content),
            if (reply.childReplies?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              ...reply.childReplies!.map((childReply) => ReplyWidget(
                    reply: childReply,
                    onReply: onReply,
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
