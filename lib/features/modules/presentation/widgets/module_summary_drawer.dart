import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import '../../models/module_summary.dart';

class ModuleSummaryDrawer extends StatelessWidget {
  final ModuleSummary summary;

  const ModuleSummaryDrawer({
    Key? key,
    required this.summary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Résumé - ${summary.moduleTitle}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (summary.moduleDescription != null) ...[
              HtmlWidget(
                summary.moduleDescription!,
                customStylesBuilder: (element) {
                  if (element.localName == 'a') {
                    return {'color': '#007AFF'};
                  }
                  return null;
                },
              ),
              const Divider(height: 32),
            ],
            Text(
              'Résumés des chapitres',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...summary.chapters
                .map((chapter) => _buildChapterSummary(context, chapter)),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterSummary(BuildContext context, ChapterSummary chapter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          chapter.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: HtmlWidget(
              chapter.summary,
              customStylesBuilder: (element) {
                if (element.localName == 'a') {
                  return {'color': '#007AFF'};
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
