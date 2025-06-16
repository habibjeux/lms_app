import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../auth/models/user.dart';
import '../../../core/services/messaging_sync_service.dart';
import '../models/discussion.dart';
import '../models/message.dart';
import 'dart:async';
import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';

class MessagingProvider with ChangeNotifier {
  final MessagingSyncService _syncService = MessagingSyncService(
    ApiClient.uploadInstance,
    AuthRepository(),
  );
  Timer? _syncTimer;

  List<Discussion> _discussions = [];
  Discussion? _currentDiscussion;
  List<Message> _messages = [];
  bool _isLoadingDiscussions = false;
  bool _isLoadingMessages = false;
  bool _isSendingMessage = false;
  bool _isSyncing = false;
  String? _error;
  int _unreadCount = 0;
  int _pendingMessagesCount = 0;

  MessagingProvider() {
    _startAutoSync();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  void _startAutoSync() {
    // Synchroniser toutes les 30 secondes
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isSyncing) {
        syncPendingMessages();
      }
    });
  }

  // Getters
  List<Discussion> get discussions => _discussions;
  Discussion? get currentDiscussion => _currentDiscussion;
  List<Message> get messages => _messages;
  bool get isLoadingDiscussions => _isLoadingDiscussions;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSendingMessage => _isSendingMessage;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  int get pendingMessagesCount => _pendingMessagesCount;

  // Charge toutes les discussions
  Future<void> loadDiscussions() async {
    _setLoadingDiscussions(true);
    _clearError();

    try {
      _discussions = await _syncService.getDiscussions();
      await _refreshUnreadCount();
      await _refreshPendingCount();
    } catch (e) {
      _setError('Impossible de charger les discussions');
      debugPrint('Erreur dans loadDiscussions: $e');
    } finally {
      _setLoadingDiscussions(false);
    }
  }

  // Charge les messages d'une discussion spécifique
  Future<void> loadMessages(String discussionId) async {
    _setLoadingMessages(true);
    _clearError();

    try {
      // Charger les messages depuis le cache d'abord
      _messages = await _syncService.getMessages(discussionId);

      // Mettre à jour la discussion courante
      _currentDiscussion = _discussions.firstWhere(
        (d) => d.id == discussionId,
        orElse: () => Discussion.empty(),
      );

      if (_currentDiscussion == null) {
        await loadDiscussions();
        _currentDiscussion = _discussions.firstWhere(
          (d) => d.id == discussionId,
          orElse: () => Discussion.empty(),
        );
      }

      // Synchroniser avec le serveur en arrière-plan
      if (await _syncService.isOnline()) {
        final serverMessages =
            await _syncService.getMessagesFromServer(discussionId);
        if (serverMessages.isNotEmpty) {
          _messages = serverMessages;
        }
      }

      // Trier les messages par date de création (du plus ancien au plus récent)
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Rafraîchir les compteurs
      await _refreshUnreadCount();
      await _refreshPendingCount();

      notifyListeners();
    } catch (e) {
      _setError('Impossible de charger les messages');
      debugPrint('Erreur dans loadMessages: $e');
    } finally {
      _setLoadingMessages(false);
    }
  }

  // Crée une nouvelle discussion
  Future<Discussion?> createDiscussion(
      String participantId, String content) async {
    _setError(null);

    try {
      final Discussion? discussion = await _syncService.createDiscussion(
        participantId,
        content,
      );

      if (discussion != null) {
        // Si on a créé la discussion avec succès, la mettre en tête de liste
        _discussions = [
          discussion,
          ..._discussions.where((d) => d.id != discussion.id)
        ];
        notifyListeners();

        // Mettre à jour la discussion courante
        _currentDiscussion = discussion;

        // Si un message a été envoyé, mettre à jour la liste des messages
        if (content.isNotEmpty) {
          await loadMessages(discussion.id);
        }

        return discussion;
      }
    } catch (e) {
      _setError('Impossible de créer la discussion');
      debugPrint('Erreur dans createDiscussion: $e');
    }

    return null;
  }

  // Envoie un message texte
  Future<Message?> sendMessage(String discussionId, String content) async {
    if (content.isEmpty) return null;

    _setSendingMessage(true);
    _clearError();

    try {
      final message = await _syncService.sendMessage(discussionId, content);

      if (message != null) {
        // Ajouter le message à la liste et mettre à jour la discussion
        _addMessageLocally(message);

        // Rafraîchir les compteurs car on a peut-être ajouté un message en attente
        await _refreshPendingCount();
      }

      return message;
    } catch (e) {
      _setError('Impossible d\'envoyer le message');
      debugPrint('Erreur dans sendMessage: $e');
      return null;
    } finally {
      _setSendingMessage(false);
    }
  }

  // Envoie un message avec des pièces jointes
  Future<Message?> sendMessageWithAttachments(
      String discussionId, String content, List<File> files) async {
    if (files.isEmpty && content.isEmpty) return null;

    _setSendingMessage(true);
    _clearError();

    try {
      final message = await _syncService.sendMessageWithAttachments(
        discussionId,
        content,
        files,
      );

      if (message != null) {
        // Ajouter le message à la liste et mettre à jour la discussion
        _addMessageLocally(message);

        // Rafraîchir les compteurs car on a peut-être ajouté un message en attente
        await _refreshPendingCount();

        // Attendre un court instant pour s'assurer que l'état est mis à jour
        await Future.delayed(const Duration(milliseconds: 100));
      }

      return message;
    } catch (e) {
      _setError('Impossible d\'envoyer le message avec pièces jointes');
      debugPrint('Erreur dans sendMessageWithAttachments: $e');
      return null;
    } finally {
      _setSendingMessage(false);
    }
  }

  // Synchronise les messages en attente
  Future<void> syncPendingMessages() async {
    if (_isSyncing) return;

    _setSyncing(true);
    _clearError();

    try {
      await _syncService.syncPendingMessages();

      // Après synchronisation, recharger les données
      if (_currentDiscussion != null) {
        await loadMessages(_currentDiscussion!.id);
      }
      await loadDiscussions();
    } catch (e) {
      _setError('Erreur lors de la synchronisation');
      debugPrint('Erreur dans syncPendingMessages: $e');
    } finally {
      _setSyncing(false);
    }
  }

  // Recherche un utilisateur pour démarrer une conversation
  Future<List<User>> searchUsers(String query) async {
    if (query.length < 2) return [];

    _clearError();

    try {
      // Cette partie dépend de votre API, mais l'idée est de renvoyer une liste d'utilisateurs
      final response = await _syncService.searchUsers(query);
      return (response as List).map((data) => User.fromJson(data)).toList();
    } catch (e) {
      _setError('Erreur lors de la recherche d\'utilisateurs');
      debugPrint('Erreur dans searchUsers: $e');
      return [];
    }
  }

  // Supprime un message
  Future<bool> deleteMessage(String discussionId, String messageId) async {
    _clearError();

    try {
      final success = await _syncService.deleteMessage(discussionId, messageId);

      if (success) {
        // Mettre à jour la liste des messages localement
        _messages.removeWhere((m) => m.id == messageId);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _setError('Impossible de supprimer le message');
      debugPrint('Erreur dans deleteMessage: $e');
      return false;
    }
  }

  // Méthodes privées pour la gestion de l'état

  void _setLoadingDiscussions(bool loading) {
    _isLoadingDiscussions = loading;
    notifyListeners();
  }

  void _setLoadingMessages(bool loading) {
    _isLoadingMessages = loading;
    notifyListeners();
  }

  void _setSendingMessage(bool sending) {
    _isSendingMessage = sending;
    notifyListeners();
  }

  void _setSyncing(bool syncing) {
    _isSyncing = syncing;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  Future<void> _refreshUnreadCount() async {
    try {
      _unreadCount = await _syncService.getUnreadMessagesCount();
      notifyListeners();
    } catch (e) {
      debugPrint(
          'Erreur lors du rafraîchissement du compteur de messages non lus: $e');
    }
  }

  Future<void> _refreshPendingCount() async {
    try {
      _pendingMessagesCount = await _syncService.getPendingMessagesCount();
      notifyListeners();
    } catch (e) {
      debugPrint(
          'Erreur lors du rafraîchissement du compteur de messages en attente: $e');
    }
  }

  void _addMessageLocally(Message message) {
    // Ajouter le message à la fin de la liste des messages
    _messages = [..._messages, message];

    // Mettre à jour la discussion courante
    if (_currentDiscussion != null) {
      _currentDiscussion = _currentDiscussion!.copyWith(
        lastMessageAt: DateTime.now(),
        messages: [...(_currentDiscussion!.messages), message],
      );
    }

    // Mettre à jour la liste des discussions
    final discussionIndex =
        _discussions.indexWhere((d) => d.id == message.discussionId);
    if (discussionIndex >= 0) {
      final updatedDiscussion = _discussions[discussionIndex].copyWith(
        lastMessageAt: DateTime.now(),
        messages: [message],
      );

      _discussions.removeAt(discussionIndex);
      _discussions.insert(0, updatedDiscussion);
    }

    notifyListeners();
  }

  // Méthodes utilitaires publiques

  void setCurrentDiscussion(Discussion? discussion) {
    _currentDiscussion = discussion;
    notifyListeners();
  }

  // Vérifie si une discussion est nouvelle (seulement pour l'UI)
  bool isDiscussionNew(Discussion discussion) {
    return discussion.lastMessageAt
        .isAfter(DateTime.now().subtract(const Duration(days: 1)));
  }

  Future<void> loadMoreMessages(String discussionId, int page) async {
    _setLoadingMessages(true);
    _clearError();

    try {
      final newMessages =
          await _syncService.getMessages(discussionId, page: page);
      _messages = [..._messages, ...newMessages];
      notifyListeners();
    } catch (e) {
      _setError('Impossible de charger plus de messages');
      debugPrint('Erreur dans loadMoreMessages: $e');
    } finally {
      _setLoadingMessages(false);
    }
  }
}
