import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/utlils/file_helper.dart';
import '../../models/assignment.dart';
import '../../models/assignment_attachment.dart';
import '../../models/assignment_submission.dart';
import '../../providers/assignment_submission_provider.dart';

class AssignmentContentWidget extends StatelessWidget {
  final Assignment assignment;
  final SyncService _syncService = SyncService();

  AssignmentContentWidget({
    super.key,
    required this.assignment,
  });

  @override
  Widget build(BuildContext context) {
    // Utiliser le provider pour maintenir l'état
    return ChangeNotifierProvider(
      create: (_) {
        final provider = AssignmentSubmissionProvider();
        // Charger immédiatement la soumission existante
        provider.loadSubmission(assignment.id);
        return provider;
      },
      child: Builder(builder: (context) {
        final connectivity = Provider.of<ConnectivityProvider>(context);
        final submissionProvider =
            Provider.of<AssignmentSubmissionProvider>(context);
        final isOffline = !connectivity.isOnline;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations du devoir
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instructions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(assignment.instructions),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.score,
                              size: 20, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(
                              'Note maximale: ${assignment.maxScore.toStringAsFixed(1)} points'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            assignment.allowLateSubmission
                                ? Icons.alarm_on
                                : Icons.alarm_off,
                            size: 20,
                            color: assignment.allowLateSubmission
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            assignment.allowLateSubmission
                                ? 'Remise tardive autorisée (${assignment.maxLateDays} jours max)'
                                : 'Remise tardive non autorisée',
                          ),
                        ],
                      ),
                      if (assignment.allowLateSubmission &&
                          assignment.lateSubmissionPenalty != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Pénalité: ${assignment.lateSubmissionPenalty?.toStringAsFixed(1)}% par jour',
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildFileInformation(context, assignment),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Pièces jointes du devoir
              if (assignment.attachments.isNotEmpty) ...[
                Text(
                  'Documents associés',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildAttachmentsList(
                    context, assignment.attachments, isOffline),
                const SizedBox(height: 16),
              ],

              // Formulaire de soumission
              Text(
                'Votre soumission',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              // Afficher un indicateur de chargement pendant que les données sont récupérées
              if (submissionProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                _buildSubmissionForm(
                    context, assignment, isOffline, submissionProvider),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFileInformation(BuildContext context, Assignment assignment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Formats de fichiers acceptés:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: assignment.acceptedFileTypes.map((type) {
            return Chip(
              label: Text(type),
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Taille maximale: ${_formatFileSize(assignment.maxFileSize)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildAttachmentsList(BuildContext context,
      List<AssignmentAttachment> attachments, bool isOffline) {
    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: attachments.length,
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return FutureBuilder<bool>(
            future: _syncService.isResourceDownloaded(attachment.id),
            builder: (context, snapshot) {
              final isDownloaded = snapshot.data ?? false;

              return ListTile(
                leading: _getFileIcon(attachment.mimeType),
                title: Text(attachment.filename),
                subtitle: Text(_formatFileSize(attachment.fileSize)),
                trailing: isDownloaded
                    ? IconButton(
                        icon: const Icon(Icons.folder_open),
                        onPressed: () => _openAttachment(context, attachment),
                      )
                    : (isOffline
                        ? const Icon(Icons.cloud_off, color: Colors.grey)
                        : IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () async {
                              await _downloadAttachment(context, attachment);
                              // Rafraîchir la liste
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Document téléchargé avec succès'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                          )),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSubmissionForm(BuildContext context, Assignment assignment,
      bool isOffline, AssignmentSubmissionProvider provider) {
    final existingSubmission = provider.submission;
    final bool hasSubmitted = existingSubmission != null;
    final bool isLate = assignment.endDate != null &&
        DateTime.now().isAfter(assignment.endDate!) &&
        !hasSubmitted;
    final bool canSubmit = !isLate || assignment.allowLateSubmission;

    // Si le provider vient de réussir une opération, afficher un message de succès
    if (provider.isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasSubmitted
                ? 'Soumission mise à jour avec succès'
                : 'Devoir soumis avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        provider.setSuccess(false);
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.error != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (hasSubmitted) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Soumis le ${_formatDateTime(existingSubmission.submissionDate)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Fichiers soumis:',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              _buildSubmittedFilesList(context, existingSubmission),
              if (existingSubmission.comment != null &&
                  existingSubmission.comment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Commentaire:',
                    style: Theme.of(context).textTheme.titleSmall),
                Text(existingSubmission.comment!),
              ],
              const SizedBox(height: 16),

              // Afficher les boutons d'action pour la modification/suppression
              if (assignment.endDate == null ||
                  DateTime.now().isBefore(assignment.endDate!)) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: provider.isSaving
                          ? null
                          : () => _showSubmissionDialog(
                              context, assignment, isOffline, provider,
                              existingSubmission: existingSubmission),
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier'),
                    ),
                    ElevatedButton.icon(
                      onPressed: provider.isSaving
                          ? null
                          : () => _confirmDeleteSubmission(context,
                              existingSubmission.id, assignment.id, provider),
                      icon: const Icon(Icons.delete),
                      label: const Text('Supprimer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ] else if (canSubmit) ...[
              if (isLate && assignment.allowLateSubmission) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'La date limite est dépassée. Une pénalité de ${assignment.lateSubmissionPenalty?.toStringAsFixed(1)}% par jour sera appliquée.',
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton.icon(
                onPressed: provider.isSaving
                    ? null
                    : () => _showSubmissionDialog(
                        context, assignment, isOffline, provider),
                icon: const Icon(Icons.upload_file),
                label: const Text('Soumettre mon devoir'),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'La date limite est dépassée. Vous ne pouvez plus soumettre de devoir.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isOffline && !hasSubmitted) ...[
              const SizedBox(height: 16),
              const Text(
                'Vous êtes en mode hors ligne. Votre soumission sera synchronisée lorsque vous serez à nouveau en ligne.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],

            // Afficher un indicateur de progression pendant la sauvegarde
            if (provider.isSaving) ...[
              const SizedBox(height: 16),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Traitement en cours...'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittedFilesList(
      BuildContext context, AssignmentSubmission submission) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: submission.files.length,
      itemBuilder: (context, index) {
        final fileName = submission.files[index].split('/').last;
        return ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text(fileName),
          trailing: IconButton(
            icon: const Icon(Icons.remove_red_eye),
            onPressed: () =>
                _viewSubmittedFile(context, submission.files[index]),
          ),
        );
      },
    );
  }

  Future<void> _showSubmissionDialog(
      BuildContext context,
      Assignment assignment,
      bool isOffline,
      AssignmentSubmissionProvider provider,
      {AssignmentSubmission? existingSubmission}) async {
    final commentController = TextEditingController();
    List<File> selectedFiles = [];

    if (existingSubmission != null && existingSubmission.comment != null) {
      commentController.text = existingSubmission.comment!;
    }

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existingSubmission != null
                          ? 'Modifier votre soumission'
                          : 'Soumettre votre devoir',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fichiers (${selectedFiles.length})',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (selectedFiles.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Aucun fichier sélectionné'),
                      )
                    else
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: 200,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: selectedFiles.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(
                                    selectedFiles[index].path.split('/').last),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      selectedFiles.removeAt(index);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final files = await _pickFiles(
                          context,
                          assignment.acceptedFileTypes,
                          maxSize: assignment.maxFileSize,
                        );
                        if (files.isNotEmpty) {
                          setState(() {
                            selectedFiles.addAll(files);
                          });
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Ajouter des fichiers'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        labelText: 'Commentaire (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: selectedFiles.isEmpty
                              ? null
                              : () {
                                  // Utiliser le provider pour soumettre
                                  provider.submitAssignment(
                                      assignment.id,
                                      selectedFiles,
                                      commentController.text,
                                      assignment.endDate != null &&
                                          DateTime.now()
                                              .isAfter(assignment.endDate!),
                                      existingSubmission: existingSubmission);
                                  Navigator.of(context).pop();
                                },
                          child: const Text('Soumettre'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteSubmission(
      BuildContext context,
      String submissionId,
      String assignmentId,
      AssignmentSubmissionProvider provider) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
            'Êtes-vous sûr de vouloir supprimer cette soumission ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteSubmission(submissionId, assignmentId);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<List<File>> _pickFiles(
      BuildContext context, List<String> acceptedTypes,
      {required int maxSize}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions:
            acceptedTypes.map((type) => type.replaceAll('.', '')).toList(),
      );

      if (result == null) return [];

      List<File> validFiles = [];
      List<String> oversizedFiles = [];

      for (var file in result.files) {
        if (file.size / (1024 * 1024) > maxSize) {
          oversizedFiles.add(file.name);
          continue;
        }

        final fileExt = file.extension?.toLowerCase() ?? '';
        if (!acceptedTypes
            .any((type) => type.toLowerCase().contains(fileExt))) {
          continue;
        }

        validFiles.add(File(file.path!));
      }

      if (oversizedFiles.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Certains fichiers dépassent la taille maximale: ${oversizedFiles.join(", ")}',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      return validFiles;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection des fichiers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    }
  }

  Future<void> _downloadAttachment(
      BuildContext context, AssignmentAttachment attachment) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléchargement en cours...')),
      );

      await _syncService.downloadAttachment(
        attachment,
        individualProgress: (progress) {
          // Afficher la progression si nécessaire
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document téléchargé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openAttachment(
      BuildContext context, AssignmentAttachment attachment) async {
    try {
      final localPath = await _syncService.getLocalAttachmentPath(attachment);
      print('Chemin local pour ${attachment.filename}: $localPath');

      if (localPath != null) {
        final file = File(localPath);
        final exists = await file.exists();
        print('Le fichier existe: $exists');

        await FileHelper.openResource(localPath, null, attachment.mimeType);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pièce jointe non disponible hors ligne'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Erreur lors de l\'ouverture de la pièce jointe: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture du document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewSubmittedFile(BuildContext context, String filePath) async {
    try {
      final isLocal = filePath.startsWith('/');
      if (isLocal) {
        // Fichier local
        final file = File(filePath);
        if (await file.exists()) {
          await FileHelper.openResource(filePath, null, '');
          return;
        }
      }

      // Fichier distant
      if (await _syncService.isOnline()) {
        final serverUrl = dotenv.env['SERVER_URL'] ?? '';
        final resourceUrl = '$serverUrl/$filePath';
        await FileHelper.openResource(null, resourceUrl, '');
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fichier non disponible hors ligne'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture du fichier: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return const Icon(Icons.image, color: Colors.blue);
    } else if (mimeType.startsWith('video/')) {
      return const Icon(Icons.video_file, color: Colors.red);
    } else if (mimeType.startsWith('audio/')) {
      return const Icon(Icons.audio_file, color: Colors.purple);
    } else if (mimeType == 'application/pdf') {
      return const Icon(Icons.picture_as_pdf, color: Colors.red);
    } else if (mimeType.contains('spreadsheet') || mimeType.contains('excel')) {
      return const Icon(Icons.table_chart, color: Colors.green);
    } else if (mimeType.contains('document') || mimeType.contains('word')) {
      return const Icon(Icons.description, color: Colors.blue);
    } else if (mimeType.contains('presentation') ||
        mimeType.contains('powerpoint')) {
      return const Icon(Icons.slideshow, color: Colors.orange);
    } else {
      return const Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kilobytes = bytes / 1024;
      return '${kilobytes.toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      final megabytes = bytes / (1024 * 1024);
      return '${megabytes.toStringAsFixed(1)} MB';
    } else {
      final gigabytes = bytes / (1024 * 1024 * 1024);
      return '${gigabytes.toStringAsFixed(1)} GB';
    }
  }
}
