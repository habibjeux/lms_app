import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'providers/messaging_provider.dart';
import 'presentation/screens/discussions_screen.dart';
import '../../core/services/messaging_sync_service.dart';

/// Cette classe s'occupe de l'initialisation de la messagerie
/// et fournit des méthodes utilitaires pour accéder aux fonctionnalités de messagerie.
class MessagingInitialization {
  static bool _initialized = false;
  static final MessagingSyncService _syncService = MessagingSyncService();

  /// Initialise les composants nécessaires pour la messagerie.
  /// À appeler dans le main.dart après l'initialisation de Hive.
  static Future<void> initialize() async {
    if (_initialized) return;

    await _registerHiveAdapters();
    await _syncPendingMessages(); // Synchronisation au démarrage

    _initialized = true;
  }

  /// Configure les boxs Hive pour la messagerie
  static Future<void> _registerHiveAdapters() async {
    // Ouvrir les boxs nécessaires si ce n'est pas déjà fait
    if (!Hive.isBoxOpen('discussions')) {
      await Hive.openBox('discussions');
    }
    if (!Hive.isBoxOpen('messages')) {
      await Hive.openBox('messages');
    }
    if (!Hive.isBoxOpen('pending_messages')) {
      await Hive.openBox('pending_messages');
    }
    if (!Hive.isBoxOpen('lastSync')) {
      await Hive.openBox('lastSync');
    }
  }

  /// Synchronise les messages en attente
  static Future<void> _syncPendingMessages() async {
    try {
      await _syncService.syncPendingMessages();
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation initiale: $e');
    }
  }

  /// Retourne le nombre de messages non lus
  static Future<int> getUnreadMessagesCount() async {
    return _syncService.getUnreadMessagesCount();
  }

  /// Retourne le nombre de messages en attente d'envoi
  static Future<int> getPendingMessagesCount() async {
    return _syncService.getPendingMessagesCount();
  }

  /// Démarre une nouvelle tâche périodique pour synchroniser les messages
  static void startPeriodicSync(Duration interval) {
    // À implémenter avec workmanager ou une autre solution si nécessaire
  }

  /// Configure le provider de messagerie dans le MultiProvider
  static ChangeNotifierProvider<MessagingProvider> getProvider() {
    return ChangeNotifierProvider<MessagingProvider>(
      create: (_) => MessagingProvider(),
    );
  }

  /// Ouvre la page des discussions
  static void navigateToDiscussions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DiscussionsScreen()),
    );
  }
}
