// DeskRu enrollment widgets.
//
// - [EnrollmentPill]   — used in HomePage LeftPane. Renders a small
//   "bound to org" pill ONLY when the device is enrolled; renders
//   nothing otherwise. Polls the server every 30s and clears the
//   plate if the admin revoked the token / deleted the device. On
//   network errors the plate stays.
//
// - [EnrollmentSettingsBlock] — used in Settings → Account. Always
//   visible: shows current state and exposes the connect / disconnect
//   actions for the typical "IT admin sent me a code, where do I
//   enter it?" flow.
//
// We keep enrollment out of the LeftPane CTA area for non-enrolled
// users so that solo (non-corporate) users see a clean sidebar.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../common.dart';
import '../../common/design_tokens.dart';
import '../../common/widgets/dt/dt_button.dart';
import '../../models/platform_model.dart';

const _kPollInterval = Duration(seconds: 30);
const _kFallbackLabel = 'Корпоративное устройство';

// Open the "Connect to organization" dialog. Calls [onChanged] (if
// provided) after a successful enroll so the caller can refresh its
// own state.
void showEnrollmentDialog(BuildContext context, {VoidCallback? onChanged}) {
  final controller = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (dialogCtx) {
      bool submitting = false;
      String? error;
      String? success;

      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final c = ctx.dtColors;
          Future<void> submit() async {
            final token = controller.text.trim();
            if (token.isEmpty) {
              setDialogState(() => error = translate('Token is required'));
              return;
            }
            setDialogState(() {
              submitting = true;
              error = null;
              success = null;
            });
            final raw = bind.mainEnrollWithToken(token: token);
            try {
              final parsed = jsonDecode(raw) as Map<String, dynamic>;
              if (parsed['ok'] == true) {
                final org = (parsed['organization'] ?? '') as String;
                setDialogState(() {
                  success = org.isNotEmpty
                      ? '${translate("Connected to")}: $org'
                      : translate('Connected');
                  submitting = false;
                });
                onChanged?.call();
                await Future.delayed(const Duration(milliseconds: 1200));
                if (Navigator.of(dialogCtx).canPop()) {
                  Navigator.of(dialogCtx).pop();
                }
              } else {
                setDialogState(() {
                  error =
                      (parsed['error'] ?? translate('Unknown error')).toString();
                  submitting = false;
                });
              }
            } catch (_) {
              setDialogState(() {
                error = translate('Bad server response');
                submitting = false;
              });
            }
          }

          return AlertDialog(
            title: Text(translate('Connect to organization')),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translate(
                        'Paste the invitation code your administrator sent you. The device will be added to the organization automatically.'),
                    style: TextStyle(
                      fontFamily: DtFonts.ui,
                      fontSize: 12,
                      color: c.text2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    enabled: !submitting,
                    style: TextStyle(
                        fontFamily: DtFonts.mono, fontSize: 13, color: c.text),
                    decoration: InputDecoration(
                      hintText: translate('Invitation code'),
                      hintStyle:
                          TextStyle(fontFamily: DtFonts.ui, color: c.text3),
                      filled: true,
                      fillColor: c.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DtRadius.sm),
                        borderSide: BorderSide(color: c.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DtRadius.sm),
                        borderSide: BorderSide(color: c.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DtRadius.sm),
                        borderSide: BorderSide(color: c.accent, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => submit(),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!,
                        style: TextStyle(
                            color: c.danger,
                            fontFamily: DtFonts.ui,
                            fontSize: 12)),
                  ],
                  if (success != null) ...[
                    const SizedBox(height: 10),
                    Text(success!,
                        style: TextStyle(
                            color: c.success,
                            fontFamily: DtFonts.ui,
                            fontSize: 12)),
                  ],
                ],
              ),
            ),
            actions: [
              DtButton.ghost(
                label: translate('Cancel'),
                onPressed:
                    submitting ? null : () => Navigator.of(dialogCtx).pop(),
              ),
              DtButton.primary(
                label: submitting
                    ? translate('Connecting...')
                    : translate('Connect'),
                onPressed: submitting ? null : submit,
              ),
            ],
          );
        },
      );
    },
  );
}

// Pill shown in the HomePage LeftPane when the device is bound to an
// organization. When not bound, renders nothing (SizedBox.shrink).
// Polls the server every 30s and clears local state if the admin
// revoked / deleted us. On network errors the plate stays.
class EnrollmentPill extends StatefulWidget {
  const EnrollmentPill({Key? key}) : super(key: key);

  @override
  State<EnrollmentPill> createState() => _EnrollmentPillState();
}

class _EnrollmentPillState extends State<EnrollmentPill> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(_kPollInterval, (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _poll() {
    if (!mounted) return;
    final current = bind.mainGetEnrollmentOrgName();
    if (current.isEmpty) {
      // not enrolled — nothing to verify, force a rebuild in case
      // the user just enrolled via Settings (which doesn't notify us)
      if (mounted) setState(() {});
      return;
    }
    final raw = bind.mainCheckEnrollmentStatus();
    try {
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      final ok = parsed['ok'] == true;
      if (!ok) return; // transient — keep plate
      final enrolled = parsed['enrolled'] == true;
      if (!enrolled) {
        bind.mainClearEnrollment();
        if (mounted) setState(() {});
      }
    } catch (_) {
      // malformed body — keep plate
    }
  }

  void _clearLocal() {
    bind.mainClearEnrollment();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final orgName = bind.mainGetEnrollmentOrgName();
    if (orgName.isEmpty) return const SizedBox.shrink();
    return _BoundPill(
      label: orgName.isEmpty ? _kFallbackLabel : orgName,
      onClear: _clearLocal,
    );
  }
}

// Block shown in Settings → Account. Always visible. Renders one of:
//   - "Подключено к {org}" + Disconnect button   (enrolled)
//   - "Не подключено" + Connect button           (not enrolled)
class EnrollmentSettingsBlock extends StatefulWidget {
  const EnrollmentSettingsBlock({Key? key}) : super(key: key);

  @override
  State<EnrollmentSettingsBlock> createState() =>
      _EnrollmentSettingsBlockState();
}

class _EnrollmentSettingsBlockState extends State<EnrollmentSettingsBlock> {
  void _clearLocal() {
    bind.mainClearEnrollment();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dtColors;
    final orgName = bind.mainGetEnrollmentOrgName();
    final isEnrolled = orgName.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translate(
                'Connect this device to a corporate DeskRu account using the invitation code your IT administrator sent you.'),
            style: TextStyle(
                fontFamily: DtFonts.ui, fontSize: 12, color: c.text2),
          ),
          const SizedBox(height: 12),
          if (isEnrolled) ...[
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: c.accentWeak,
                borderRadius: BorderRadius.circular(DtRadius.sm),
                border:
                    Border.all(color: c.accent.withOpacity(0.45), width: 1),
              ),
              child: Row(
                children: [
                  Icon(PhosphorIconsFill.shieldCheck,
                      size: 14, color: c.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${translate('Connected to')}: $orgName',
                      style: TextStyle(
                        fontFamily: DtFonts.ui,
                        fontSize: 13,
                        fontWeight: DtFonts.medium,
                        color: c.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: DtButton.dangerGhost(
                label: translate('Disconnect from organization'),
                icon: PhosphorIcons.signOut(),
                onPressed: _clearLocal,
              ),
            ),
          ] else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: DtButton.ghost(
                label: translate('Connect by code'),
                icon: PhosphorIcons.shieldCheck(),
                onPressed: () => showEnrollmentDialog(
                  context,
                  onChanged: () {
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Small pill shown in LeftPane.
class _BoundPill extends StatelessWidget {
  const _BoundPill({required this.label, required this.onClear});
  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.dtColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: c.accentWeak,
        borderRadius: BorderRadius.circular(DtRadius.sm),
        border: Border.all(color: c.accent.withOpacity(0.45), width: 1),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsFill.shieldCheck, size: 14, color: c.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: DtFonts.ui,
                fontSize: 12,
                fontWeight: DtFonts.medium,
                color: c.text,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(4),
            child: Tooltip(
              message: translate('Disconnect from organization'),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(PhosphorIcons.x(), size: 12, color: c.text2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
