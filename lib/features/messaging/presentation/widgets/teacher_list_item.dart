import 'package:flutter/material.dart';
import '../../../auth/models/user.dart';

class TeacherListItem extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const TeacherListItem({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        child: Text(
          _getTeacherInitials(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        '${user.firstName} ${user.lastName}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(user.role == UserRole.TEACHER ? 'Professeur' : 'Etudiant'),
      trailing: const Icon(Icons.message),
    );
  }

  String _getTeacherInitials() {
    String initials = '';
    if (user.firstName.isNotEmpty) {
      initials += user.firstName[0].toUpperCase();
    }
    if (user.lastName.isNotEmpty) {
      initials += user.lastName[0].toUpperCase();
    }
    return initials.isNotEmpty ? initials : '?';
  }
}
