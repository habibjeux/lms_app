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

import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/widgets/connectivity/offline_banner.dart';

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
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssignment();
      _checkDownloadStatus();
    });
  }

  Future<void> _loadAssignment() async {
    final provider = Provider.of<AssignmentProvider>(context, listen: false);
    await provider.loadAssignment(widget.assignmentId);
  }

  Future<void> _checkDownloadStatus() async {
    final provider = Provider.of<AssignmentProvider>(context, listen: false);
    final downloaded =
        await provider.isAssignmentDownloaded(widget.assignmentId);
    setState(() {
      _isDownloaded = downloaded;
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AssignmentProvider, ConnectivityProvider>(
      builder: (context, assignmentProvider, connectivityProvider, child) {
        final assignment = assignmentProvider.currentAssignment;
        final submission = assignmentProvider.currentSubmission;
        final isOnline = connectivityProvider.isOnline;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title ?? 'Devoir'),
            actions: [
              if (assignment != null && isOnline && !_isDownloaded)
                IconButton(
                  onPressed: assignmentProvider.isDownloading
                      ? null
                      : _downloadAssignment,
                  icon: assignmentProvider.isDownloading
                      ? CircularProgressIndicator(
                          value: assignmentProvider.downloadProgress,
                          strokeWidth: 2)
                      : const Icon(Icons.download),
                  tooltip: 'Télécharger le devoir',
                ),
              if (_isDownloaded)
                const Icon(Icons.offline_pin, color: Colors.green),
            ],
          ),
          body: Column(
            children: [
              if (!isOnline) const OfflineBanner(),
              Expanded(
                child: _buildBody(assignmentProvider, connectivityProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
      AssignmentProvider provider, ConnectivityProvider connectivityProvider) {
    if (provider.isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: ErrorMessage(
          message: provider.error!,
          onRetry: () => _loadAssignment(),
        ),
      );
    }

    final assignment = provider.currentAssignment;
    if (assignment == null) {
      return const Center(
        child: Text('Devoir introuvable'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(widget.assignmentId),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAssignmentHeader(assignment),
            const SizedBox(height: 24),
            _buildAssignmentDetails(assignment),
            const SizedBox(height: 24),
            _buildSubmissionSection(provider, connectivityProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentHeader(Assignment assignment) {
    final now = DateTime.now();
    final isOverdue =
        assignment.endDate != null && now.isAfter(assignment.endDate!);
    final isNotStarted =
        assignment.startDate != null && now.isBefore(assignment.startDate!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment,
                  size: 28,
                  color:
                      isOverdue ? Colors.red : Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    assignment.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isOverdue ? Colors.red : null,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (assignment.startDate != null) ...[
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Disponible depuis: ${_formatDate(assignment.startDate!)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (assignment.endDate != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: isOverdue ? Colors.red : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'À rendre avant: ${_formatDate(assignment.endDate!)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isOverdue ? Colors.red : Colors.orange,
                          fontWeight: isOverdue ? FontWeight.bold : null,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Note maximale: ${assignment.maxScore.toInt()} points',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            if (isNotStarted) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Pas encore disponible',
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ],
            if (isOverdue) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Date limite dépassée',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentDetails(Assignment assignment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instructions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              assignment.instructions.isNotEmpty
                  ? assignment.instructions
                  : 'Aucune instruction spécifique.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (assignment.attachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Pièces jointes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...assignment.attachments.map(
                (attachment) => ListTile(
                  leading: const Icon(Icons.attachment),
                  title: Text(attachment.filename),
                  trailing: const Icon(Icons.download),
                  onTap: () {
                    // TODO: Télécharger la pièce jointe
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildAssignmentRequirements(assignment),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentRequirements(Assignment assignment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exigences',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (assignment.acceptedFileTypes.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.file_present, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Types de fichiers acceptés: ${assignment.acceptedFileTypes.join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            const Icon(Icons.data_usage, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Taille maximale: ${_formatFileSize(assignment.maxFileSize)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        if (assignment.allowLateSubmission) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule_outlined,
                  size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Soumission tardive autorisée',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSubmissionSection(
      AssignmentProvider provider, ConnectivityProvider connectivityProvider) {
    final submission = provider.currentSubmission;
    final assignment = provider.currentAssignment!;
    final now = DateTime.now();
    final isOverdue =
        assignment.endDate != null && now.isAfter(assignment.endDate!);
    final isNotStarted =
        assignment.startDate != null && now.isBefore(assignment.startDate!);
    final canSubmit =
        !isNotStarted && (assignment.allowLateSubmission || !isOverdue);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ma soumission',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (submission != null)
              _buildExistingSubmission(
                  submission, provider, connectivityProvider.isOnline)
            else if (canSubmit)
              _buildSubmissionForm(provider, connectivityProvider.isOnline)
            else
              _buildCannotSubmit(isNotStarted, isOverdue),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingSubmission(AssignmentSubmission submission,
      AssignmentProvider provider, bool isOnline) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Soumission effectuée',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Le ${_formatDate(submission.submissionDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (submission.comment != null && submission.comment!.isNotEmpty) ...[
          Text(
            'Commentaire:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(submission.comment!),
          const SizedBox(height: 12),
        ],
        if (submission.files.isNotEmpty) ...[
          Text(
            'Fichiers soumis:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...submission.files.map(
            (filePath) => ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(filePath.split('/').last),
              dense: true,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (isOnline)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: provider.isLoading || !provider.canDeleteSubmission
                  ? null
                  : () => _deleteSubmission(submission),
              icon: Icon(
                Icons.delete,
                color: provider.canDeleteSubmission ? Colors.red : Colors.grey,
              ),
              label: Text(
                provider.canDeleteSubmission
                    ? 'Supprimer la soumission'
                    : 'Suppression impossible (date limite dépassée)',
                style: TextStyle(
                  color:
                      provider.canDeleteSubmission ? Colors.red : Colors.grey,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmissionForm(AssignmentProvider provider, bool isOnline) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sélection de fichiers
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: _pickFiles,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cliquez pour sélectionner vos fichiers',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    'ou glissez-déposez ici',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Fichiers sélectionnés
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Fichiers sélectionnés:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ..._selectedFiles.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(file.path.split('/').last),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _selectedFiles.removeAt(index);
                  });
                },
              ),
            );
          }),
        ],

        const SizedBox(height: 16),

        // Commentaire
        TextField(
          controller: _commentController,
          decoration: const InputDecoration(
            labelText: 'Commentaire (optionnel)',
            hintText: 'Ajoutez un commentaire à votre soumission...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),

        const SizedBox(height: 16),

        // Bouton de soumission
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            onPressed: provider.isSubmitting ? null : _submitAssignment,
            isLoading: provider.isSubmitting,
            child: Text(
              isOnline
                  ? 'Soumettre le devoir'
                  : 'Sauvegarder (sera synchronisé en ligne)',
            ),
          ),
        ),

        if (provider.isSubmitting) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(value: provider.submitProgress),
          const SizedBox(height: 8),
          Text(
            'Envoi en cours... ${(provider.submitProgress * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildCannotSubmit(bool isNotStarted, bool isOverdue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isNotStarted ? Icons.schedule : Icons.block,
            color: Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isNotStarted
                  ? 'Ce devoir n\'est pas encore disponible'
                  : 'La date limite de soumission est dépassée',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAssignment() async {
    final provider = Provider.of<AssignmentProvider>(context, listen: false);
    await provider.downloadAssignmentForOffline(widget.assignmentId);
    await _checkDownloadStatus();
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

  Future<void> _submitAssignment() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un fichier'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final provider = Provider.of<AssignmentProvider>(context, listen: false);
    await provider.submitAssignment(
      widget.assignmentId,
      _selectedFiles,
      _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
    );

    if (provider.error == null) {
      setState(() {
        _selectedFiles.clear();
        _commentController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devoir soumis avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteSubmission(AssignmentSubmission submission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la soumission'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette soumission ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = Provider.of<AssignmentProvider>(context, listen: false);
      await provider.deleteSubmission(submission.id, widget.assignmentId);

      if (provider.error == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Soumission supprimée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
