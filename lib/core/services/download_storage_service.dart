import 'package:hive/hive.dart';

class DownloadStorageService {
  static const String downloadedChaptersBox = 'downloaded_chapters';
  static const String downloadedResourcesBox = 'downloaded_resources';

  Future<Box> _openBox(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  Future<void> markChapterAsDownloaded(String chapterId) async {
    final box = await _openBox(downloadedChaptersBox);
    await box.put(chapterId, true);
  }

  Future<void> markResourceAsDownloaded(String resourceId) async {
    final box = await _openBox(downloadedResourcesBox);
    await box.put(resourceId, true);
  }

  Future<bool> isChapterDownloaded(String chapterId) async {
    final box = await _openBox(downloadedChaptersBox);
    return box.get(chapterId) == true;
  }

  Future<bool> isResourceDownloaded(String resourceId) async {
    final box = await _openBox(downloadedResourcesBox);
    return box.get(resourceId) == true;
  }

  Future<void> clearDownloadData() async {
    final chaptersBox = await _openBox(downloadedChaptersBox);
    final resourcesBox = await _openBox(downloadedResourcesBox);
    await chaptersBox.clear();
    await resourcesBox.clear();
  }
}
