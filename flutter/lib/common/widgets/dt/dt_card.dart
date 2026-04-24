// DeskRu v2.0.7 visual refresh — card container.
// Spec: plans/2026-04-24-client-visual-refresh.md §4.5
//
// bg=surface, border=1px border, radius=14, padding=16.
// Inner row dividers: DtCardDivider (border-top 1px border).

import 'package:flutter/material.dart';

import '../../design_tokens.dart';

class DtCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const DtCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DtSpace.md),
    this.radius = DtRadius.xl,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.dtColors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.border, width: 1),
      ),
      child: child,
    );
  }
}

/// Horizontal 1px divider to separate rows inside a [DtCard].
class DtCardDivider extends StatelessWidget {
  const DtCardDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: context.dtColors.border);
  }
}
