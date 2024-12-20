import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../widgets/module_list.dart';

class CourseDetailScreen extends StatelessWidget {
  final Course course;

  const CourseDetailScreen({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(course.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.code,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(course.description),
                ],
              ),
            ),
            if (course.modules != null && course.modules!.isNotEmpty)
              ModuleList(modules: course.modules!)
            else
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucun module disponible'),
              ),
          ],
        ),
      ),
    );
  }
}
