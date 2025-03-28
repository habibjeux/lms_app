import 'package:flutter/material.dart';

class SyncIndicator extends StatelessWidget {
  final int pendingCount;
  final bool isSyncing;
  final VoidCallback onPressed;

  const SyncIndicator({
    super.key,
    this.pendingCount = 0,
    this.isSyncing = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingCount == 0 && !isSyncing) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: isSyncing ? null : onPressed,
      tooltip: 'Synchroniser les messages en attente',
      icon: Stack(
        alignment: Alignment.center,
        children: [
          if (isSyncing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            const Icon(Icons.sync),
          if (pendingCount > 0 && !isSyncing)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  pendingCount < 100 ? '$pendingCount' : '99+',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
