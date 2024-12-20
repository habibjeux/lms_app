import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/courses_provider.dart';
import '../widgets/course_card.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les cours au démarrage
    Future.microtask(
      () => context.read<CoursesProvider>().loadCourses(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes cours'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CoursesProvider>().loadCourses(),
          ),
        ],
      ),
      body: Consumer<CoursesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: () => provider.loadCourses(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (provider.courses.isEmpty) {
            return const Center(
              child: Text('Aucun cours disponible'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadCourses(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.courses.length,
              itemBuilder: (context, index) {
                final course = provider.courses[index];
                return CourseCard(
                  course: course,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/course-detail',
                    arguments: course,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
