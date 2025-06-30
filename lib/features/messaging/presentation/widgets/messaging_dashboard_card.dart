import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../messaging/providers/messaging_provider.dart';
import '../../../messaging/messaging_initialization.dart';

class MessagingDashboardCard extends StatefulWidget {
  const MessagingDashboardCard({super.key});

  @override
  State<MessagingDashboardCard> createState() => _MessagingDashboardCardState();
}

class _MessagingDashboardCardState extends State<MessagingDashboardCard>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  int _unreadCount = 0;
  int _pendingCount = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

      // Déclencher l'animation après le chargement
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  void _navigateToMessages() {
    MessagingInitialization.navigateToDiscussions(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primaryColor.withOpacity(0.8),
                theme.primaryColor,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _navigateToMessages,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      _buildLoadingIndicator()
                    else
                      _buildContent(),
                    const SizedBox(height: 12),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.message_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 80,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_unreadCount == 0 && _pendingCount == 0) {
      return Container(
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Colors.white.withOpacity(0.8),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Aucun nouveau message',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        if (_unreadCount > 0) ...[
          Expanded(
            child: _buildModernStatCard(
              value: _unreadCount.toString(),
              label: _unreadCount > 1 ? 'Non lus' : 'Non lu',
              icon: Icons.mark_email_unread_rounded,
            ),
          ),
          if (_pendingCount > 0) const SizedBox(width: 12),
        ],
        if (_pendingCount > 0)
          Expanded(
            child: _buildModernStatCard(
              value: _pendingCount.toString(),
              label: 'En attente',
              icon: Icons.schedule_rounded,
            ),
          ),
      ],
    );
  }

  Widget _buildModernStatCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(
                icon,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Appuyez pour ouvrir',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.white.withOpacity(0.8),
          size: 14,
        ),
      ],
    );
  }
}
