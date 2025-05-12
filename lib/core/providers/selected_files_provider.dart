// selected_files_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';

class SelectedFilesProvider with ChangeNotifier {
  final List<File> _selectedFiles = [];

  List<File> get selectedFiles => List.unmodifiable(_selectedFiles);

  void addFiles(List<File> files) {
    _selectedFiles.addAll(files);
    notifyListeners();
  }

  void removeFileAt(int index) {
    _selectedFiles.removeAt(index);
    notifyListeners();
  }

  void clearFiles() {
    _selectedFiles.clear();
    notifyListeners();
  }

  bool get isEmpty => _selectedFiles.isEmpty;
}
