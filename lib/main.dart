import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lms_app/features/auth/presentation/screens/login_screen.dart';
import 'package:lms_app/features/forum/providers/forums_provider.dart';
import 'package:lms_app/features/messaging/providers/messaging_provider.dart';
import 'package:lms_app/features/modules/providers/modules_provider.dart';
import 'package:provider/provider.dart';

import 'core/providers/connectivity_provider.dart';
import 'core/providers/dashboard_provider.dart';
import 'core/providers/expandable_text_field_provider.dart';
import 'core/providers/login_form_provider.dart';
import 'core/services/download_storage_service.dart';
import 'core/widgets/connectivity/connectivity_overlay.dart';
import 'features/auth/presentation/widgets/auth_wrapper_first.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/downloads/providers/download_provider.dart';
import 'features/meeting/providers/jitsi_meeting_provider.dart.dart';
import 'features/meeting/providers/meetings_provider.dart';
import 'features/modules/models/module.dart';
import 'features/modules/presentation/screens/module_detail_screen.dart';
import 'features/modules/presentation/screens/modules_screen.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/date_symbol_data_local.dart';

import 'features/modules/providers/activity_provider.dart';
import 'features/quizzes/data/providers/quiz_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);

  timeago.setLocaleMessages('fr', timeago.FrMessages());
  await initializeDateFormatting('fr_FR', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(
            create: (_) => AuthProvider(context, listen: false)),
        ChangeNotifierProvider(create: (_) => ModulesProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => MeetingsProvider()),
        ChangeNotifierProvider(create: (_) => ForumProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => MessagingProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
        ChangeNotifierProvider(create: (_) => LoginFormProvider()),
        ChangeNotifierProvider(create: (_) => JitsiMeetingProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ExpandableTextFieldProvider()),
        Provider(create: (_) => DownloadStorageService()),
      ],
      child: MaterialApp(
          builder: (context, child) => ConnectivityOverlay(child: child!),
          home: const AuthWrapperFirst(),
          title: 'LMS App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          routes: {
            '/modules': (context) => const ModulesScreen(),
            '/login': (context) => const LoginScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/module-detail') {
              final module = settings.arguments as Module;
              return MaterialPageRoute(
                builder: (context) => ModuleDetailScreen(module: module),
              );
            }
            return null;
          }),
    );
  }
}
