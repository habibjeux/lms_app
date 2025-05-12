import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/jitsi_meeting_provider.dart.dart';
import '../../providers/meetings_provider.dart';

class MeetingScreen extends StatelessWidget {
  const MeetingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JitsiMeetingProvider>().joinMeeting(context);
    });

    return Consumer2<JitsiMeetingProvider, MeetingsProvider>(
      builder: (context, jitsiProvider, meetingsProvider, _) {
        final sessionTitle = meetingsProvider.sessionTitle;
        final courseTitle = meetingsProvider.courseTitle;

        return Scaffold(
          appBar: AppBar(
            title: Text(
                sessionTitle.isNotEmpty ? sessionTitle : 'Séance de cours'),
            actions: [
              IconButton(
                icon: const Icon(Icons.call_end),
                onPressed: () {
                  jitsiProvider.hangUp();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (jitsiProvider.state == JitsiMeetingState.loading)
                    Column(
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Connexion à la séance en cours...'),
                      ],
                    )
                  else if (jitsiProvider.state == JitsiMeetingState.error)
                    Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          jitsiProvider.errorMessage ??
                              'Une erreur est survenue',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => jitsiProvider.joinMeeting(context),
                          child: const Text('Réessayer'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Retour'),
                        ),
                      ],
                    )
                  else if (jitsiProvider.state == JitsiMeetingState.started)
                    const Text(
                      'Vous êtes en cours de réunion. Si l\'interface d\'appel n\'apparaît pas automatiquement, utilisez le bouton ci-dessous pour quitter.',
                      textAlign: TextAlign.center,
                    )
                  else
                    Column(
                      children: [
                        const Text(
                          'Prêt à rejoindre',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (courseTitle.isNotEmpty)
                          Text(
                            courseTitle,
                            style: const TextStyle(fontSize: 16),
                          ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => jitsiProvider.joinMeeting(context),
                          child: const Text('Rejoindre maintenant'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
