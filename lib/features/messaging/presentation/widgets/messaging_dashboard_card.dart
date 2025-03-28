import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../messaging/providers/messaging_provider.dart';
import '../../../messaging/messaging_initialization.dart';

class MessagingDashboardCard extends StatefulWidget {
  const MessagingDashboardCard({super.key});

  @override
  State<MessagingDashboardCard> createState() => _MessagingDashboardCardState();
}

class _MessagingDashboardCardState extends State<MessagingDashboardCard> {
  bool _isLoading = true;
  int _unreadCount = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<MessagingProvider>(context, listen: false);
      await provider.loadDiscussions();

      setState(() {
        _unreadCount = provider.unreadCount;
        _pendingCount = provider.pendingMessagesCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToMessages() {
    MessagingInitialization.navigateToDiscussions(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: _navigateToMessages,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Icon(
                    Icons.message,
                    color: theme.primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _isLoading
                  ? const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_unreadCount > 0)
                          _buildInfoItem(
                            context,
                            '$_unreadCount',
                            'non lu${_unreadCount > 1 ? 's' : ''}',
                            Colors.red,
                          ),
                        if (_pendingCount > 0)
                          _buildInfoItem(
                            context,
                            '$_pendingCount',
                            'en attente',
                            Colors.orange,
                          ),
                        if (_unreadCount == 0 && _pendingCount == 0)
                          const Text('Pas de nouveaux messages'),
                      ],
                    ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _navigateToMessages,
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
