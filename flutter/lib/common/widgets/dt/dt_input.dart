// DeskRu v2.0.7 visual refresh — text input.
// Spec: plans/2026-04-24-client-visual-refresh.md §4.4
//
// Padding 10x12, radius 10, border 1.5px borderStrong.
// Focus: border-color=accent.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_tokens.dart';

class DtInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final bool mono;
  final IconData? leadingIcon;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final FocusNode? focusNode;

  const DtInput({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.mono = false,
    this.leadingIcon,
    this.trailing,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.focusNode,
  });

  @override
  State<DtInput> createState() => _DtInputState();
}

class _DtInputState extends State<DtInput> {
  late final FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focused != _focus.hasFocus) {
      setState(() => _focused = _focus.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dtColors;
    final borderColor = _focused ? c.accent : c.borderStrong;

    final textStyle = TextStyle(
      fontFamily: widget.mono ? DtFonts.mono : DtFonts.ui,
      fontSize: 13,
      fontWeight: DtFonts.regular,
      color: c.text,
      height: 1.3,
    );

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.45,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(DtRadius.md),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            if (widget.leadingIcon != null) ...[
              Icon(widget.leadingIcon, size: 16, color: c.text2),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
                maxLines: widget.maxLines,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                style: textStyle,
                cursorColor: c.accent,
                cursorWidth: 1.5,
                decoration: InputDecoration(
                  isDense: true,
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: widget.hintText,
                  hintStyle: textStyle.copyWith(color: c.text3),
                ),
              ),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 8),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
