import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/forums_provider.dart';
import '../screens/topic_detail_screen.dart';
import 'topic_list_item.dart';
import 'create_topic_dialog.dart';

class ModuleForumSection extends StatefulWidget {
  final String moduleId;

  const ModuleForumSection({
    super.key,
    required this.moduleId,
  });

  @override
  State<ModuleForumSection> createState() => _ModuleForumSectionState();
}

class _ModuleForumSectionState extends State<ModuleForumSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForumProvider>().loadModuleForum(widget.moduleId);
    });
  }

  void _showCreateTopicDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateTopicDialog(
          onSubmit: (title, content) {
            context.read<ForumProvider>().createTopic(
                  title: title,
                  content: content,
                );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ForumProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
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
                ElevatedButton(
                  onPressed: () => provider.loadModuleForum(widget.moduleId),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        Widget mainContent;

        if (provider.forum == null || provider.forum!.topics.isEmpty) {
          mainContent = const Center(
            child: Text('Soyez le premier à poser une question !'),
          );
        } else {
          final pinnedTopics = provider.getPinnedTopics();
          final regularTopics = provider.getRegularTopics();

          mainContent = CustomScrollView(
            slivers: [
              if (pinnedTopics.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Sujets épinglés',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TopicListItem(
                          topic: pinnedTopics[index],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TopicDetailScreen(
                                topic: pinnedTopics[index],
                              ),
                            ),
                          ),
                        ),
                      ),
                      childCount: pinnedTopics.length,
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Questions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TopicListItem(
                        topic: regularTopics[index],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TopicDetailScreen(
                              topic: regularTopics[index],
                            ),
                          ),
                        ),
                      ),
                    ),
                    childCount: regularTopics.length,
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 80),
              ), // Espace pour le FAB
            ],
          );
        }

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => provider.refreshForum(moduleId: widget.moduleId),
              child: mainContent,
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                onPressed:
                    provider.isCreatingTopic ? null : _showCreateTopicDialog,
                icon: const Icon(Icons.question_answer),
                label: const Text('Poser une question'),
              ),
            ),
            if (provider.isCreatingTopic)
              const Positioned.fill(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
    );
  }
}
