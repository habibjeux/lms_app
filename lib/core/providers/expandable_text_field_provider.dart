import 'package:flutter/material.dart';

class ExpandableTextFieldProvider with ChangeNotifier {
  final Map<String, int> _textFieldLinesMap = {};

  int getCurrentLines(String textFieldId, int minLines, int maxLines) {
    return _textFieldLinesMap[textFieldId] ?? minLines;
  }

  void updateLines(
      String textFieldId, String text, int minLines, int maxLines) {
    final newLines = '\n'.allMatches(text).length + 1;
    final clampedLines = newLines.clamp(minLines, maxLines);

    if (_textFieldLinesMap[textFieldId] != clampedLines) {
      _textFieldLinesMap[textFieldId] = clampedLines;
      notifyListeners();
    }
  }
}
