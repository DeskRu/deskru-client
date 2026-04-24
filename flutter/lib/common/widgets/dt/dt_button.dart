// DeskRu v2.0.7 visual refresh — base button.
// Spec: plans/2026-04-24-client-visual-refresh.md §4.1
//
// Four variants, all radius 8, 13/500, padding 9×16, gap 6:
//   - primary:     bg=accent,       fg=#fff
//   - ghost:       bg=transparent,  fg=text,   border=borderStrong
//   - danger:      bg=danger,       fg=#fff
//   - dangerGhost: bg=transparent,  fg=danger, border=borderStrong

import 'package:flutter/material.dart';

import '../../design_tokens.dart';

enum DtButtonVariant { primary, ghost, danger, dangerGhost }

class DtButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final DtButtonVariant variant;

  const DtButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.variant = DtButtonVariant.primary,
  });

  const DtButton.primary({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
  }) : variant = DtButtonVariant.primary;

  const DtButton.ghost({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
  }) : variant = DtButtonVariant.ghost;

  const DtButton.danger({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
  }) : variant = DtButtonVariant.danger;

  const DtButton.dangerGhost({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
  }) : variant = DtButtonVariant.dangerGhost;

  @override
  Widget build(BuildContext context) {
    final c = context.dtColors;
    final disabled = onPressed == null;

    late final Color bg;
    late final Color fg;
    late final BorderSide side;
    late final Color hoverOverlay;
    late final Color pressedOverlay;

    switch (variant) {
      case DtButtonVariant.primary:
        bg = c.accent;
        fg = Colors.white;
        side = BorderSide.none;
        hoverOverlay = Colors.white.withOpacity(0.08);
        pressedOverlay = Colors.black.withOpacity(0.08);
        break;
      case DtButtonVariant.ghost:
        bg = Colors.transparent;
        fg = c.text;
        side = BorderSide(color: c.borderStrong);
        hoverOverlay = c.surface2;
        pressedOverlay = c.surface3;
        break;
      case DtButtonVariant.danger:
        bg = c.danger;
        fg = Colors.white;
        side = BorderSide.none;
        hoverOverlay = Colors.white.withOpacity(0.08);
        pressedOverlay = Colors.black.withOpacity(0.08);
        break;
      case DtButtonVariant.dangerGhost:
        bg = Colors.transparent;
        fg = c.danger;
        side = BorderSide(color: c.borderStrong);
        hoverOverlay = c.danger.withOpacity(0.08);
        pressedOverlay = c.danger.withOpacity(0.14);
        break;
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DtRadius.sm),
      side: side,
    );

    final labelStyle = TextStyle(
      fontFamily: DtFonts.ui,
      fontSize: 13,
      fontWeight: DtFonts.medium,
      color: fg,
      height: 1.0,
    );

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
          ],
          Text(label, style: labelStyle),
        ],
      ),
    );

    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: Material(
        color: bg,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          hoverColor: hoverOverlay,
          splashColor: pressedOverlay,
          highlightColor: pressedOverlay,
          child: content,
        ),
      ),
    );
  }
}
