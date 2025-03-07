import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/connectivity_provider.dart';

class ConnectivityOverlay extends StatelessWidget {
  final Widget child;

  const ConnectivityOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        if (connectivity.shouldShowSnackbar) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context)
                .showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Vous êtes hors ligne'),
                      ],
                    ),
                    duration: const Duration(seconds: 3),
                    backgroundColor: Colors.orange,
                  ),
                )
                .closed
                .then((_) => connectivity.hideSnackbar());
          });
        }

        return Stack(
          children: [
            child,
            if (!connectivity.isOnline)
              Positioned(
                top: MediaQuery.of(context).viewPadding.top + 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.offline_bolt, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Hors ligne',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
