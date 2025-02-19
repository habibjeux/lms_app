import 'package:flutter/material.dart';
import 'package:lms_app/features/auth/presentation/screens/login_screen.dart';
import 'package:lms_app/features/forum/providers/forums_provider.dart';
import 'package:lms_app/features/modules/providers/modules_provider.dart';
import 'package:provider/provider.dart';

import 'core/providers/connectivity_provider.dart';
import 'core/widgets/connectivity/connectivity_overlay.dart';
import 'features/auth/presentation/widgets/auth_wrapper_first.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/meeting/providers/meetings_provider.dart';
import 'features/modules/models/module.dart';
import 'features/modules/presentation/screens/module_detail_screen.dart';
import 'features/modules/presentation/screens/modules_screen.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:timeago/timeago.dart' as timeago;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);

  timeago.setLocaleMessages('fr', timeago.FrMessages());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ModulesProvider()),
        ChangeNotifierProvider(create: (_) => MeetingsProvider()),
        ChangeNotifierProvider(create: (_) => ForumProvider()),
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
