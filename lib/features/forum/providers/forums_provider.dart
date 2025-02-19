import 'package:flutter/foundation.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../data/forum_repository.dart';
import '../models/forum.dart';

class ForumProvider with ChangeNotifier {
  final ForumRepository _repository = ForumRepository();

  Forum? _forum;
  Topic? _currentTopic;
  bool _isLoading = false;
  bool _isLoadingTopic = false;
  String? _error;
  bool _isCreatingTopic = false;
  bool _isCreatingReply = false;

  // Getters
  Forum? get forum => _forum;
  Topic? get currentTopic => _currentTopic;
  bool get isLoading => _isLoading;
  bool get isLoadingTopic => _isLoadingTopic;
  String? get error => _error;
  bool get isCreatingTopic => _isCreatingTopic;
  bool get isCreatingReply => _isCreatingReply;

  // Chargement du forum d'un module
  Future<void> loadModuleForum(String moduleId) async {
    _setLoading(true);
    _clearError();

    try {
      _forum = await _repository.getModuleForum(moduleId);
      _clearError();
    } on AppException catch (e) {
      _setError(e.toString());
    } catch (e) {
      _setError('Une erreur est survenue lors du chargement du forum');
    } finally {
      _setLoading(false);
    }
  }

  // Chargement du forum d'un chapitre
  Future<void> loadChapterForum(String chapterId) async {
    _setLoading(true);
    _clearError();

    try {
      _forum = await _repository.getChapterForum(chapterId);
      _clearError();
    } on AppException catch (e) {
      _setError(e.toString());
    } catch (e) {
      _setError('Une erreur est survenue lors du chargement du forum');
    } finally {
      _setLoading(false);
    }
  }

  // Rafraîchissement du forum
  Future<void> refreshForum({String? moduleId, String? chapterId}) async {
    if (moduleId == null && chapterId == null) return;

    try {
      if (moduleId != null) {
        _forum = await _repository.getModuleForum(moduleId, forceRefresh: true);
      } else if (chapterId != null) {
        _forum =
            await _repository.getChapterForum(chapterId, forceRefresh: true);
      }
      _clearError();
      notifyListeners();
    } on AppException catch (e) {
      _setError(e.toString());
    }
  }

  // Création d'un nouveau sujet
  Future<void> createTopic({
    required String title,
    required String content,
  }) async {
    if (_forum == null) return;

    _setCreatingTopic(true);
    _clearError();

    try {
      final newTopic =
          await _repository.createTopic(_forum!.id, title, content);
      _forum = Forum(
        id: _forum!.id,
        title: _forum!.title,
        description: _forum!.description,
        moduleId: _forum!.moduleId,
        chapterId: _forum!.chapterId,
        schoolId: _forum!.schoolId,
        active: _forum!.active,
        createdAt: _forum!.createdAt,
        updatedAt: _forum!.updatedAt,
        topics: [newTopic, ..._forum!.topics],
      );
      _clearError();
      notifyListeners();
    } on AppException catch (e) {
      _setError(e.toString());
    } catch (e) {
      _setError('Une erreur est survenue lors de la création du sujet');
    } finally {
      _setCreatingTopic(false);
    }
  }

  // Chargement des détails d'un topic
  Future<void> loadTopicDetail(String topicId) async {
    _setLoadingTopic(true);
    _clearError();

    try {
      _currentTopic = await _repository.getTopicDetail(topicId);
      _clearError();
    } on AppException catch (e) {
      _setError(e.toString());
    } catch (e) {
      _setError('Une erreur est survenue lors du chargement du sujet');
    } finally {
      _setLoadingTopic(false);
    }
  }

  // Création d'une réponse
  Future<void> createReply({
    required String topicId,
    required String content,
    String? parentReplyId,
  }) async {
    _setCreatingReply(true);
    _clearError();

    try {
      final newReply = await _repository.createReply(
        topicId: topicId,
        content: content,
        parentReplyId: parentReplyId,
      );

      if (_currentTopic != null) {
        final updatedReplies = List<Reply>.from(_currentTopic!.replies ?? []);
        if (parentReplyId == null) {
          updatedReplies.insert(0, newReply);
        } else {
          // Trouver et mettre à jour la réponse parent
          final parentIndex =
              updatedReplies.indexWhere((r) => r.id == parentReplyId);
          if (parentIndex != -1) {
            final parent = updatedReplies[parentIndex];
            final childReplies = List<Reply>.from(parent.childReplies ?? []);
            childReplies.add(newReply);
            updatedReplies[parentIndex] = Reply(
              id: parent.id,
              content: parent.content,
              createdAt: parent.createdAt,
              author: parent.author,
              parentReplyId: parent.parentReplyId,
              childReplies: childReplies,
            );
          }
        }

        _currentTopic = Topic(
          id: _currentTopic!.id,
          title: _currentTopic!.title,
          content: _currentTopic!.content,
          pinned: _currentTopic!.pinned,
          createdAt: _currentTopic!.createdAt,
          author: _currentTopic!.author,
          replyCount: _currentTopic!.replyCount + 1,
          replies: updatedReplies,
        );
      }

      _clearError();
      notifyListeners();
    } on AppException catch (e) {
      _setError(e.toString());
    } catch (e) {
      _setError('Une erreur est survenue lors de la création de la réponse');
    } finally {
      _setCreatingReply(false);
    }
  }

  // Filtrage des topics
  List<Topic> getPinnedTopics() =>
      _forum?.topics.where((topic) => topic.pinned).toList() ?? [];

  List<Topic> getRegularTopics() =>
      _forum?.topics.where((topic) => !topic.pinned).toList() ?? [];

  List<Topic> getUnreadTopics() =>
      _forum?.topics.where((topic) => topic.replyCount == 0).toList() ?? [];

  // Recherche de topics
  List<Topic> searchTopics(String query) {
    if (query.isEmpty || _forum == null) return [];
    return _forum!.topics.where((topic) {
      return topic.title.toLowerCase().contains(query.toLowerCase()) ||
          topic.content.toLowerCase().contains(query.toLowerCase()) ||
          topic.author.fullName.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Méthodes privées pour la gestion de l'état
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setLoadingTopic(bool value) {
    _isLoadingTopic = value;
    notifyListeners();
  }

  void _setCreatingTopic(bool value) {
    _isCreatingTopic = value;
    notifyListeners();
  }

  void _setCreatingReply(bool value) {
    _isCreatingReply = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

// Continuation de lib/features/forum/providers/forum_provider.dart

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Réinitialiser l'état du provider
  void reset() {
    _forum = null;
    _currentTopic = null;
    _isLoading = false;
    _isLoadingTopic = false;
    _error = null;
    _isCreatingTopic = false;
    _isCreatingReply = false;
    notifyListeners();
  }

  // Nettoyer le topic courant
  void clearCurrentTopic() {
    _currentTopic = null;
    notifyListeners();
  }

  // Obtenir une réponse spécifique par son ID
  Reply? getReplyById(String replyId) {
    if (_currentTopic == null || _currentTopic!.replies == null) {
      return null;
    }

    // Rechercher dans les réponses principales
    Reply? findReply;

    // Fonction récursive pour chercher dans les réponses imbriquées
    Reply? searchInReplies(List<Reply> replies, String targetId) {
      for (var reply in replies) {
        if (reply.id == targetId) {
          return reply;
        }
        if (reply.childReplies != null) {
          final found = searchInReplies(reply.childReplies!, targetId);
          if (found != null) {
            return found;
          }
        }
      }
      return null;
    }

    findReply = searchInReplies(_currentTopic!.replies!, replyId);
    return findReply;
  }

  // Compter le nombre total de réponses (incluant les réponses imbriquées)
  int getTotalRepliesCount() {
    if (_currentTopic == null || _currentTopic!.replies == null) {
      return 0;
    }

    int count = _currentTopic!.replies!.length;

    // Fonction récursive pour compter les réponses imbriquées
    void countChildReplies(Reply reply) {
      if (reply.childReplies != null) {
        count += reply.childReplies!.length;
        for (var childReply in reply.childReplies!) {
          countChildReplies(childReply);
        }
      }
    }

    for (var reply in _currentTopic!.replies!) {
      countChildReplies(reply);
    }

    return count;
  }

  bool isCurrentTopic(String topicId) {
    return _currentTopic?.id == topicId;
  }
}
