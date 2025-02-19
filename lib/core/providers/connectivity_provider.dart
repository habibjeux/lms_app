import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  final Connectivity _connectivity = Connectivity();

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _updateConnectionStatus(await _connectivity.checkConnectivity());
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    _isConnected = result != [ConnectivityResult.none];
    notifyListeners();
  }
}
