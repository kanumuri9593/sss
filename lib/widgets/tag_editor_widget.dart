import 'package:flutter/material.dart';

/// Tag Editor Widget
///
/// Hybrid UI component for managing tags with:
/// - Chips display above (with delete buttons)
/// - Text field below for adding new tags
/// - Bidirectional sync between chips and text field
class TagEditorWidget extends StatefulWidget {
  /// Current list of tags
  final List<String> tags;

  /// Callback when tags change
  final ValueChanged<List<String>> onTagsChanged;

  /// Optional label for the text field
  final String? labelText;

  /// Optional hint text
  final String? hintText;

  /// Optional helper text
  final String? helperText;

  const TagEditorWidget({
    super.key,
    required this.tags,
    required this.onTagsChanged,
    this.labelText,
    this.hintText,
    this.helperText,
  });

  @override
  State<TagEditorWidget> createState() => _TagEditorWidgetState();
}

class _TagEditorWidgetState extends State<TagEditorWidget> {
  late List<String> _tags;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.tags);
    _updateTextController();
  }

  @override
  void didUpdateWidget(TagEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tags != oldWidget.tags) {
      _tags = List.from(widget.tags);
      _updateTextController();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updateTextController() {
    _textController.text = _tags.join(', ');
  }

  void _addTagsFromText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Parse comma-separated tags
    final newTags = text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    // Update tags list (remove duplicates, preserve order)
    final updatedTags = <String>[];
    for (final tag in newTags) {
      if (!updatedTags.any((t) => t.toLowerCase() == tag.toLowerCase())) {
        updatedTags.add(tag);
      }
    }

    // Also keep existing tags that weren't in the text
    for (final existingTag in _tags) {
      if (!updatedTags.any((t) => t.toLowerCase() == existingTag.toLowerCase())) {
        updatedTags.add(existingTag);
      }
    }

    setState(() {
      _tags = updatedTags;
    });
    _updateTextController();
    widget.onTagsChanged(_tags);
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    _updateTextController();
    widget.onTagsChanged(_tags);
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tags display (chips)
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeTag(tag),
                backgroundColor: theme.colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        // Text field for adding/editing tags
        TextField(
          controller: _textController,
          decoration: InputDecoration(
            labelText: widget.labelText ?? 'Tags',
            hintText: widget.hintText ?? 'Comma-separated tags (e.g., storage, organize, box)',
            helperText: widget.helperText,
            suffixIcon: _tags.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear all tags',
                    onPressed: () {
                      setState(() {
                        _tags.clear();
                      });
                      _textController.clear();
                      widget.onTagsChanged(_tags);
                    },
                  )
                : null,
          ),
          onChanged: (_) {
            // Update tags as user types (debounced via onEditingComplete)
          },
          onEditingComplete: _addTagsFromText,
          onSubmitted: (_) => _addTagsFromText(),
        ),
      ],
    );
  }
}

