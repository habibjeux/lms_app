import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/messaging_provider.dart';
import '../widgets/discussion_list_item.dart';
import '../widgets/new_discussion_button.dart';
import '../widgets/sync_indicator.dart';
import '../../../../core/widgets/connectivity/offline_banner.dart';
import 'discussion_detail_screen.dart';
import 'new_discussion_screen.dart';

class DiscussionsScreen extends StatefulWidget {
  const DiscussionsScreen({super.key});

  @override
  State<DiscussionsScreen> createState() => _DiscussionsScreenState();
}

class _DiscussionsScreenState extends State<DiscussionsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Charger les discussions au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDiscussions();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  Future<void> _loadDiscussions() async {
    await Provider.of<MessagingProvider>(context, listen: false)
        .loadDiscussions();
  }

  Future<void> _syncPendingMessages() async {
    await Provider.of<MessagingProvider>(context, listen: false)
        .syncPendingMessages();
  }

  void _navigateToDiscussion(BuildContext context, String discussionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DiscussionDetailScreen(discussionId: discussionId),
      ),
    );
  }

  void _navigateToNewDiscussion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewDiscussionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          Consumer<MessagingProvider>(
            builder: (context, provider, child) {
              return SyncIndicator(
                pendingCount: provider.pendingMessagesCount,
                isSyncing: provider.isSyncing,
                onPressed: _syncPendingMessages,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une conversation...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
          ),
          Expanded(
            child: Consumer<MessagingProvider>(
              builder: (context, provider, child) {
                if (provider.isLoadingDiscussions) {
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
                          onPressed: _loadDiscussions,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                final discussions = provider.discussions;

                if (discussions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Aucune conversation'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _navigateToNewDiscussion,
                          child: const Text('Démarrer une conversation'),
                        ),
                      ],
                    ),
                  );
                }

                // Filtrer les discussions en fonction de la recherche
                final filteredDiscussions = _searchQuery.isEmpty
                    ? discussions
                    : discussions.where((discussion) {
                        final otherParticipant = discussion.getOtherParticipant(
                            Provider.of<AuthProvider>(context, listen: false)
                                    .user
                                    ?.id ??
                                '');
                        final name =
                            '${otherParticipant['firstName']} ${otherParticipant['lastName']}'
                                .toLowerCase();
                        return name.contains(_searchQuery.toLowerCase());
                      }).toList();

                if (filteredDiscussions.isEmpty) {
                  return const Center(
                    child: Text('Aucun résultat trouvé'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadDiscussions,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: filteredDiscussions.length,
                    itemBuilder: (context, index) {
                      final discussion = filteredDiscussions[index];
                      return DiscussionListItem(
                        discussion: discussion,
                        onTap: () =>
                            _navigateToDiscussion(context, discussion.id),
                        isNew: provider.isDiscussionNew(discussion),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: NewDiscussionButton(
        onPressed: _navigateToNewDiscussion,
      ),
    );
  }
}
