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
    super.key,
    required this.assignmentId,
    this.moduleId,
    this.chapterId,
    this.title,
  });

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
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            elevation: 0,
            toolbarHeight: 40,
            actions: [
              if (assignment != null && isOnline && !_isDownloaded)
                IconButton(
                  onPressed: assignmentProvider.isDownloading
                      ? null
                      : _downloadAssignment,
                  icon: assignmentProvider.isDownloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download),
                  tooltip: 'Télécharger le devoir',
                ),
              if (_isDownloaded)
                const Icon(Icons.offline_pin, color: Colors.white),
            ],
          ),
          body: Column(
            children: [
              if (!isOnline) const OfflineBanner(),
              const SizedBox(height: 8),
              if (assignment != null) _buildAssignmentHeader(assignment),
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
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAssignmentDetails(assignment),
            const SizedBox(height: 16),
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

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal,
            Colors.teal.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.assignment,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${assignment.maxScore.toInt()} points',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (assignment.startDate != null || assignment.endDate != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (assignment.startDate != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Disponible depuis: ${_formatDate(assignment.startDate!)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  if (assignment.endDate != null) ...[
                    if (assignment.startDate != null) const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: isOverdue ? Colors.orange[100] : Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'À rendre avant: ${_formatDate(assignment.endDate!)}',
                          style: TextStyle(
                            color:
                                isOverdue ? Colors.orange[100] : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (isNotStarted || isOverdue) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isOverdue
                    ? Colors.red.withOpacity(0.2)
                    : Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isOverdue ? 'Date limite dépassée' : 'Pas encore disponible',
                style: TextStyle(
                  color: isOverdue ? Colors.orange[100] : Colors.lightBlue[100],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssignmentDetails(Assignment assignment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.withOpacity(0.8),
                Colors.green.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Soumission effectuée',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Le ${_formatDate(submission.submissionDate)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.teal.withOpacity(0.05),
                Colors.teal.withOpacity(0.1),
              ],
            ),
            border: Border.all(
              color: Colors.teal.withOpacity(0.3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: _pickFiles,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.cloud_upload,
                      size: 32,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cliquez pour sélectionner vos fichiers',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ou glissez-déposez ici',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.teal.withOpacity(0.7),
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
    final Color primaryColor = isNotStarted ? Colors.blue : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              isNotStarted ? Icons.schedule : Icons.block,
              size: 32,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isNotStarted
                ? 'Ce devoir n\'est pas encore disponible'
                : 'La date limite de soumission est dépassée',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isNotStarted
                ? 'Vous pourrez soumettre votre travail une fois le devoir ouvert.'
                : 'Vous ne pouvez plus soumettre de travail pour ce devoir.',
            style: TextStyle(
              fontSize: 14,
              color: primaryColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
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
