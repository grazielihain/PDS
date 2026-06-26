import 'package:flutter/material.dart';

/// Template de página scrollável com largura máxima centrada e padding padrão.
/// Usado nas páginas autenticadas do aluno (quiz_selection, fazer_quiz, etc).
class ScrollablePageTemplate extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;
  final Color backgroundColor;
  final bool allowRefresh;
  final Future<void> Function()? onRefresh;

  const ScrollablePageTemplate({
    super.key,
    required this.child,
    this.maxWidth = 900,
    this.padding = const EdgeInsets.all(24),
    this.backgroundColor = const Color(0xFFF9FAFB),
    this.allowRefresh = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      physics: allowRefresh
          ? const AlwaysScrollableScrollPhysics()
          : const ClampingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: allowRefresh && onRefresh != null
          ? RefreshIndicator(onRefresh: onRefresh!, child: content)
          : content,
    );
  }
}
