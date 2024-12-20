import 'package:flutter/material.dart';

import '../../models/module.dart';
import '../../models/resource.dart';

class ModuleList extends StatelessWidget {
  final List<Module> modules;

  const ModuleList({super.key, required this.modules});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return ModuleCard(module: module);
      },
    );
  }
}

class ModuleCard extends StatefulWidget {
  final Module module;

  const ModuleCard({super.key, required this.module});

  @override
  State<ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<ModuleCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.module.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${widget.module.credits} crédits'),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.book,
                color: Theme.of(context).primaryColor,
              ),
            ),
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
          ),
          if (_isExpanded) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.module.description.isNotEmpty)
                    Text(widget.module.description),
                  const SizedBox(height: 16),
                  if (widget.module.resources?.isNotEmpty ?? false) ...[
                    const Text(
                      'Ressources',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.module.resources!
                        .map((resource) => ResourceItem(resource: resource)),
                  ],
                  if (widget.module.quizzes?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Quiz',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.module.quizzes!.map(
                      (quiz) => ListTile(
                        title: Text(quiz.title),
                        leading: const Icon(Icons.quiz),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Navigation vers le quiz
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ResourceItem extends StatelessWidget {
  final Resource resource;

  const ResourceItem({super.key, required this.resource});

  IconData _getIconForType() {
    switch (resource.type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'video':
        return Icons.video_library;
      case 'link':
        return Icons.link;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_getIconForType()),
      title: Text(resource.label),
      trailing: resource.visible
          ? const Icon(Icons.download, size: 20)
          : const Icon(Icons.lock, size: 20),
      onTap: resource.visible
          ? () {
              // Logique de téléchargement/ouverture
            }
          : null,
    );
  }
}
