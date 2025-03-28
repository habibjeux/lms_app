import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/discussion.dart';

class DiscussionListItem extends StatelessWidget {
  final Discussion discussion;
  final VoidCallback onTap;
  final bool isNew;

  const DiscussionListItem({
    super.key,
    required this.discussion,
    required this.onTap,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Provider.of<AuthProvider>(context, listen: false).user?.id;
    final otherParticipant = discussion.getOtherParticipant(currentUserId!);
    final lastMessage = discussion.lastMessage;
    final hasUnread = discussion.unreadCount > 0;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor:
            hasUnread ? Theme.of(context).primaryColor : Colors.grey[400],
        child: Text(
          _getParticipantInitials(otherParticipant),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${otherParticipant['firstName']} ${otherParticipant['lastName']}',
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (lastMessage != null) ...[
            const SizedBox(width: 8),
            Text(
              _formatDate(lastMessage.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: hasUnread ? Theme.of(context).primaryColor : Colors.grey,
              ),
            ),
          ],
        ],
      ),
      subtitle: Row(
        children: [
          if (lastMessage != null) ...[
            if (lastMessage.senderId == currentUserId)
              const Text(
                'Vous: ',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            Expanded(
              child: Text(
                lastMessage.content.isNotEmpty
                    ? lastMessage.content
                    : lastMessage.attachments.isNotEmpty
                        ? '📎 Pièce jointe'
                        : 'Nouvelle discussion',
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                  color: hasUnread
                      ? Theme.of(context).primaryColor
                      : Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            Text(
              'Nouvelle discussion',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
      trailing: hasUnread
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${discussion.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      tileColor: isNew ? Colors.blue.withOpacity(0.05) : null,
    );
  }

  String _getParticipantInitials(Map<String, dynamic> participant) {
    final firstName = participant['firstName'] as String? ?? '';
    final lastName = participant['lastName'] as String? ?? '';

    String initials = '';
    if (firstName.isNotEmpty) {
      initials += firstName[0].toUpperCase();
    }
    if (lastName.isNotEmpty) {
      initials += lastName[0].toUpperCase();
    }

    return initials.isNotEmpty ? initials : '?';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(date);
    } else if (messageDate == yesterday) {
      return 'Hier';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('E').format(date); // Jour de la semaine
    } else {
      return DateFormat('dd/MM').format(date);
    }
  }
}
