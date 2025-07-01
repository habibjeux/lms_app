import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../models/quiz.dart';
import '../../providers/quiz_provider.dart';
import 'quiz_session_screen.dart';

class QuizDetailScreen extends StatefulWidget {
  final String quizId;

  const QuizDetailScreen({
    super.key,
    required this.quizId,
  });

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().loadQuiz(widget.quizId);
      _checkDownloadStatus();
    });
  }

  Future<void> _checkDownloadStatus() async {
    final provider = context.read<QuizProvider>();
    final downloaded = await provider.isQuizDownloaded(widget.quizId);
    if (mounted) {
      setState(() {
        _isDownloaded = downloaded;
      });
    }
  }

  Future<void> _downloadQuiz(QuizProvider provider) async {
    try {
      await provider.downloadQuizForOffline(widget.quizId);
      if (mounted) {
        setState(() {
          _isDownloaded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz téléchargé avec succès !'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 40,
        actions: [
          Consumer<QuizProvider>(
            builder: (context, quizProvider, child) {
              final isDownloading = quizProvider.isDownloading;

              return IconButton(
                onPressed: _isDownloaded || isDownloading
                    ? null
                    : () => _downloadQuiz(quizProvider),
                icon: isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : _isDownloaded
                        ? const Icon(Icons.offline_pin, color: Colors.white)
                        : const Icon(Icons.download),
                tooltip: _isDownloaded
                    ? 'Quiz téléchargé'
                    : isDownloading
                        ? 'Téléchargement en cours...'
                        : 'Télécharger le quiz',
              );
            },
          ),
        ],
      ),
      body: Consumer2<QuizProvider, ConnectivityProvider>(
        builder: (context, quizProvider, connectivityProvider, child) {
          if (quizProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (quizProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      quizProvider.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => quizProvider.loadQuiz(widget.quizId),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final quiz = quizProvider.currentQuiz;
          if (quiz == null) {
            return const Center(
              child: Text('Quiz non trouvé'),
            );
          }

          return Column(
            children: [
              const SizedBox(height: 8),
              _buildQuizHeader(quiz),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informations détaillées
                      _buildQuizInfo(quiz),
                      const SizedBox(height: 16),

                      // Tentatives précédentes
                      if (quizProvider.attempts.isNotEmpty) ...[
                        _buildAttemptsSection(quizProvider.attempts),
                        const SizedBox(height: 16),
                      ],

                      // Boutons d'action
                      _buildActionButtons(
                          context, quiz, quizProvider, connectivityProvider),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuizHeader(Quiz quiz) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange,
            Colors.orange.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
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
                  Icons.quiz,
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
                      quiz.title,
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
                        '${_formatScore(quiz.maxScore)} points',
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
          if (quiz.startDate != null || quiz.endDate != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (quiz.startDate != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.event,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Disponible à partir du: ${_formatDate(quiz.startDate!)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  if (quiz.endDate != null) ...[
                    if (quiz.startDate != null) const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.event_busy,
                          color:
                              quiz.isExpired ? Colors.red[200] : Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Disponible jusqu\'au: ${_formatDate(quiz.endDate!)}',
                          style: TextStyle(
                            color:
                                quiz.isExpired ? Colors.red[200] : Colors.white,
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
          if (!quiz.isAvailable) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: quiz.isExpired
                    ? Colors.red.withOpacity(0.2)
                    : Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                quiz.isExpired ? 'Quiz expiré' : 'Quiz non disponible',
                style: TextStyle(
                  color:
                      quiz.isExpired ? Colors.red[200] : Colors.lightBlue[200],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizInfo(Quiz quiz) {
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
              'Informations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.access_time,
              label: 'Durée',
              value: quiz.durationText,
            ),
            _buildInfoRow(
              icon: Icons.help_outline,
              label: 'Questions',
              value:
                  '${quiz.questionCount} question${quiz.questionCount > 1 ? 's' : ''}',
            ),
            _buildInfoRow(
              icon: Icons.grade,
              label: 'Score maximum',
              value: '${_formatScore(quiz.maxScore)} points',
            ),
            _buildInfoRow(
              icon: Icons.repeat,
              label: 'Tentatives autorisées',
              value: quiz.maxAttempts.toString(),
            ),
            _buildInfoRow(
              icon: Icons.check_circle_outline,
              label: 'Score de passage',
              value: '${(quiz.passingScore * 100).toStringAsFixed(0)}%',
            ),
            if (quiz.startDate != null)
              _buildInfoRow(
                icon: Icons.event,
                label: 'Disponible à partir du',
                value: _formatDate(quiz.startDate!),
              ),
            if (quiz.endDate != null)
              _buildInfoRow(
                icon: Icons.event_busy,
                label: 'Disponible jusqu\'au',
                value: _formatDate(quiz.endDate!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptsSection(List attempts) {
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
              'Tentatives précédentes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...attempts.map((attempt) => _buildAttemptItem(attempt)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttemptItem(dynamic attempt) {
    final Color statusColor =
        attempt.isCompleted ? Colors.green : Colors.orange;

    return Consumer<QuizProvider>(
      builder: (context, quizProvider, child) {
        final maxScore = quizProvider.currentQuiz?.maxScore ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                statusColor.withOpacity(0.1),
                statusColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  attempt.isCompleted ? Icons.check_circle : Icons.pending,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tentative du ${_formatDate(attempt.startDate)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score: ${_formatScore(attempt.score)}/${_formatScore(maxScore)}',
                      style: TextStyle(
                        color: statusColor.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (attempt.endDate != null)
                      Text(
                        'Durée: ${attempt.timeSpentText}',
                        style: TextStyle(
                          color: statusColor.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  attempt.isCompleted ? 'Terminé' : 'En cours',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Formater les scores pour afficher les entiers sans décimales
  String _formatScore(double score) {
    if (score == score.roundToDouble()) {
      return score.round().toString();
    } else {
      return score.toStringAsFixed(1);
    }
  }

  Widget _buildActionButtons(
    BuildContext context,
    Quiz quiz,
    QuizProvider quizProvider,
    ConnectivityProvider connectivityProvider,
  ) {
    // Vérifier si l'utilisateur a atteint le nombre maximum de tentatives
    final hasReachedMaxAttempts =
        quizProvider.attempts.length >= quiz.maxAttempts;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Message d'erreur pour tentatives dépassées
            if (hasReachedMaxAttempts) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.red.withOpacity(0.1),
                      Colors.red.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.block,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vous avez atteint le nombre maximum de tentatives autorisées (${quiz.maxAttempts}) pour ce quiz.',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Bouton principal
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: quiz.isAvailable && connectivityProvider.isOnline
                        ? [Colors.orange, Colors.orange.withOpacity(0.8)]
                        : [Colors.grey[400]!, Colors.grey[300]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: quiz.isAvailable && connectivityProvider.isOnline
                      ? [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: ElevatedButton.icon(
                  onPressed: quiz.isAvailable && connectivityProvider.isOnline
                      ? () => _startQuiz(context, quizProvider)
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    quiz.isAvailable
                        ? 'Commencer le quiz'
                        : quiz.isExpired
                            ? 'Quiz expiré'
                            : 'Quiz non disponible',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Message hors ligne
              if (!connectivityProvider.isOnline) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.withOpacity(0.1),
                        Colors.orange.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.wifi_off,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Connexion Internet requise pour passer le quiz',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _startQuiz(BuildContext context, QuizProvider quizProvider) async {
    try {
      await quizProvider.startQuizAttempt();

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const QuizSessionScreen(),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du démarrage du quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
