import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/meetings_provider.dart';

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  MeetingScreenState createState() => MeetingScreenState();
}

class MeetingScreenState extends State<MeetingScreen> {
  final JitsiMeet _jitsiMeet = JitsiMeet();
  bool _isLoading = false;
  bool _hasMeetingStarted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _joinMeeting(context);
    });
  }

  Future<void> _joinMeeting(BuildContext context) async {
    final meetingProvider = context.read<MeetingsProvider>();
    final user = context.read<AuthProvider>().user;

    if (user == null) {
      setState(() {
        _errorMessage = 'Utilisateur non connecté';
      });
      return;
    }

    if (meetingProvider.token.isEmpty || meetingProvider.roomName.isEmpty) {
      setState(() {
        _errorMessage = 'Informations de séance non disponibles';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Map<String, dynamic> configOverrides = {
        "startWithAudioMuted": true,
        "startWithVideoMuted": true,
        "prejoinPageEnabled": false,
      };

      configOverrides["toolbarButtons"] = [
        'microphone',
        'camera',
        'hangup',
        'chat',
        'raisehand',
        'videoquality',
        'filmstrip',
        'tileview',
        'help',
      ];

      configOverrides["liveStreamingEnabled"] = false;
      configOverrides["recordingEnabled"] = true;
      configOverrides["disableInviteFunctions"] = true;
      configOverrides["disablePolls"] = true;
      configOverrides["disablePrivateChat"] = true;

      final options = JitsiMeetConferenceOptions(
        serverURL: "https://8x8.vc",
        room: meetingProvider.roomName,
        token: meetingProvider.token,
        configOverrides: configOverrides,
        featureFlags: {
          "ios.screensharing.enabled": true,
          "android.screensharing.enabled": true,
          "meeting-name.enabled": true,
          "chat.private.enabled": false,
          "recording.enabled": true
        },
        userInfo: JitsiMeetUserInfo(
          displayName: '${user.firstName} ${user.lastName}',
          email: user.email,
        ),
      );

      await _jitsiMeet.join(options);
      setState(() {
        _hasMeetingStarted = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de rejoindre la réunion : ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetingProvider = context.watch<MeetingsProvider>();
    final sessionTitle = meetingProvider.sessionTitle;
    final courseTitle = meetingProvider.courseTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(sessionTitle.isNotEmpty ? sessionTitle : 'Séance de cours'),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_end),
            onPressed: () {
              _jitsiMeet.hangUp();
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
              if (_isLoading)
                Column(
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Connexion à la séance en cours...'),
                  ],
                )
              else if (_errorMessage != null)
                Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _joinMeeting(context),
                      child: const Text('Réessayer'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Retour'),
                    ),
                  ],
                )
              else if (_hasMeetingStarted)
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
                      onPressed: () => _joinMeeting(context),
                      child: const Text('Rejoindre maintenant'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _jitsiMeet.hangUp();
    super.dispose();
  }
}
