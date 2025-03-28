import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/messaging_provider.dart';
import '../widgets/teacher_list_item.dart';
import '../../../auth/models/user.dart';
import 'discussion_detail_screen.dart';

class NewDiscussionScreen extends StatefulWidget {
  const NewDiscussionScreen({super.key});

  @override
  State<NewDiscussionScreen> createState() => _NewDiscussionScreenState();
}

class _NewDiscussionScreenState extends State<NewDiscussionScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<User> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results =
          await Provider.of<MessagingProvider>(context, listen: false)
              .searchUsers(query);

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _startDiscussion(User user) async {
    // Créer une nouvelle discussion sans message initial
    final provider = Provider.of<MessagingProvider>(context, listen: false);
    final discussion = await provider.createDiscussion(user.id, '');

    if (discussion != null && mounted) {
      // Naviguer vers la nouvelle discussion
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DiscussionDetailScreen(discussionId: discussion.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle discussion'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un professeur...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              autofocus: true,
            ),
          ),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchController.text.length < 2) {
      return const Center(
        child: Text('Entrez au moins 2 caractères pour rechercher'),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('Aucun résultat trouvé'),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return TeacherListItem(
          user: user,
          onTap: () => _startDiscussion(user),
        );
      },
    );
  }
}
