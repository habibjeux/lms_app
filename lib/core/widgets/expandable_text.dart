import 'package:flutter/material.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final TextAlign? textAlign;
  final String? expandText;
  final String? collapseText;
  final TextStyle? linkStyle;

  const ExpandableText(
    this.text, {
    super.key,
    this.maxLines = 3,
    this.style,
    this.textAlign,
    this.expandText = 'Voir plus',
    this.collapseText = 'Voir moins',
    this.linkStyle,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;
  bool _needsExpansion = false;

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.style ?? Theme.of(context).textTheme.bodyMedium;
    final linkTextStyle = widget.linkStyle ??
        TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w600,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(
          text: widget.text,
          style: textStyle,
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          maxLines: widget.maxLines,
        )..layout(maxWidth: constraints.maxWidth);

        _needsExpansion = textPainter.didExceedMaxLines;

        if (!_needsExpansion) {
          return Text(
            widget.text,
            style: textStyle,
            textAlign: widget.textAlign,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCrossFade(
              firstChild: _buildTruncatedText(textStyle),
              secondChild: _buildExpandedText(textStyle),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? widget.collapseText! : widget.expandText!,
                      style: linkTextStyle,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTruncatedText(TextStyle? textStyle) {
    return Text(
      widget.text,
      style: textStyle,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildExpandedText(TextStyle? textStyle) {
    return Text(
      widget.text,
      style: textStyle,
      textAlign: widget.textAlign,
    );
  }
}
