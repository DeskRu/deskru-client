// DeskRu v2.0.7 visual refresh — radio row.
// Spec: plans/2026-04-24-client-visual-refresh.md §4.3
//
// Row-card: padding 10, radius 8, border 1px transparent.
// Checked: bg=accentWeak, border=accent@25%, accent dot.
// Hover:   bg=surface2.
// 14x14 dot with 1.5px border; checked shows inner accent fill.

import 'package:flutter/material.dart';

import '../../design_tokens.dart';

class DtRadio<T> extends StatefulWidget {
  final T value;
  final T groupValue;
  final ValueChanged<T>? onChanged;
  final String label;
  final String? description;
  final IconData? icon;

  const DtRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.label,
    this.description,
    this.icon,
  });

  @override
  State<DtRadio<T>> createState() => _DtRadioState<T>();
}

class _DtRadioState<T> extends State<DtRadio<T>> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dtColors;
    final checked = widget.value == widget.groupValue;
    final disabled = widget.onChanged == null;

    final Color bg;
    final Color borderColor;
    if (checked) {
      bg = c.accentWeak;
      borderColor = c.accent.withOpacity(0.25);
    } else if (_hover && !disabled) {
      bg = c.surface2;
      borderColor = Colors.transparent;
    } else {
      bg = Colors.transparent;
      borderColor = Colors.transparent;
    }

    return MouseRegion(
      cursor:
          disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled ? null : () => widget.onChanged!(widget.value),
        child: Opacity(
          opacity: disabled ? 0.45 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(DtRadius.sm),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                _Dot(checked: checked, colors: c),
                const SizedBox(width: 10),
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: c.text),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontFamily: DtFonts.ui,
                          fontSize: 13,
                          fontWeight: DtFonts.medium,
                          color: c.text,
                          height: 1.25,
                        ),
                      ),
                      if (widget.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.description!,
                          style: TextStyle(
                            fontFamily: DtFonts.ui,
                            fontSize: 12,
                            fontWeight: DtFonts.regular,
                            color: c.text2,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool checked;
  final DtColors colors;

  const _Dot({required this.checked, required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: checked ? colors.accent : colors.borderStrong,
            width: 1.5,
          ),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: checked ? 7 : 0,
            height: checked ? 7 : 0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accent,
            ),
          ),
        ),
      ),
    );
  }
}
