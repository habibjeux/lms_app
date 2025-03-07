import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isOnline = true;
  bool _shouldShowSnackbar = false;
  Timer? _checkTimer;
  final Connectivity _connectivity = Connectivity();
  final Duration _checkInterval = const Duration(seconds: 5);

  bool get isOnline => _isOnline;
  bool get shouldShowSnackbar => _shouldShowSnackbar;

  ConnectivityProvider() {
    _initConnectivity();
    _setupPeriodicCheck();
  }

  void _initConnectivity() {
    _connectivity.onConnectivityChanged.listen((result) async {
      await _checkConnectivity(result);
    });
    _checkCurrentConnectivity();
  }

  void _setupPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(_checkInterval, (timer) {
      _checkCurrentConnectivity();
    });
  }

  Future<void> _checkCurrentConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    await _checkConnectivity(connectivityResult);
  }

  Future<void> _checkConnectivity(List<ConnectivityResult> result) async {
    final wasOnline = _isOnline;
    bool isOnline = true;

    if (result.contains(ConnectivityResult.none)) {
      isOnline = false;
    } else {
      try {
        final result = await InternetAddress.lookup('google.com');
        isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        isOnline = false;
      }
    }

    if (wasOnline && !isOnline) {
      _shouldShowSnackbar = true;
    }

    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      notifyListeners();
    }
  }

  void hideSnackbar() {
    _shouldShowSnackbar = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}
