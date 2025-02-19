import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/meetings_provider.dart';

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  _MeetingScreenState createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  final JitsiMeet _jitsiMeet = JitsiMeet();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _joinMeeting(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final meetingProvider = context.read<MeetingsProvider>();
    final user = authProvider.user;
    final appId = 'vpaas-magic-cookie-7179a7d37d344199899dd8e8cb24afb4';

    if (user == null) {
      setState(() {
        _errorMessage = 'Utilisateur non connecté';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await meetingProvider.loadJitsiToken();
      final token = meetingProvider.token;

      final options = JitsiMeetConferenceOptions(
        serverURL: "https://8x8.vc",
        room: "$appId/course-session-1", //

        token: token,
        configOverrides: {
          "startWithAudioMuted": true,
          "startWithVideoMuted": true,
          "prejoinPageEnabled": false,
        },
        featureFlags: {
          "ios.screensharing.enabled": true,
          "android.screensharing.enabled": true,
          "meeting-name-set": true,
        },
      );

      await _jitsiMeet.join(options);
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
    final user = context.read<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réunion de cours'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                Text(
                  'Bienvenue, ${user?.firstName}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _joinMeeting(context),
                  child: const Text('Rejoindre la réunion'),
                ),
              ],
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
