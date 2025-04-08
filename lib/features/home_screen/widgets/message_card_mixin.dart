import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:diff_match_patch/diff_match_patch.dart';


mixin MessageCardMixin {
  String formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('yyyy/MM/dd h:mm:ss a');
    return dateFormat.format(dateTime);
  }

  List<InlineSpan> _buildTextWithEdits(String previous, String current) {
    if (previous.isEmpty) {
      return [
        TextSpan(
          text: current,
          style: const TextStyle(color: Colors.black),
        )
      ];
    }

    final dmp = DiffMatchPatch();
    final diffs = dmp.diff(previous, current);
    dmp.diffCleanupSemantic(diffs);

    final List<InlineSpan> spans = [];
    for (int i = 0; i < diffs.length; i++) {
      final diff = diffs[i];
      final text = diff.text;
      switch (diff.operation) {
        case DIFF_EQUAL:
          spans.add(TextSpan(text: text, style: const TextStyle(color: Colors.black)));
          break;
        case DIFF_INSERT:
          spans.add(
            TextSpan(
              text: text,
              style: TextStyle(
                backgroundColor: Colors.green.withOpacity(0.3),
                color: Colors.black,
              ),
            ),
          );
          break;
        case DIFF_DELETE:
          if (i + 1 < diffs.length && diffs[i + 1].operation == DIFF_INSERT) {
            final insertedText = diffs[i + 1].text;
            spans.add(
              TextSpan(
                text: insertedText,
                style: TextStyle(
                  backgroundColor: Colors.red.withOpacity(0.2),
                  color: Colors.black,
                ),
              ),
            );
            i++;
          }
          break;
      }
    }
    return spans;
  }

  List<Widget> buildMessageLines(String content, String previousContent, int index) {
    final lines = content.split('\n');
    final previousLines = previousContent.isNotEmpty ? previousContent.split('\n') : [];
    final List<Widget> lineWidgets = [];

    for (int i = 0; i < lines.length; i++) {
      final currentLine = lines[i];
      final previousLine = i < previousLines.length ? previousLines[i] : '';
      lineWidgets.add(
        RichText(
          text: TextSpan(
            children: index > 0 && previousLine.isNotEmpty
                ? _buildTextWithEdits(previousLine, currentLine)
                : [
                    TextSpan(
                      text: currentLine,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
          ),
        ),
      );
    }
    return lineWidgets;
  }
}