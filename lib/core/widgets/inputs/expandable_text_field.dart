import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/expandable_text_field_provider.dart';

class ExpandableTextField extends StatelessWidget {
  final TextEditingController controller;
  final int minLines;
  final int maxLines;
  final InputDecoration? decoration;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;

  final String _textFieldId = UniqueKey().toString();

  ExpandableTextField({
    super.key,
    required this.controller,
    this.minLines = 1,
    this.maxLines = 5,
    this.decoration,
    this.onChanged,
    this.onSubmitted,
  }) {
    _setupControllerListener();
  }

  void _setupControllerListener() {
    controller.addListener(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        Provider.of<ExpandableTextFieldProvider>(context, listen: false);

    provider.updateLines(_textFieldId, controller.text, minLines, maxLines);

    return Consumer<ExpandableTextFieldProvider>(
      builder: (context, textFieldProvider, _) {
        final currentLines =
            textFieldProvider.getCurrentLines(_textFieldId, minLines, maxLines);

        return TextField(
          controller: controller,
          minLines: currentLines,
          maxLines: maxLines,
          decoration: decoration,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          onChanged: (text) {
            textFieldProvider.updateLines(
                _textFieldId, text, minLines, maxLines);
            if (onChanged != null) {
              onChanged!(text);
            }
          },
          onSubmitted: onSubmitted,
        );
      },
    );
  }
}
