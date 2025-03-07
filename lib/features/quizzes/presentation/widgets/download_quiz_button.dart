import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../data/providers/quiz_provider.dart';

class DownloadQuizButton extends StatelessWidget {
  final String quizId;

  const DownloadQuizButton({
    super.key,
    required this.quizId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<QuizProvider, ConnectivityProvider>(
      builder: (context, quizProvider, connectivityProvider, _) {
        final isDownloaded = quizProvider.isDownloaded;
        final isOnline = connectivityProvider.isOnline;

        // En mode hors ligne, ne pas afficher le bouton si le quiz n'est pas déjà téléchargé
        if (!isOnline && !isDownloaded) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: quizProvider.isLoading
                ? null
                : isDownloaded
                    ? () => _removeDownload(context, quizProvider)
                    : () => _downloadQuiz(context, quizProvider),
            icon: Icon(
              isDownloaded ? Icons.cloud_done : Icons.cloud_download,
              color: isDownloaded ? Colors.green : Colors.blue,
            ),
            label: Text(
              isDownloaded
                  ? 'Disponible hors ligne'
                  : 'Télécharger pour utilisation hors ligne',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  (isDownloaded ? Colors.green : Colors.blue).withOpacity(0.1),
              foregroundColor: isDownloaded ? Colors.green : Colors.blue,
              elevation: 0,
              side: BorderSide(
                color: (isDownloaded ? Colors.green : Colors.blue)
                    .withOpacity(0.5),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadQuiz(
    BuildContext context,
    QuizProvider provider,
  ) async {
    try {
      await provider.downloadQuizForOffline(quizId);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz disponible hors ligne'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors du téléchargement'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeDownload(
    BuildContext context,
    QuizProvider provider,
  ) async {
    await provider.removeDownloadedQuiz(quizId);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quiz supprimé du mode hors ligne'),
      ),
    );
  }
}
