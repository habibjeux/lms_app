import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/assignment_provider.dart';
import '../../models/assignment.dart';
import '../../models/assignment_submission.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_message.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/buttons/download_button.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;
  final String? moduleId;
  final String? chapterId;
  final String? title;

  const AssignmentDetailScreen({
    Key? key,
    required this.assignmentId,
    this.moduleId,
    this.chapterId,
    this.title,
  }) : super(key: key);

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<File> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssignmentProvider>().loadAssignment(widget.assignmentId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Devoir'),
        actions: [
          Consumer<AssignmentProvider>(
            builder: (context, provider, child) {
              if (!provider.isDownloaded) {
                return IconButton(
                  icon: provider.downloadProgress > 0 &&
                          provider.downloadProgress < 1
                      ? CircularProgressIndicator(
                          value: provider.downloadProgress,
                          strokeWidth: 2,
                        )
                      : const Icon(Icons.download),
                  onPressed: () => _downloadAssignment(provider),
                  tooltip: 'Télécharger le devoir',
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: Consumer<AssignmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (provider.error != null && provider.currentAssignment == null) {
            return Center(
              child: ErrorMessage(
                message: provider.error!,
                onRetry: () => provider.loadAssignment(widget.assignmentId),
              ),
            );
          }

          final assignment = provider.currentAssignment;
          if (assignment == null) {
            return const Center(
              child: Text('Devoir non trouvé'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations du devoir
                _buildAssignmentInfo(assignment),
                const SizedBox(height: 24),

                // Instructions
                if (assignment.instructions.isNotEmpty) ...[
                  _buildSection('Instructions', assignment.instructions),
                  const SizedBox(height: 24),
                ],

                // Pièces jointes
                if (assignment.attachments.isNotEmpty) ...[
                  _buildAttachments(assignment, provider),
                  const SizedBox(height: 24),
                ],

                // Soumission existante ou formulaire de soumission
                _buildSubmissionSection(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssignmentInfo(Assignment assignment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assignment.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.school, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Module: ${assignment.moduleId}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.grade, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Note maximale: ${assignment.maxScore} points'),
              ],
            ),
            if (assignment.endDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: _isLate(assignment.endDate!)
                        ? Colors.red
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Date limite: ${_formatDate(assignment.endDate!)}',
                    style: TextStyle(
                      color: _isLate(assignment.endDate!) ? Colors.red : null,
                      fontWeight:
                          _isLate(assignment.endDate!) ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(content),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachments(Assignment assignment, AssignmentProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pièces jointes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: assignment.attachments.map((attachment) {
              return ListTile(
                leading: Icon(_getFileIcon(attachment.filename)),
                title: Text(attachment.filename),
                subtitle: Text(_formatFileSize(attachment.fileSize)),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadAttachment(attachment, provider),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionSection(AssignmentProvider provider) {
    final submission = provider.currentSubmission;

    if (submission != null) {
      return _buildExistingSubmission(submission);
    } else {
      return _buildSubmissionForm(provider);
    }
  }

  Widget _buildExistingSubmission(AssignmentSubmission submission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Votre soumission',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Soumis le ${_formatDate(submission.submissionDate)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (submission.isLate) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Soumission tardive',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                ],
                if (submission.comment != null &&
                    submission.comment!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Commentaire:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(submission.comment!),
                ],
                if (submission.files.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Fichiers soumis:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...submission.files.map((filePath) => Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.attach_file, size: 16),
                            const SizedBox(width: 4),
                            Text(filePath.split('/').last),
                          ],
                        ),
                      )),
                ],
                if (submission.grade != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Note: ${submission.grade!.score}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (submission.grade!.feedback != null) ...[
                          const SizedBox(height: 8),
                          Text('Commentaire de l\'enseignant:'),
                          Text(submission.grade!.feedback!),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionForm(AssignmentProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Soumettre votre devoir',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sélection de fichiers
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedFiles.isEmpty
                            ? 'Aucun fichier sélectionné'
                            : '${_selectedFiles.length} fichier(s) sélectionné(s)',
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Choisir fichiers'),
                    ),
                  ],
                ),

                // Liste des fichiers sélectionnés
                if (_selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...(_selectedFiles.map((file) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.insert_drive_file, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(file.path.split('/').last)),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _removeFile(file),
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ))),
                ],

                const SizedBox(height: 16),

                // Commentaire
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    labelText: 'Commentaire (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 16),

                // Bouton de soumission
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    onPressed: _selectedFiles.isNotEmpty
                        ? () => _submitAssignment(provider)
                        : null,
                    isLoading: provider.isSubmitting,
                    child: const Text('Soumettre'),
                  ),
                ),

                // Affichage des erreurs
                if (provider.error != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: provider.error!.contains('sauvegardée localement')
                          ? Colors.orange.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color:
                            provider.error!.contains('sauvegardée localement')
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          provider.error!.contains('sauvegardée localement')
                              ? Icons.info
                              : Icons.error,
                          color:
                              provider.error!.contains('sauvegardée localement')
                                  ? Colors.orange
                                  : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(provider.error!)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Méthodes utilitaires
  bool _isLate(DateTime endDate) {
    return DateTime.now().isAfter(endDate);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Actions
  Future<void> _downloadAssignment(AssignmentProvider provider) async {
    await provider.downloadAssignment(
      widget.assignmentId,
      moduleId: widget.moduleId,
      chapterId: widget.chapterId,
      title: widget.title,
    );
  }

  Future<void> _downloadAttachment(
      attachment, AssignmentProvider provider) async {
    // Logique pour télécharger/ouvrir une pièce jointe
    final localPath = await provider.getLocalAttachmentPath(
      attachment.id,
      attachment.filename,
    );

    if (localPath != null) {
      // Ouvrir le fichier local
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ouverture du fichier: ${attachment.filename}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fichier non disponible hors ligne')),
      );
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        _selectedFiles = result.paths.map((path) => File(path!)).toList();
      });
    }
  }

  void _removeFile(File file) {
    setState(() {
      _selectedFiles.remove(file);
    });
  }

  Future<void> _submitAssignment(AssignmentProvider provider) async {
    final assignment = provider.currentAssignment;
    if (assignment == null) return;

    final isLate = assignment.endDate != null &&
        DateTime.now().isAfter(assignment.endDate!);

    final success = await provider.submitAssignment(
      assignmentId: widget.assignmentId,
      files: _selectedFiles,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      isLate: isLate,
    );

    if (success) {
      // Nettoyer le formulaire
      setState(() {
        _selectedFiles.clear();
        _commentController.clear();
      });

      if (!provider.error!.contains('sauvegardée localement')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devoir soumis avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
