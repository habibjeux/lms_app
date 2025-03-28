import 'package:flutter/material.dart';

class NewDiscussionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const NewDiscussionButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: 'Nouvelle discussion',
      child: const Icon(Icons.message),
    );
  }
}
