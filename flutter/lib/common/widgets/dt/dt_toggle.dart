// DeskRu v2.0.7 visual refresh — toggle switch.
// Spec: plans/2026-04-24-client-visual-refresh.md §4.2
//
// 36x20 track (radius 10), 16x16 thumb (white).
// OFF: bg=surface3 (light) / surface2 (dark).
// ON:  bg=accent.

import 'package:flutter/material.dart';

import '../../design_tokens.dart';

class DtToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const DtToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.dtColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = onChanged == null;

    final trackOff = isDark ? c.surface2 : c.surface3;
    final trackColor = value ? c.accent : trackOff;

    return Semantics(
      toggled: value,
      child: MouseRegion(
        cursor:
            disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: disabled ? null : () => onChanged!(!value),
          child: Opacity(
            opacity: disabled ? 0.45 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              width: 36,
              height: 20,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(DtRadius.md),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A000000),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
