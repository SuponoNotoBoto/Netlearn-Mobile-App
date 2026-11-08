/// Parsing for the plain-text body stored in `materials.content`.
///
/// The bodies are plain text rather than HTML or Markdown, but they use three
/// shapes that cannot be rendered as a single run of paragraphs:
///
///   * A ``` fenced run has to keep its monospacing and must not be soft
///     wrapped. That is what the ASCII topology sketch and the aligned
///     IPv4 / subnet / gateway tables rely on to stay legible; in a
///     proportional font the box-drawing characters and the aligned colons
///     come out misaligned.
///   * Lines starting with "- " are list items.
///   * A block consisting of a single line such as "1. Pengertian ..." is a
///     section heading.
///
/// Everything else is an ordinary paragraph, separated by the blank lines in
/// the stored body.
library;

enum MaterialBlockKind { paragraph, heading, bullets, preformatted }

class MaterialBlock {
  final MaterialBlockKind kind;
  final List<String> lines;

  const MaterialBlock(this.kind, this.lines);
}

final RegExp _sectionHeading = RegExp(r'^\d+\.\s+\S');

List<MaterialBlock> parseMaterialBody(String text) {
  final blocks = <MaterialBlock>[];
  final paragraph = <String>[];

  void flushParagraph() {
    if (paragraph.isEmpty) {
      return;
    }

    blocks.add(
      MaterialBlock(MaterialBlockKind.paragraph, List<String>.from(paragraph)),
    );
    paragraph.clear();
  }

  final rawLines = text.split('\n');

  for (var i = 0; i < rawLines.length; i++) {
    final line = rawLines[i];
    final trimmed = line.trim();

    if (trimmed == '```') {
      flushParagraph();

      final preformatted = <String>[];

      while (i + 1 < rawLines.length && rawLines[i + 1].trim() != '```') {
        i++;
        preformatted.add(rawLines[i]);
      }

      // Skip the closing fence when there is one.
      if (i + 1 < rawLines.length) {
        i++;
      }

      while (preformatted.isNotEmpty && preformatted.first.trim().isEmpty) {
        preformatted.removeAt(0);
      }

      while (preformatted.isNotEmpty && preformatted.last.trim().isEmpty) {
        preformatted.removeLast();
      }

      if (preformatted.isNotEmpty) {
        blocks.add(
          MaterialBlock(MaterialBlockKind.preformatted, preformatted),
        );
      }

      continue;
    }

    if (trimmed.isEmpty) {
      flushParagraph();

      continue;
    }

    if (trimmed.startsWith('- ') && trimmed.length > 2) {
      flushParagraph();

      final items = <String>[trimmed.substring(2).trim()];

      // Absorb the rest of a run of consecutive bullet lines.
      while (i + 1 < rawLines.length) {
        final next = rawLines[i + 1].trim();

        if (!next.startsWith('- ') || next.length <= 2) {
          break;
        }

        i++;
        items.add(next.substring(2).trim());
      }

      blocks.add(MaterialBlock(MaterialBlockKind.bullets, items));

      continue;
    }

    if (_sectionHeading.hasMatch(trimmed)) {
      flushParagraph();

      blocks.add(MaterialBlock(MaterialBlockKind.heading, [trimmed]));

      continue;
    }

    paragraph.add(line);
  }

  flushParagraph();

  return blocks;
}
