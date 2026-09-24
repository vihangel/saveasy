import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Campo de tags com chips removíveis (formulários de criação).
class TagInput extends StatefulWidget {
  const TagInput({super.key, required this.tags, required this.onChanged, this.label = 'Tag'});

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final String label;

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String value) {
    final tag = value.trim();
    if (tag.isEmpty || widget.tags.contains(tag)) return;
    widget.onChanged([...widget.tags, tag]);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
          child: Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final tag in widget.tags)
                InputChip(
                  label: Text(tag),
                  backgroundColor: Colors.white,
                  onDeleted: () => widget.onChanged(widget.tags.where((t) => t != tag).toList()),
                ),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Adicionar tag',
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  ),
                  onSubmitted: _add,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
