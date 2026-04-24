// DeskRu v2.0.7 visual refresh — design tokens.
// Direction B (Tailscale / CleanShot — light airy).
// Spec: plans/2026-04-24-client-visual-refresh.md
//
// Usage:
//   final c = context.dtColors;              // light or dark based on theme
//   color: c.accent,
//   padding: const EdgeInsets.all(DtSpace.md),
//   borderRadius: BorderRadius.circular(DtRadius.lg),

import 'package:flutter/material.dart';

/// Palette tokens. Two instances — [light] and [dark].
@immutable
class DtColors {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color text2;
  final Color text3;
  final Color accent;
  final Color accentWeak;
  final Color success;
  final Color danger;

  const DtColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.text2,
    required this.text3,
    required this.accent,
    required this.accentWeak,
    required this.success,
    required this.danger,
  });

  static const DtColors light = DtColors(
    bg: Color(0xFFFAFAF9),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF5F4F0),
    surface3: Color(0xFFEFEDE8),
    border: Color(0xFFE7E5E0),
    borderStrong: Color(0xFFDCD9D2),
    text: Color(0xFF111827),
    text2: Color(0xFF57534E),
    text3: Color(0xFFA1A1AA),
    accent: Color(0xFF2E6BE0),
    accentWeak: Color(0xFFE8EEFD),
    success: Color(0xFF16A34A),
    danger: Color(0xFFDC2626),
  );

  static const DtColors dark = DtColors(
    bg: Color(0xFF0F1115),
    surface: Color(0xFF15181F),
    surface2: Color(0xFF1A1D25),
    surface3: Color(0xFF1F2330),
    border: Color(0xFF23262F),
    borderStrong: Color(0xFF2D3139),
    text: Color(0xFFE6E8EE),
    text2: Color(0xFF8B93A7),
    text3: Color(0xFF5B6170),
    accent: Color(0xFF6D92FF),
    accentWeak: Color(0xFF1A2340),
    success: Color(0xFF22C55E),
    danger: Color(0xFFEF4444),
  );
}

/// Font family + weight tokens. UI: Inter, Mono: JetBrains Mono.
class DtFonts {
  const DtFonts._();

  static const String ui = 'Inter';
  static const String mono = 'JetBrainsMono';

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}

/// Text styles per role. `-0.01em` / `-0.02em` / `0.06em` translated to
/// absolute `letterSpacing` (px) at each size.
class DtText {
  const DtText._();

  /// Page title, 19/700, tight tracking.
  static const TextStyle pageTitle = TextStyle(
    fontFamily: DtFonts.ui,
    fontSize: 19,
    fontWeight: DtFonts.bold,
    letterSpacing: -0.38,
    height: 1.3,
  );

  /// Section heading inside cards / popovers, 14/600.
  static const TextStyle sectionHeading = TextStyle(
    fontFamily: DtFonts.ui,
    fontSize: 14,
    fontWeight: DtFonts.semiBold,
    letterSpacing: -0.14,
  );

  /// Default body copy, 13/400.
  static const TextStyle body = TextStyle(
    fontFamily: DtFonts.ui,
    fontSize: 13,
    fontWeight: DtFonts.regular,
  );

  /// Description / help text under a heading, 12/400.
  static const TextStyle description = TextStyle(
    fontFamily: DtFonts.ui,
    fontSize: 12,
    fontWeight: DtFonts.regular,
  );

  /// Uppercase label above a value (e.g. "ВАШ ID"), 11/500 + wide tracking.
  static const TextStyle label = TextStyle(
    fontFamily: DtFonts.ui,
    fontSize: 11,
    fontWeight: DtFonts.medium,
    letterSpacing: 0.66,
  );

  /// Small caption, 11/500.
  static const TextStyle caption = TextStyle(
    fontFamily: DtFonts.ui,
    fontSize: 11,
    fontWeight: DtFonts.medium,
  );

  /// Mono, large — used for the client ID on Home, 18/600.
  static const TextStyle monoId = TextStyle(
    fontFamily: DtFonts.mono,
    fontSize: 18,
    fontWeight: DtFonts.semiBold,
    letterSpacing: 0.36,
  );

  /// Mono, default — for passwords, paths, session IDs, 13/500.
  static const TextStyle mono = TextStyle(
    fontFamily: DtFonts.mono,
    fontSize: 13,
    fontWeight: DtFonts.medium,
    letterSpacing: 0.26,
  );
}

/// Corner radii.
class DtRadius {
  const DtRadius._();

  /// 6 — chips, small labels.
  static const double xs = 6;

  /// 8 — buttons, tabs, nav items, toggle thumb area.
  static const double sm = 8;

  /// 10 — inputs, selects, tray items.
  static const double md = 10;

  /// 12 — cards, modals (small).
  static const double lg = 12;

  /// 14 — cards, modals, window corners.
  static const double xl = 14;

  /// 100 — status indicators, permission pills.
  static const double pill = 100;
}

/// Spacing on a 4-pt grid.
class DtSpace {
  const DtSpace._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

/// Elevation-less B-direction shadows. Cards use [card] (border-only, no shadow).
class DtShadow {
  const DtShadow._();

  /// Cards — no shadow, border only. Empty list so callers can still pass it.
  static const List<BoxShadow> card = [];

  /// Modal dialogs.
  static const List<BoxShadow> modal = [
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 20), blurRadius: 60),
    BoxShadow(color: Color(0x26000000), offset: Offset(0, 4), blurRadius: 12),
  ];

  /// Tray / menu popovers.
  static const List<BoxShadow> tray = [
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 10), blurRadius: 30),
  ];

  /// Floating remote toolbar — on top of the user's screen, stronger.
  static const List<BoxShadow> floatingToolbar = [
    BoxShadow(color: Color(0x66000000), offset: Offset(0, 10), blurRadius: 30),
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 2), blurRadius: 6),
  ];
}

/// Pick [DtColors.light] or [DtColors.dark] based on the current [Theme]
/// brightness in [context].
extension DtContext on BuildContext {
  DtColors get dtColors =>
      Theme.of(this).brightness == Brightness.dark
          ? DtColors.dark
          : DtColors.light;
}
