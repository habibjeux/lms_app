import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import 'meetings_provider.dart';

enum JitsiMeetingState {
  initial,
  loading,
  started,
  error,
}

class JitsiMeetingProvider with ChangeNotifier {
  final JitsiMeet _jitsiMeet = JitsiMeet();
  JitsiMeetingState _state = JitsiMeetingState.initial;
  String? _errorMessage;

  JitsiMeetingState get state => _state;
  String? get errorMessage => _errorMessage;
  JitsiMeet get jitsiMeet => _jitsiMeet;

  void _setState(JitsiMeetingState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(JitsiMeetingState.error);
  }

  Future<void> joinMeeting(BuildContext context) async {
    final meetingProvider = context.read<MeetingsProvider>();
    final user = context.read<AuthProvider>().user;

    if (user == null) {
      _setError('Utilisateur non connecté');
      return;
    }

    if (meetingProvider.token.isEmpty || meetingProvider.roomName.isEmpty) {
      _setError('Informations de séance non disponibles');
      return;
    }

    _setState(JitsiMeetingState.loading);

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
      _setState(JitsiMeetingState.started);
    } catch (e) {
      _setError('Impossible de rejoindre la réunion : ${e.toString()}');
    }
  }

  void hangUp() {
    _jitsiMeet.hangUp();
  }

  void reset() {
    _state = JitsiMeetingState.initial;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _jitsiMeet.hangUp();
    super.dispose();
  }
}
