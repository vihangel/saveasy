import 'package:flutter/material.dart';

import '../../app/breakpoints.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import 'app_back_button.dart';

/// Web-only authentication composition. Native screens keep their own layout.
class WebAuthLayout extends StatelessWidget {
  const WebAuthLayout({
    super.key,
    required this.child,
    required this.title,
    required this.description,
    required this.showBack,
    this.onBack,
  });
  final Widget child;
  final String title, description;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFDDE0E9)),
    );
    final theme = base.copyWith(
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: Colors.white,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF43485A)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: border,
        border: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF7A8091)),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(iconSize: 20)),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final compact = context.isCompact;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 40, vertical: compact ? 24 : 48),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (box.maxHeight - (compact ? 48 : 96)).clamp(0, double.infinity),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: context.isExpanded ? 1000 : 480),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE7E9F0)),
                          boxShadow: const [BoxShadow(color: Color(0x080F1738), blurRadius: 40, offset: Offset(0, 12))],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(compact ? 24 : 40),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (context.isExpanded) ...[
                                const Expanded(child: _BrandPanel()),
                                const SizedBox(width: 64),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!context.isExpanded) ...[const _Brand(), const SizedBox(height: 32)],
                                    if (showBack) ...[
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton.icon(
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(64, 36),
                                          ),
                                          onPressed:
                                              onBack ?? () => AppBackButton.goBack(context, fallback: AppRoutes.login),
                                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                                          label: const Text('Voltar'),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 26,
                                        height: 1.2,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      description,
                                      style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF687084)),
                                    ),
                                    const SizedBox(height: 28),
                                    child,
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Image.asset('assets/images/logo.png', width: 36, height: 36),
      const SizedBox(width: 10),
      const Flexible(
        child: Text(
          'Save Easy',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
      ),
    ],
  );
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Brand(),
      const SizedBox(height: 56),
      const Text(
        'Pequenas ações.\nGrandes mudanças.',
        style: TextStyle(fontSize: 34, height: 1.2, fontWeight: FontWeight.w700, color: AppColors.textDark),
      ),
      const SizedBox(height: 20),
      const Text(
        'Conecte-se a quem faz o bem e descubra novas formas de ajudar a sua comunidade.',
        style: TextStyle(fontSize: 14, height: 1.8, color: Color(0xFF687084)),
      ),
      const SizedBox(height: 32),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFFF0F2FF), borderRadius: BorderRadius.circular(16)),
        child: const Column(
          children: [
            _Benefit(Icons.volunteer_activism_outlined, 'Apoie causas que importam'),
            SizedBox(height: 20),
            _Benefit(Icons.people_outline_rounded, 'Encontre sua comunidade'),
            SizedBox(height: 20),
            _Benefit(Icons.auto_awesome_outlined, 'Acompanhe o seu impacto'),
          ],
        ),
      ),
    ],
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 22, color: AppColors.primary),
      const SizedBox(width: 12),
      Expanded(
        child: Text(text, style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF43485A))),
      ),
    ],
  );
}
