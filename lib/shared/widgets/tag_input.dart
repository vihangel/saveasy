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
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Saiu do campo com texto digitado: vira tag (antes o texto se perdia
    // se a pessoa não apertasse Enter).
    _focus.addListener(() {
      if (!_focus.hasFocus) _add(_controller.text);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _add(String value) {
    if (!mounted || value.trim().isEmpty) return;
    final tags = [
      ...widget.tags,
      for (final part in value.split(','))
        if (part.trim().isNotEmpty && !widget.tags.contains(part.trim())) part.trim().replaceFirst('#', ''),
    ];
    _controller.clear();
    if (tags.length != widget.tags.length) widget.onChanged(tags.take(10).toList());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text),
        ),
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
                width: 240,
                child: Semantics(
                  label: widget.label,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Digite e aperte Enter',
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      suffixIcon: _controller.text.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Adicionar tag',
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              onPressed: () => _add(_controller.text),
                            ),
                    ),
                    // Vírgula também separa: "animais, adoção".
                    onChanged: (v) => v.contains(',') ? _add(v) : setState(() {}),
                    onSubmitted: (v) {
                      _add(v);
                      _focus.requestFocus();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
