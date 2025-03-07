import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/services/sync_service.dart';
import '../../../quizzes/data/providers/quiz_provider.dart';
import '../../models/activity.dart';
import '../../models/enums/activity_type.dart';
import '../../models/enums/resource_type.dart';
import '../../models/resource.dart';
import '../../../quizzes/presentation/screens/quiz_detail_screen.dart';
import '../screens/activity_detail_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityListItem extends StatefulWidget {
  final Activity activity;
  final String? chapterId;
  final String? moduleId;

  const ActivityListItem({
    super.key,
    required this.activity,
    this.chapterId,
    this.moduleId,
  });

  @override
  State<ActivityListItem> createState() => _ActivityListItemState();
}

class _ActivityListItemState extends State<ActivityListItem> {
  final SyncService _syncService = SyncService();
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.activity is Resource) {
      _checkDownloadStatus();
    } else if (widget.activity.type == ActivityType.QUIZ) {
      _checkQuizDownloadStatus();
    }
  }

  Future<void> _checkDownloadStatus() async {
    if (widget.activity is Resource) {
      final isDownloaded =
          await _syncService.isResourceDownloaded(widget.activity.id);
      if (mounted) {
        setState(() {
          _isDownloaded = isDownloaded;
        });
      }
    }
  }

  Future<void> _checkQuizDownloadStatus() async {
    if (widget.activity.type == ActivityType.QUIZ) {
      try {
        // Vérifier si le QuizProvider a la méthode isQuizDownloaded
        final quizProvider = Provider.of<QuizProvider>(context, listen: false);
        final isDownloaded =
            await quizProvider.isQuizDownloaded(widget.activity.id);
        if (mounted) {
          setState(() {
            _isDownloaded = isDownloaded;
          });
        }
      } catch (e) {
        // Ignorer l'erreur si la méthode n'existe pas
      }
    }
  }

  Future<void> _handleDownload() async {
    if (_isDownloading) return;

    // Cas des ressources
    if (widget.activity is Resource) {
      final resource = widget.activity as Resource;
      if (!resource.downloadable) return;

      setState(() {
        _isDownloading = true;
        _downloadProgress = 0;
      });

      try {
        await _syncService.downloadResource(
          resource,
          individualProgress: (progress) {
            if (mounted) {
              setState(() {
                _downloadProgress = progress;
              });
            }
          },
        );

        if (mounted) {
          setState(() {
            _isDownloaded = true;
            _isDownloading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ressource téléchargée avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors du téléchargement: $e')),
          );
        }
      }
    }
    // Cas des quiz
    else if (widget.activity.type == ActivityType.QUIZ) {
      setState(() {
        _isDownloading = true;
      });

      try {
        final quizProvider = Provider.of<QuizProvider>(context, listen: false);
        // Charger d'abord le quiz
        await quizProvider.loadQuiz(widget.activity.id);
        // Puis le télécharger
        await quizProvider.downloadQuizForOffline(widget.activity.id);

        if (mounted) {
          setState(() {
            _isDownloaded = true;
            _isDownloading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz téléchargé avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors du téléchargement: $e')),
          );
        }
      }
    }
  }

  Widget _buildDownloadStatus() {
    // Cas des ressources
    if (widget.activity is Resource) {
      final resource = widget.activity as Resource;
      if (!resource.downloadable) return const SizedBox.shrink();

      if (_isDownloading) {
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: _downloadProgress,
          ),
        );
      }

      return Consumer<ConnectivityProvider>(
        builder: (context, connectivity, _) {
          if (!connectivity.isOnline) {
            return Icon(
              _isDownloaded ? Icons.offline_pin : Icons.offline_bolt,
              color: _isDownloaded ? Colors.green : Colors.orange,
              size: 20,
            );
          }

          if (_isDownloaded) {
            return const Icon(Icons.cloud_done, color: Colors.green, size: 20);
          }

          return IconButton(
            icon: const Icon(Icons.cloud_download, size: 20),
            onPressed: _handleDownload,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          );
        },
      );
    }
    // Cas des quiz
    else if (widget.activity.type == ActivityType.QUIZ) {
      if (_isDownloading) {
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        );
      }

      return Consumer<ConnectivityProvider>(
        builder: (context, connectivity, _) {
          if (!connectivity.isOnline) {
            return Icon(
              _isDownloaded ? Icons.offline_pin : Icons.offline_bolt,
              color: _isDownloaded ? Colors.green : Colors.orange,
              size: 20,
            );
          }

          if (_isDownloaded) {
            return const Icon(Icons.cloud_done, color: Colors.green, size: 20);
          }

          return IconButton(
            icon: const Icon(Icons.cloud_download, size: 20),
            onPressed: _handleDownload,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  String _getFormattedDate(DateTime? date) {
    if (date == null) return '';
    return timeago.format(date, locale: 'fr');
  }

  bool _shouldDisplayActivity() {
    // Afficher les activités du chapitre
    if (widget.activity.chapterId == widget.chapterId) {
      return true;
    }

    // Afficher les activités du module si elles n'ont pas de chapterId
    // et si elles correspondent au moduleId fourni
    if (widget.activity.chapterId == null &&
        widget.moduleId != null &&
        widget.activity.moduleId == widget.moduleId) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        // Filtrer les activités
        if (!_shouldDisplayActivity()) {
          return const SizedBox.shrink();
        }

        // Construire l'interface
        return ListTile(
          leading: _buildActivityIcon(),
          title: Text(widget.activity.title),
          subtitle: widget.activity.startDate != null ||
                  widget.activity.endDate != null
              ? Text(
                  widget.activity.endDate != null
                      ? 'Se termine ${_getFormattedDate(widget.activity.endDate)}'
                      : 'Commence ${_getFormattedDate(widget.activity.startDate)}',
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDownloadStatus(),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
          onTap: () async {
            // Vérifier la disponibilité hors ligne pour les ressources
            if (!connectivity.isOnline &&
                widget.activity is Resource &&
                !_isDownloaded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Cette ressource n\'est pas disponible hors ligne'),
                ),
              );
              return;
            }

            // Vérifier la disponibilité hors ligne pour les quiz
            if (!connectivity.isOnline &&
                widget.activity.type == ActivityType.QUIZ &&
                !_isDownloaded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ce quiz n\'est pas disponible hors ligne'),
                ),
              );
              return;
            }

            // Navigation spécifique selon le type d'activité
            if (widget.activity.type == ActivityType.QUIZ) {
              final quizProvider =
                  Provider.of<QuizProvider>(context, listen: false);

              // Montrer un indicateur de chargement
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );

              try {
                // Charger le quiz
                await quizProvider.loadQuiz(widget.activity.id);

                // Charger les tentatives
                await quizProvider.loadQuizAttempts(widget.activity.id);

                // Fermer l'indicateur de chargement
                if (context.mounted) Navigator.pop(context);
                print("QuizProvider.currentQuiz: ${quizProvider.currentQuiz}");

                if (quizProvider.currentQuiz != null && context.mounted) {
                  // Naviguer vers l'écran de détails du quiz
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizDetailScreen(
                        quiz: quizProvider.currentQuiz!,
                      ),
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Impossible de charger le quiz')),
                  );
                }
              } catch (e) {
                // Fermer l'indicateur de chargement en cas d'erreur
                if (context.mounted) Navigator.pop(context);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            } else {
              // Pour les autres types d'activités, utiliser l'écran de détail existant
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActivityDetailScreen(
                    activity: widget.activity,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildActivityIcon() {
    if (widget.activity is Resource) {
      final resource = widget.activity as Resource;
      switch (resource.resourceType) {
        case ResourceType.PDF:
          return Icon(Icons.picture_as_pdf, color: _getActivityColor());
        case ResourceType.VIDEO:
          return Icon(Icons.video_library, color: _getActivityColor());
        case ResourceType.IMAGE:
          return Icon(Icons.image, color: _getActivityColor());
        case ResourceType.LINK:
          return Icon(Icons.link, color: _getActivityColor());
        case ResourceType.FILE:
          return Icon(Icons.insert_drive_file, color: _getActivityColor());
      }
    }

    switch (widget.activity.type) {
      case ActivityType.QUIZ:
        return Icon(Icons.quiz, color: _getActivityColor());
      case ActivityType.ASSIGNMENT:
        return Icon(Icons.assignment, color: _getActivityColor());
      case ActivityType.CONTENT:
        return Icon(Icons.subject, color: _getActivityColor());
      case ActivityType.RESOURCE:
        return Icon(Icons.article, color: _getActivityColor());
      default:
        return Icon(Icons.article, color: _getActivityColor());
    }
  }

  Color _getActivityColor() {
    if (widget.activity is Resource) {
      final resource = widget.activity as Resource;
      switch (resource.resourceType) {
        case ResourceType.PDF:
          return Colors.red;
        case ResourceType.VIDEO:
          return Colors.blue;
        case ResourceType.IMAGE:
          return Colors.green;
        case ResourceType.LINK:
          return Colors.purple;
        case ResourceType.FILE:
          return Colors.grey;
      }
    }

    switch (widget.activity.type) {
      case ActivityType.QUIZ:
        return Colors.orange;
      case ActivityType.ASSIGNMENT:
        return Colors.teal;
      case ActivityType.CONTENT:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}
