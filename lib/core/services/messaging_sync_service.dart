import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

import '../../features/messaging/models/discussion.dart';
import '../../features/messaging/models/message.dart';
import '../network/api_client.dart';
import 'offline_storage_service.dart';

class MessagingSyncService {
  final OfflineStorageService _storage = OfflineStorageService();
  final Dio _api = ApiClient.instance;
  final Dio _uploadApi = ApiClient.uploadInstance;
  bool _isSyncing = false;

  // Constantes pour le stockage
  static const String discussionsBoxName = 'discussions';
  static const String messagesBoxName = 'messages';
  static const String pendingMessagesBoxName = 'pending_messages';
  static const String pendingAttachmentsBoxName = 'pending_attachments';
  static const String lastSyncBoxName = 'lastSync';

  bool get isSyncing => _isSyncing;

  // Vérifie si l'application est en ligne
  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Récupère toutes les discussions
  Future<List<Discussion>> getDiscussions() async {
    try {
      if (await isOnline()) {
        final response = await _api.get('/discussions');
        final List<Discussion> discussions = (response.data as List)
            .map((item) => Discussion.fromJson(item))
            .toList();

        // Sauvegarder dans le cache
        await _saveDiscussionsToCache(discussions);

        // Retourner les discussions fraîchement récupérées
        return discussions;
      }

      // Si hors ligne, utiliser les données en cache
      return await _getDiscussionsFromCache();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des discussions: $e');
      // En cas d'erreur, essayer de récupérer depuis le cache
      return await _getDiscussionsFromCache();
    }
  }

  // Récupère les messages d'une discussion spécifique
  Future<List<Message>> getMessages(String discussionId) async {
    try {
      if (await isOnline()) {
        final response = await _api.get('/discussions/$discussionId/messages');
        final List<Message> messages = (response.data as List)
            .map((item) => Message.fromJson(item))
            .toList();

        // Sauvegarder dans le cache
        await _saveMessagesToCache(discussionId, messages);

        // Marquer les messages comme lus
        await _api.patch('/discussions/$discussionId/read');

        // Fusionner avec les messages en attente
        final pendingMessages = await _getPendingMessages(discussionId);
        return [...messages, ...pendingMessages];
      }

      // Si hors ligne, utiliser les données en cache et les messages en attente
      final cachedMessages = await _getMessagesFromCache(discussionId);
      final pendingMessages = await _getPendingMessages(discussionId);
      return [...cachedMessages, ...pendingMessages];
    } catch (e) {
      debugPrint('Erreur lors de la récupération des messages: $e');
      // En cas d'erreur, essayer de récupérer depuis le cache et les messages en attente
      final cachedMessages = await _getMessagesFromCache(discussionId);
      final pendingMessages = await _getPendingMessages(discussionId);
      return [...cachedMessages, ...pendingMessages];
    }
  }

  // Crée une nouvelle discussion
  Future<Discussion?> createDiscussion(
      String participantId, String content) async {
    // Vérifie si on est en ligne pour décider si on crée immédiatement ou en mode hors ligne
    if (await isOnline()) {
      try {
        final response = await _api.post('/discussions', data: {
          'participantId': participantId,
          'content': content,
        });

        print(response.data);

        final discussion = Discussion.fromJson(response.data);

        // Sauvegarder dans le cache
        await _saveDiscussionToCache(discussion);

        return discussion;
      } catch (e) {
        debugPrint('Erreur lors de la création de la discussion: $e');
        return null;
      }
    } else {
      // Mode hors ligne: créer localement et mettre en file d'attente
      try {
        // Récupérer les infos du participant depuis le cache
        final Discussion localDiscussion =
            await _createLocalDiscussion(participantId);

        // Créer un message en attente
        if (content.isNotEmpty) {
          await _createPendingMessage(localDiscussion.id, content);
        }

        return localDiscussion;
      } catch (e) {
        debugPrint('Erreur lors de la création locale de la discussion: $e');
        return null;
      }
    }
  }

  // Envoie un message texte
  Future<Message?> sendMessage(String discussionId, String content) async {
    if (content.isEmpty) return null;

    // Vérifie si on est en ligne
    if (await isOnline()) {
      try {
        final response =
            await _api.post('/discussions/$discussionId/messages', data: {
          'content': content,
        });

        final message = Message.fromJson(response.data);

        // Sauvegarder dans le cache
        await _addMessageToCache(discussionId, message);

        return message;
      } catch (e) {
        debugPrint('Erreur lors de l\'envoi du message: $e');
        // Créer un message en attente en cas d'erreur
        return await _createPendingMessage(discussionId, content);
      }
    } else {
      // Mode hors ligne: créer message en attente
      return await _createPendingMessage(discussionId, content);
    }
  }

  // Envoie un message avec des pièces jointes
  Future<Message?> sendMessageWithAttachments(
      String discussionId, String content, List<File> files) async {
    if (files.isEmpty && content.isEmpty) return null;

    // Vérifie si on est en ligne pour l'envoi immédiat
    if (await isOnline()) {
      try {
        // Préparer les fichiers à envoyer
        final formData = FormData();
        formData.fields.add(MapEntry('content', content));

        for (var file in files) {
          final filename = path.basename(file.path);
          final mimeType =
              lookupMimeType(file.path) ?? 'application/octet-stream';

          formData.files.add(MapEntry(
            'files',
            await MultipartFile.fromFile(
              file.path,
              filename: filename,
              contentType: MediaType.parse(mimeType),
            ),
          ));
        }

        final response = await _uploadApi.post(
          '/discussions/$discussionId/messages/attachments',
          data: formData,
        );

        final message = Message.fromJson(response.data);

        // Sauvegarder dans le cache
        await _addMessageToCache(discussionId, message);

        return message;
      } catch (e) {
        debugPrint(
            'Erreur lors de l\'envoi du message avec pièces jointes: $e');
        // Créer un message en attente avec pièces jointes en cas d'erreur
        return await _createPendingMessageWithAttachments(
            discussionId, content, files);
      }
    } else {
      // Mode hors ligne: créer message en attente avec pièces jointes
      return await _createPendingMessageWithAttachments(
          discussionId, content, files);
    }
  }

  // Synchronise les messages en attente
  Future<void> syncPendingMessages() async {
    if (_isSyncing || !await isOnline()) return;

    _isSyncing = true;

    try {
      final pendingMessages = await _getAllPendingMessages();
      if (pendingMessages.isEmpty) {
        _isSyncing = false;
        return;
      }

      for (final message in pendingMessages) {
        try {
          final messageId = message.id;
          final discussionId = message.discussionId;
          final content = message.content;
          final attachments = message.attachments;
          final isLocalDiscussion = discussionId.startsWith('local_');

          // Si la discussion est locale, créer d'abord la discussion
          String actualDiscussionId = discussionId;
          if (isLocalDiscussion) {
            final discussion = await _getDiscussionFromCache(discussionId);
            if (discussion == null) {
              await _removePendingMessage(messageId);
              continue;
            }

            final participantId =
                discussion.getOtherParticipantId(message.senderId);
            final response = await _api.post('/discussions', data: {
              'participantId': participantId,
              'content': '',
            });

            actualDiscussionId = response.data['id'];

            // Mettre à jour les références de la discussion locale
            await _updateLocalDiscussionId(discussionId, actualDiscussionId);
          }

          // Envoyer le message (avec ou sans pièces jointes)
          if (attachments.isEmpty) {
            await _api.post('/discussions/$actualDiscussionId/messages', data: {
              'content': content,
            });
            await _removePendingMessage(messageId);
          } else {
            // Préparer les fichiers à envoyer
            final formData = FormData();
            formData.fields.add(MapEntry('content', content));

            for (var attachment in attachments) {
              if (attachment.localPath == null) continue;

              final file = File(attachment.localPath!);
              if (!await file.exists()) continue;

              formData.files.add(MapEntry(
                'files',
                await MultipartFile.fromFile(
                  file.path,
                  filename: attachment.filename,
                  contentType: MediaType.parse(attachment.mimeType),
                ),
              ));
            }

            await _uploadApi.post(
              '/discussions/$actualDiscussionId/messages/attachments',
              data: formData,
            );
            await _removePendingMessage(messageId);
          }
        } catch (e) {
          debugPrint(
              'Erreur lors de la synchronisation du message ${message.id}: $e');
          // En cas d'erreur, on continue avec le message suivant
          continue;
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  // Méthodes privées pour la gestion du cache

  Future<void> _saveDiscussionsToCache(List<Discussion> discussions) async {
    final box = await _openBox(discussionsBoxName);
    await box.put('all_discussions',
        jsonEncode(discussions.map((d) => d.toJson()).toList()));
    await _updateLastSync('discussions');
  }

  Future<void> _saveDiscussionToCache(Discussion discussion) async {
    final box = await _openBox(discussionsBoxName);
    await box.put(discussion.id, jsonEncode(discussion.toJson()));

    // Mettre à jour aussi la liste complète
    final allDiscussions = await _getDiscussionsFromCache();
    final existingIndex =
        allDiscussions.indexWhere((d) => d.id == discussion.id);

    if (existingIndex >= 0) {
      allDiscussions[existingIndex] = discussion;
    } else {
      allDiscussions.add(discussion);
    }

    await _saveDiscussionsToCache(allDiscussions);
  }

  Future<List<Discussion>> _getDiscussionsFromCache() async {
    try {
      final box = await _openBox(discussionsBoxName);
      final data = box.get('all_discussions');

      if (data != null) {
        final decoded = jsonDecode(data) as List;
        return decoded.map((item) => Discussion.fromJson(item)).toList();
      }

      // Essayer de reconstruire depuis les discussions individuelles
      final discussions = <Discussion>[];
      for (final key in box.keys) {
        if (key != 'all_discussions') {
          final discussionData = box.get(key);
          if (discussionData != null) {
            discussions.add(Discussion.fromJson(jsonDecode(discussionData)));
          }
        }
      }

      return discussions;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des discussions du cache: $e');
      return [];
    }
  }

  Future<Discussion?> _getDiscussionFromCache(String discussionId) async {
    try {
      final box = await _openBox(discussionsBoxName);
      final data = box.get(discussionId);

      if (data != null) {
        return Discussion.fromJson(jsonDecode(data));
      }

      return null;
    } catch (e) {
      debugPrint(
          'Erreur lors de la récupération de la discussion du cache: $e');
      return null;
    }
  }

  Future<void> _saveMessagesToCache(
      String discussionId, List<Message> messages) async {
    final box = await _openBox(messagesBoxName);
    await box.put(
        discussionId, jsonEncode(messages.map((m) => m.toJson()).toList()));
    await _updateLastSync('messages_$discussionId');
  }

  Future<void> _addMessageToCache(String discussionId, Message message) async {
    final box = await _openBox(messagesBoxName);
    final existingData = box.get(discussionId);

    if (existingData != null) {
      final messages = (jsonDecode(existingData) as List)
          .map((item) => Message.fromJson(item))
          .toList();

      // Vérifier si le message existe déjà
      final existingIndex = messages.indexWhere((m) => m.id == message.id);
      if (existingIndex >= 0) {
        messages[existingIndex] = message;
      } else {
        messages.add(message);
      }

      await box.put(
          discussionId, jsonEncode(messages.map((m) => m.toJson()).toList()));
    } else {
      await box.put(discussionId, jsonEncode([message.toJson()]));
    }

    await _updateLastSync('messages_$discussionId');
  }

  Future<List<Message>> _getMessagesFromCache(String discussionId) async {
    try {
      final box = await _openBox(messagesBoxName);
      final data = box.get(discussionId);

      if (data != null) {
        final decoded = jsonDecode(data) as List;
        return decoded.map((item) => Message.fromJson(item)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Erreur lors de la récupération des messages du cache: $e');
      return [];
    }
  }

  Future<Message> _createPendingMessage(
      String discussionId, String content) async {
    final box = await _openBox(pendingMessagesBoxName);

    // Récupérer l'ID utilisateur depuis le stockage
    final userBox = await Hive.openBox('user');
    final userData = userBox.get('currentUser');
    final userId = userData?['id'] ?? 'unknown';

    // Récupérer les infos de la discussion pour avoir l'ID du destinataire
    final discussion = await _getDiscussionFromCache(discussionId);
    final receiverId = discussion?.getOtherParticipantId(userId) ?? 'unknown';

    final localId = const Uuid().v4();
    final message = Message.pending(
      content: content,
      senderId: userId,
      receiverId: receiverId,
      discussionId: discussionId,
      localId: localId,
    );

    await box.put(message.id, jsonEncode(message.toJson()));

    // Mettre à jour la discussion si elle existe
    if (discussion != null) {
      final updatedDiscussion = discussion.copyWith(
        lastMessageAt: DateTime.now(),
        messages: [message, ...discussion.messages],
      );
      await _saveDiscussionToCache(updatedDiscussion);
    }

    return message;
  }

  Future<Message> _createPendingMessageWithAttachments(
      String discussionId, String content, List<File> files) async {
    // D'abord, sauvegarder les fichiers localement
    final attachments = <MessageAttachment>[];

    for (final file in files) {
      final filename = path.basename(file.path);
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final fileSize = await file.length();

      // Copier le fichier dans un dossier temporaire
      final tempDir = await getTemporaryDirectory();
      final attachmentsDir = Directory('${tempDir.path}/message_attachments');
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      final localFilePath =
          '${attachmentsDir.path}/${const Uuid().v4()}_$filename';
      await file.copy(localFilePath);

      final attachment = MessageAttachment.fromLocalFile(
        localPath: localFilePath,
        filename: filename,
        fileSize: fileSize,
        mimeType: mimeType,
      );

      attachments.add(attachment);
    }

    // Créer le message en attente avec les pièces jointes
    final box = await _openBox(pendingMessagesBoxName);

    // Récupérer l'ID utilisateur depuis le stockage
    final userBox = await Hive.openBox('user');
    final userData = userBox.get('currentUser');
    final userId = userData?['id'] ?? 'unknown';

    // Récupérer les infos de la discussion pour avoir l'ID du destinataire
    final discussion = await _getDiscussionFromCache(discussionId);
    final receiverId = discussion?.getOtherParticipantId(userId) ?? 'unknown';

    final localId = const Uuid().v4();
    final message = Message.pending(
      content: content,
      senderId: userId,
      receiverId: receiverId,
      discussionId: discussionId,
      attachments: attachments,
      localId: localId,
    );

    await box.put(message.id, jsonEncode(message.toJson()));

    // Mettre à jour la discussion si elle existe
    if (discussion != null) {
      final updatedDiscussion = discussion.copyWith(
        lastMessageAt: DateTime.now(),
        messages: [message, ...discussion.messages],
      );
      await _saveDiscussionToCache(updatedDiscussion);
    }

    return message;
  }

  Future<List<Message>> _getPendingMessages(String discussionId) async {
    try {
      final box = await _openBox(pendingMessagesBoxName);
      final result = <Message>[];

      for (final key in box.keys) {
        final messageData = box.get(key);
        if (messageData != null) {
          final message = Message.fromJson(jsonDecode(messageData));
          if (message.discussionId == discussionId) {
            result.add(message);
          }
        }
      }

      return result;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des messages en attente: $e');
      return [];
    }
  }

  Future<List<Message>> _getAllPendingMessages() async {
    try {
      final box = await _openBox(pendingMessagesBoxName);
      final result = <Message>[];

      for (final key in box.keys) {
        final messageData = box.get(key);
        if (messageData != null) {
          result.add(Message.fromJson(jsonDecode(messageData)));
        }
      }

      return result;
    } catch (e) {
      debugPrint(
          'Erreur lors de la récupération de tous les messages en attente: $e');
      return [];
    }
  }

  Future<void> _removePendingMessage(String messageId) async {
    final box = await _openBox(pendingMessagesBoxName);
    await box.delete(messageId);
  }

  Future<Discussion> _createLocalDiscussion(String participantId) async {
    // Récupérer l'ID utilisateur depuis le stockage
    final userBox = await Hive.openBox('user');
    final userData = userBox.get('currentUser');

    if (userData == null) {
      throw Exception('Utilisateur non connecté');
    }

    final userId = userData['id'];

    // Récupérer les infos du participant
    // (en pratique, on devrait avoir ces informations en cache)
    // Pour simplifier, on va créer un objet basique
    final participantInfo = {
      'id': participantId,
      'firstName': 'Professeur',
      'lastName': 'Inconnu',
      'role': 'TEACHER',
    };

    // Créer une discussion locale
    final discussion = Discussion.local(
      participantOneId: userId,
      participantTwoId: participantId,
      participantOne: userData,
      participantTwo: participantInfo,
    );

    // Sauvegarder dans le cache
    await _saveDiscussionToCache(discussion);

    return discussion;
  }

  Future<void> _updateLocalDiscussionId(String localId, String serverId) async {
    final box = await _openBox(discussionsBoxName);
    final data = box.get(localId);

    if (data != null) {
      final discussion = Discussion.fromJson(jsonDecode(data));
      final updatedDiscussion = discussion.copyWith(
        id: serverId,
        isLocal: false,
      );

      await box.delete(localId);
      await _saveDiscussionToCache(updatedDiscussion);

      // Mettre à jour les ID des messages en attente
      final pendingBox = await _openBox(pendingMessagesBoxName);
      for (final key in pendingBox.keys) {
        final messageData = pendingBox.get(key);
        if (messageData != null) {
          final message = Message.fromJson(jsonDecode(messageData));
          if (message.discussionId == localId) {
            final updatedMessage = message.copyWith(
              discussionId: serverId,
            );
            await pendingBox.put(key, jsonEncode(updatedMessage.toJson()));
          }
        }
      }
    }
  }

  Future<Box> _openBox(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  Future<void> _updateLastSync(String key) async {
    final box = await _openBox(lastSyncBoxName);
    await box.put(key, DateTime.now().toIso8601String());
  }

  Future<DateTime?> getLastSync(String key) async {
    final box = await _openBox(lastSyncBoxName);
    final dateStr = box.get(key);
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }

  Future<bool> isDataStale(String key,
      {Duration threshold = const Duration(hours: 1)}) async {
    final lastSync = await getLastSync(key);
    if (lastSync == null) return true;

    final now = DateTime.now();
    return now.difference(lastSync) > threshold;
  }

  // Recherche des utilisateurs (enseignants ou étudiants)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      if (await isOnline()) {
        final response =
            await _api.get('/discussions/search', queryParameters: {
          'q': query,
        });

        return List<Map<String, dynamic>>.from(response.data);
      }

      // Si hors ligne, essayer de chercher dans les utilisateurs en cache
      // Cette partie est optionnelle et dépend de si vous stockez un cache d'utilisateurs
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la recherche d\'utilisateurs: $e');
      return [];
    }
  }

  // Méthodes utilitaires
  Future<int> getPendingMessagesCount() async {
    try {
      final box = await _openBox(pendingMessagesBoxName);
      return box.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getUnreadMessagesCount() async {
    try {
      if (await isOnline()) {
        final response = await _api.get('/discussions/unread-count');
        return response.data['count'] ?? 0;
      }

      // Essayer de calculer depuis le cache
      final discussions = await _getDiscussionsFromCache();
      var total = 0;
      for (final discussion in discussions) {
        total += discussion.unreadCount;
      }
      return total;
    } catch (e) {
      debugPrint('Erreur lors du calcul des messages non lus: $e');
      return 0;
    }
  }
}
