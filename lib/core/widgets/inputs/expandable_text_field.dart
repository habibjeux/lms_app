import 'package:flutter/material.dart';

class ExpandableTextField extends StatefulWidget {
  final TextEditingController controller;
  final int minLines;
  final int maxLines;
  final InputDecoration? decoration;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;

  const ExpandableTextField({
    super.key,
    required this.controller,
    this.minLines = 1,
    this.maxLines = 5,
    this.decoration,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<ExpandableTextField> createState() => _ExpandableTextFieldState();
}

class _ExpandableTextFieldState extends State<ExpandableTextField> {
  late int _currentLines;

  @override
  void initState() {
    super.initState();
    _currentLines = widget.minLines;

    // Écouter les changements dans le controller pour ajuster la hauteur
    widget.controller.addListener(_updateLines);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateLines);
    super.dispose();
  }

  void _updateLines() {
    final newLines = '\n'.allMatches(widget.controller.text).length + 1;

    if (newLines != _currentLines) {
      setState(() {
        _currentLines = newLines.clamp(widget.minLines, widget.maxLines);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      minLines: _currentLines,
      maxLines: widget.maxLines,
      decoration: widget.decoration,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      onChanged: (text) {
        _updateLines();
        widget.onChanged?.call(text);
      },
      onSubmitted: widget.onSubmitted,
    );
  }
}
