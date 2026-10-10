import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

/// Campo com o rótulo acima, como no protótipo.
///
/// O rótulo visível também vira o rótulo do campo para leitores de tela.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.obscure = false,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.prefixIcon,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscure;
  final int maxLines;

  /// Limite de caracteres (mostra o contador só em campos de várias linhas).
  final int? maxLength;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  bool get _isEmail => widget.keyboardType == TextInputType.emailAddress;

  @override
  Widget build(BuildContext context) {
    final multiline = !widget.obscure && widget.maxLines > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          ExcludeSemantics(
            child: Text(widget.label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
          const SizedBox(height: 6),
        ],
        Semantics(
          label: widget.label,
          child: TextFormField(
            controller: widget.controller,
            initialValue: widget.controller == null ? widget.initialValue : null,
            validator: widget.validator,
            onChanged: widget.onChanged,
            keyboardType: widget.keyboardType ?? (multiline ? TextInputType.multiline : null),
            obscureText: _hidden,
            autocorrect: !widget.obscure && !_isEmail,
            enableSuggestions: !widget.obscure && !_isEmail,
            maxLines: widget.obscure ? 1 : widget.maxLines,
            maxLength: widget.maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            inputFormatters: widget.inputFormatters,
            textInputAction: widget.textInputAction ?? (multiline ? TextInputAction.newline : null),
            textCapitalization: widget.textCapitalization,
            onFieldSubmitted: widget.onSubmitted,
            autofillHints: widget.readOnly ? null : widget.autofillHints,
            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon,
              // Contador só onde ajuda (textos longos); nos demais o limite é silencioso.
              counterText: multiline ? null : '',
              suffixIcon: widget.obscure
                  ? IconButton(
                      tooltip: _hidden ? 'Mostrar senha' : 'Ocultar senha',
                      icon: Icon(_hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                      color: AppColors.textMuted,
                      onPressed: () => setState(() => _hidden = !_hidden),
                    )
                  : widget.suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
