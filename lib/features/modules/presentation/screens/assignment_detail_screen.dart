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
import '../../../../core/helper/DateHelper.dart';
import '../../../../core/helper/ResourceViewerHelper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    final connectivityProvider =
        Provider.of<ConnectivityProvider>(context, listen: false);

    if (connectivityProvider.isOnline) {
      await provider.loadAssignment(widget.assignmentId);
    } else {
      // En mode hors ligne, utiliser la méthode spécifique
      await provider.loadOfflineAssignment(widget.assignmentId);
    }
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
      onRefresh: () => _loadAssignment(),
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
              _buildAttachmentsSection(assignment.attachments),
            ],
            const SizedBox(height: 16),
            _buildAssignmentRequirements(assignment),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection(List<dynamic> attachments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.attach_file,
              color: Colors.teal,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Pièces jointes (${attachments.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.teal.withOpacity(0.05),
                Colors.teal.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.teal.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: attachments.asMap().entries.map((entry) {
              final index = entry.key;
              final attachment = entry.value;
              final isLast = index == attachments.length - 1;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft:
                        index == 0 ? const Radius.circular(12) : Radius.zero,
                    topRight:
                        index == 0 ? const Radius.circular(12) : Radius.zero,
                    bottomLeft:
                        isLast ? const Radius.circular(12) : Radius.zero,
                    bottomRight:
                        isLast ? const Radius.circular(12) : Radius.zero,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getFileColor(attachment.filename)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getFileIcon(attachment.filename),
                          color: _getFileColor(attachment.filename),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        attachment.filename,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: attachment.fileSize != null
                          ? Text(
                              _formatFileSize(attachment.fileSize),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            )
                          : null,
                      trailing:
                          Consumer2<AssignmentProvider, ConnectivityProvider>(
                        builder:
                            (context, provider, connectivityProvider, child) {
                          final attachmentId = attachment.id?.toString() ??
                              attachment.filename?.toString() ??
                              '';
                          final isDownloading =
                              provider.isDownloadingAttachment(attachmentId);
                          final isDownloaded =
                              provider.isAttachmentDownloaded(attachmentId);
                          final isOnline = connectivityProvider.isOnline;

                          // Vérifier le statut au chargement
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            provider.checkAttachmentStatus(attachmentId);
                          });

                          if (isDownloading) {
                            return const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            );
                          }

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _openAttachment(attachment),
                                icon: Icon(
                                  Icons.open_in_new,
                                  color: Colors.teal,
                                  size: 20,
                                ),
                                tooltip: 'Ouvrir',
                              ),
                              if (isOnline && !isDownloaded) ...[
                                IconButton(
                                  onPressed: () =>
                                      _downloadAttachment(attachment),
                                  icon: Icon(
                                    Icons.download,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  tooltip: 'Télécharger',
                                ),
                              ] else if (isDownloaded) ...[
                                Icon(
                                  Icons.offline_pin,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ] else if (!isOnline) ...[
                                Icon(
                                  Icons.cloud_off,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      onTap: () => _handleAttachmentTap(attachment),
                    ),
                    if (!isLast)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: Colors.grey[200],
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
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
          const SizedBox(height: 16),
          _buildSubmittedFilesSection(submission.files),
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

  // Méthodes pour les pièces jointes
  Color _getFileColor(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.green;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Colors.purple;
      case 'txt':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _getFileIcon(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_library;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _openAttachment(dynamic attachment) async {
    try {
      final provider = Provider.of<AssignmentProvider>(context, listen: false);
      final connectivityProvider =
          Provider.of<ConnectivityProvider>(context, listen: false);
      // Utiliser la même méthode que dans le provider pour l'ID
      final attachmentId =
          attachment.id?.toString() ?? attachment.filename?.toString() ?? '';
      final isOnline = connectivityProvider.isOnline;

      print(
          "🔍 Tentative d'ouverture pièce jointe: $attachmentId (${attachment.filename})");
      print("📱 Mode: ${isOnline ? 'en ligne' : 'hors ligne'}");

      // En mode hors ligne, utiliser UNIQUEMENT les fichiers locaux
      if (!isOnline) {
        print("🔒 Mode hors ligne - Vérification fichier local uniquement");
        if (provider.isAttachmentDownloaded(attachmentId)) {
          print("✅ Pièce jointe marquée comme téléchargée");
          final attachmentInfo =
              await provider.getAttachmentLocalPath(attachmentId);
          if (attachmentInfo != null && attachmentInfo['localPath'] != null) {
            print("📂 Ouverture depuis: ${attachmentInfo['localPath']}");
            await ResourceViewerHelper.openResource(
              context: context,
              resourcePath: attachmentInfo['localPath'],
              title: attachment.filename,
            );
          } else {
            print("❌ Chemin local introuvable dans les métadonnées");
            throw Exception(
                'Fichier non disponible hors ligne. Le téléchargement n\'a peut-être pas abouti.');
          }
        } else {
          print("❌ Pièce jointe non marquée comme téléchargée");
          throw Exception('Fichier non téléchargé. Non disponible hors ligne.');
        }
      } else {
        print("🌐 Mode en ligne - Privilégier local puis serveur");
        // En mode en ligne, privilégier le fichier local s'il existe, sinon le serveur
        if (provider.isAttachmentDownloaded(attachmentId)) {
          print("✅ Pièce jointe téléchargée - tentative ouverture locale");
          final attachmentInfo =
              await provider.getAttachmentLocalPath(attachmentId);
          if (attachmentInfo != null && attachmentInfo['localPath'] != null) {
            print(
                "📂 Ouverture depuis fichier local: ${attachmentInfo['localPath']}");
            await ResourceViewerHelper.openResource(
              context: context,
              resourcePath: attachmentInfo['localPath'],
              title: attachment.filename,
            );
          } else {
            print(
                "⚠️ Fichier marqué téléchargé mais introuvable - fallback serveur");
            // Fichier marqué comme téléchargé mais introuvable, essayer le serveur
            await _openAttachmentFromServer(attachment);
          }
        } else {
          print("🌐 Pièce jointe non téléchargée - ouverture depuis serveur");
          // Pas téléchargé, ouvrir depuis le serveur
          await _openAttachmentFromServer(attachment);
        }
      }
    } catch (e) {
      print("❌ Erreur ouverture pièce jointe: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openAttachmentFromServer(dynamic attachment) async {
    if (attachment.url != null && attachment.url.isNotEmpty) {
      final serverUrl = dotenv.env['SERVER_URL'] ?? '';
      final fullUrl = attachment.url.startsWith('http')
          ? attachment.url
          : '$serverUrl${attachment.url}';

      await ResourceViewerHelper.openResource(
        context: context,
        resourcePath: fullUrl,
        title: attachment.filename,
      );
    } else {
      throw Exception('URL de la pièce jointe non disponible.');
    }
  }

  Future<void> _downloadAttachment(dynamic attachment) async {
    try {
      final provider = Provider.of<AssignmentProvider>(context, listen: false);
      await provider.downloadAttachment(attachment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${attachment.filename} téléchargé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleAttachmentTap(dynamic attachment) {
    // Pour l'instant, on ouvre le fichier
    _openAttachment(attachment);
  }

  Widget _buildSubmittedFilesSection(List<String> files) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.upload_file,
              color: Colors.green,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Fichiers soumis (${files.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.withOpacity(0.05),
                Colors.green.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: files.asMap().entries.map((entry) {
              final index = entry.key;
              final filePath = entry.value;
              final filename = filePath.split('/').last;
              final isLast = index == files.length - 1;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft:
                        index == 0 ? const Radius.circular(12) : Radius.zero,
                    topRight:
                        index == 0 ? const Radius.circular(12) : Radius.zero,
                    bottomLeft:
                        isLast ? const Radius.circular(12) : Radius.zero,
                    bottomRight:
                        isLast ? const Radius.circular(12) : Radius.zero,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getFileColor(filename).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getFileIcon(filename),
                          color: _getFileColor(filename),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        filename,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        'Fichier soumis',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing:
                          Consumer2<AssignmentProvider, ConnectivityProvider>(
                        builder:
                            (context, provider, connectivityProvider, child) {
                          final isDownloading =
                              provider.isDownloadingSubmissionFile(filePath);
                          final isDownloaded =
                              provider.isSubmissionFileDownloaded(filePath);
                          final isOnline = connectivityProvider.isOnline;

                          // Vérifier le statut au chargement
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            provider.checkSubmissionFileStatus(filePath);
                          });

                          if (isDownloading) {
                            return const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            );
                          }

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _openSubmittedFile(filePath),
                                icon: Icon(
                                  Icons.open_in_new,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                tooltip: 'Ouvrir',
                              ),
                              if (isOnline && !isDownloaded) ...[
                                IconButton(
                                  onPressed: () =>
                                      _downloadSubmittedFile(filePath),
                                  icon: Icon(
                                    Icons.download,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  tooltip: 'Télécharger',
                                ),
                              ] else if (isDownloaded) ...[
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ] else if (!isOnline) ...[
                                Icon(
                                  Icons.cloud_off,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      onTap: () => _openSubmittedFile(filePath),
                    ),
                    if (!isLast)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: Colors.grey[200],
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _openSubmittedFile(String filePath) async {
    try {
      final provider = Provider.of<AssignmentProvider>(context, listen: false);
      final connectivityProvider =
          Provider.of<ConnectivityProvider>(context, listen: false);
      final filename = filePath.split('/').last;
      final isOnline = connectivityProvider.isOnline;

      print("🔍 Tentative d'ouverture fichier soumis: $filePath");
      print("📱 Mode: ${isOnline ? 'en ligne' : 'hors ligne'}");
      print("📄 Soumission actuelle ID: ${provider.currentSubmission?.id}");

      // En mode hors ligne, utiliser UNIQUEMENT les fichiers locaux
      if (!isOnline) {
        print("🔒 Mode hors ligne - Vérification fichier local uniquement");
        if (provider.isSubmissionFileDownloaded(filePath)) {
          print("✅ Fichier soumis marqué comme téléchargé");
          final fileInfo = await provider.getSubmissionFileLocalPath(filePath);
          print("📂 Informations récupérées: $fileInfo");
          if (fileInfo != null && fileInfo['localPath'] != null) {
            print("📂 Tentative d'ouverture depuis: ${fileInfo['localPath']}");
            await ResourceViewerHelper.openResource(
              context: context,
              resourcePath: fileInfo['localPath'],
              title: filename,
            );
          } else {
            print("❌ Chemin local introuvable dans les métadonnées");
            throw Exception(
                'Fichier non disponible hors ligne. Le téléchargement n\'a peut-être pas abouti.');
          }
        } else {
          print("❌ Fichier soumis non marqué comme téléchargé");
          throw Exception('Fichier non téléchargé. Non disponible hors ligne.');
        }
      } else {
        print("🌐 Mode en ligne - Privilégier local puis serveur");
        // En mode en ligne, privilégier le fichier local s'il existe, sinon le serveur
        if (provider.isSubmissionFileDownloaded(filePath)) {
          print("✅ Fichier soumis téléchargé - tentative ouverture locale");
          final fileInfo = await provider.getSubmissionFileLocalPath(filePath);
          print("📂 Informations récupérées: $fileInfo");
          if (fileInfo != null && fileInfo['localPath'] != null) {
            print(
                "📂 Ouverture depuis fichier local: ${fileInfo['localPath']}");
            await ResourceViewerHelper.openResource(
              context: context,
              resourcePath: fileInfo['localPath'],
              title: filename,
            );
          } else {
            print(
                "⚠️ Fichier marqué téléchargé mais introuvable - fallback serveur");
            // Fichier marqué comme téléchargé mais introuvable, essayer le serveur
            await _openSubmittedFileFromServer(filePath);
          }
        } else {
          print("🌐 Fichier soumis non téléchargé - ouverture depuis serveur");
          // Pas téléchargé, ouvrir depuis le serveur
          await _openSubmittedFileFromServer(filePath);
        }
      }
    } catch (e) {
      print("❌ Erreur ouverture fichier soumis: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openSubmittedFileFromServer(String filePath) async {
    final filename = filePath.split('/').last;

    // Si c'est un chemin relatif (commence par /), ajouter l'URL du serveur
    String resourcePath = filePath;
    if (filePath.startsWith('/') && !filePath.startsWith('http')) {
      final serverUrl = dotenv.env['SERVER_URL'] ?? '';
      resourcePath = '$serverUrl$filePath';
    }

    await ResourceViewerHelper.openResource(
      context: context,
      resourcePath: resourcePath,
      title: filename,
    );
  }

  Future<void> _downloadSubmittedFile(String filePath) async {
    try {
      final provider = Provider.of<AssignmentProvider>(context, listen: false);
      await provider.downloadSubmissionFile(filePath);

      if (mounted) {
        final filename = filePath.split('/').last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$filename téléchargé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
