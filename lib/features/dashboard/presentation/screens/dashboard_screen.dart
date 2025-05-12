import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lms_app/features/meeting/presentation/screens/sessions_list_screen.dart';
import 'package:lms_app/features/modules/presentation/screens/modules_screen.dart';
import '../../../../core/providers/dashboard_provider.dart';
import '../../../messaging/presentation/screens/discussions_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../widgets/student_drawer.dart';
import 'home_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static final List<Widget> _pages = [
    const HomeScreen(),
    const ModulesScreen(),
    const DiscussionsScreen(),
    const SessionsListScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, _) {
        return Scaffold(
          drawer: const StudentDrawer(),
          body: _pages[dashboardProvider.currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: dashboardProvider.currentIndex,
            onDestinationSelected: (index) {
              dashboardProvider.setCurrentIndex(index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Accueil',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: 'Modules',
              ),
              NavigationDestination(
                icon: Icon(Icons.forum_outlined),
                selectedIcon: Icon(Icons.forum),
                label: 'Forums',
              ),
              NavigationDestination(
                icon: Icon(Icons.video_call_outlined),
                selectedIcon: Icon(Icons.video_call),
                label: 'Réunions',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
