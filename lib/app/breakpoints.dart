import 'package:flutter/material.dart';

enum WindowSize { compact, medium, expanded }

abstract final class Breakpoints {
  static const medium = 600.0;
  static const expanded = 1024.0;
  static const supportingColumn = 1280.0;
  static const content = 680.0;
}

extension WindowSizeContext on BuildContext {
  WindowSize get windowSize {
    final width = MediaQuery.sizeOf(this).width;
    if (width < Breakpoints.medium) return WindowSize.compact;
    if (width < Breakpoints.expanded) return WindowSize.medium;
    return WindowSize.expanded;
  }

  bool get isCompact => windowSize == WindowSize.compact;
  bool get isExpanded => windowSize == WindowSize.expanded;
  bool get hasSupportingColumn => MediaQuery.sizeOf(this).width >= Breakpoints.supportingColumn;
}
