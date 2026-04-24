// DeskRu v2.0.7 visual refresh — status pill.
// Spec: plans/2026-04-24-client-visual-refresh.md §4.6
//
// padding 4x10, radius 100, font 11/500.
// Success: bg=success@12%, color=success.
// Danger:  bg=danger@12%,  color=danger.
// 6x6 colored dot before the label.

import 'package:flutter/material.dart';

import '../../design_tokens.dart';

enum DtStatusPillVariant { success, danger }

class DtStatusPill extends StatelessWidget {
  final String label;
  final DtStatusPillVariant variant;

  const DtStatusPill({
    super.key,
    required this.label,
    this.variant = DtStatusPillVariant.success,
  });

  const DtStatusPill.success({super.key, required this.label})
      : variant = DtStatusPillVariant.success;

  const DtStatusPill.danger({super.key, required this.label})
      : variant = DtStatusPillVariant.danger;

  @override
  Widget build(BuildContext context) {
    final c = context.dtColors;
    final base = switch (variant) {
      DtStatusPillVariant.success => c.success,
      DtStatusPillVariant.danger => c.danger,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: base.withOpacity(0.12),
        borderRadius: BorderRadius.circular(DtRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: base,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: DtFonts.ui,
              fontSize: 11,
              fontWeight: DtFonts.medium,
              color: base,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
