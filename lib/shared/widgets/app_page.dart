import 'package:flutter/material.dart';

import '../../app/breakpoints.dart';

/// Constrains content without changing viewport metrics or overlay sizing.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = Breakpoints.content});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    this.appBar,
    this.body,
    this.backgroundColor,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
    this.maxWidth = Breakpoints.content,
  });
  final PreferredSizeWidget? appBar;
  final Widget? body, floatingActionButton, bottomNavigationBar;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: appBar,
    backgroundColor: backgroundColor,
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    floatingActionButton: floatingActionButton,
    bottomNavigationBar: bottomNavigationBar == null
        ? null
        : ContentWidth(maxWidth: maxWidth, child: bottomNavigationBar!),
    body: body == null ? null : ContentWidth(maxWidth: context.isCompact ? double.infinity : maxWidth, child: body!),
  );
}
