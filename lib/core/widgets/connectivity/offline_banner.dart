import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/connectivity_provider.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, provider, child) {
        if (provider.isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          color: Colors.orange,
          child: Row(
            children: const [
              Icon(
                Icons.wifi_off,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vous êtes hors ligne. Les messages seront envoyés dès que vous serez connecté.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
