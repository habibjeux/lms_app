import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _coursesKey = 'student_courses';
  static const String _downloadsKey = 'downloaded_resources';

  final _storage = SharedPreferences.getInstance();

  Future<void> saveToken(String token) async {
    final prefs = await _storage;
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await _storage;
    return prefs.getString(_tokenKey);
  }

  Future<void> deleteToken() async {
    final prefs = await _storage;
    await prefs.remove(_tokenKey);
  }

  Future<void> saveUser(Map<String, dynamic> userData) async {
    final prefs = await _storage;
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await _storage;
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  Future<void> deleteUser() async {
    final prefs = await _storage;
    await prefs.remove(_userKey);
  }

  Future<void> clearAll() async {
    final prefs = await _storage;
    await prefs.clear();
  }

  // Méthodes génériques pour sauvegarder/récupérer des données
  Future<void> saveData(String key, dynamic data) async {
    final prefs = await _storage;
    final jsonString = jsonEncode(data);
    await prefs.setString(key, jsonString);
  }

  Future<dynamic> getData(String key) async {
    final prefs = await _storage;
    final jsonString = prefs.getString(key);
    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return null;
  }

  Future<void> removeData(String key) async {
    final prefs = await _storage;
    await prefs.remove(key);
  }

  // Méthodes pour les cours
  Future<void> saveCourses(List<dynamic> courses) async {
    await saveData(_coursesKey, courses);
  }

  Future<List<dynamic>?> getCourses() async {
    return await getData(_coursesKey);
  }

  // Méthodes pour les ressources téléchargées
  Future<void> saveDownloadedResource(
      String resourceId, String localPath) async {
    final downloads = await getDownloadedResources() ?? {};
    downloads[resourceId] = localPath;
    await saveData(_downloadsKey, downloads);
  }

  Future<Map<String, dynamic>?> getDownloadedResources() async {
    return await getData(_downloadsKey);
  }

  Future<String?> getResourcePath(String resourceId) async {
    final downloads = await getDownloadedResources();
    return downloads?[resourceId];
  }

  Future<bool> isResourceDownloaded(String resourceId) async {
    final downloads = await getDownloadedResources();
    return downloads?.containsKey(resourceId) ?? false;
  }

  Future<void> removeDownloadedResource(String resourceId) async {
    final downloads = await getDownloadedResources() ?? {};
    downloads.remove(resourceId);
    await saveData(_downloadsKey, downloads);
  }

  Future<bool> hasKey(String key) async {
    final prefs = await _storage;
    return prefs.containsKey(key);
  }

  Future<int> getStorageSize() async {
    final prefs = await _storage;
    int totalSize = 0;
    prefs.getKeys().forEach((key) {
      final value = prefs.getString(key);
      if (value != null) {
        totalSize += value.length;
      }
    });
    return totalSize;
  }

  // Méthodes de gestion des dates
  Future<void> saveLastSync(String key, DateTime dateTime) async {
    final prefs = await _storage;
    await prefs.setString('${key}_last_sync', dateTime.toIso8601String());
  }

  Future<DateTime?> getLastSync(String key) async {
    final prefs = await _storage;
    final dateStr = prefs.getString('${key}_last_sync');
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }
}
