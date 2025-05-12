import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/jitsi_meeting_provider.dart.dart';
import 'meeting_screen.dart';

class MeetingScreenWrapper extends StatefulWidget {
  const MeetingScreenWrapper({super.key});

  @override
  State<MeetingScreenWrapper> createState() => _MeetingScreenWrapperState();
}

class _MeetingScreenWrapperState extends State<MeetingScreenWrapper> {
  @override
  void initState() {
    super.initState();
    context.read<JitsiMeetingProvider>().reset();
  }

  @override
  void dispose() {
    context.read<JitsiMeetingProvider>().hangUp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const MeetingScreen();
  }
}
