// DeskRu enrollment card — shows the "bound to organization" pill or a
// CTA button to connect this device to an organization. Polls the server
// every 30s; if the admin revoked the token / deleted the device, the
// plate clears itself. On network errors the plate stays — we never
// clear state on transient failures.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../common.dart';
import '../../models/platform_model.dart';

const _kPollInterval = Duration(seconds: 30);
const _kOrgIdKey = 'deskru-enrollment-org-id';
const _kOrgNameKey = 'deskru-enrollment-org-name';
const _kFallbackLabel = 'Корпоративное устройство';

class EnrollmentCard extends StatefulWidget {
  const EnrollmentCard({Key? key}) : super(key: key);

  @override
  State<EnrollmentCard> createState() => _EnrollmentCardState();
}

class _EnrollmentCardState extends State<EnrollmentCard> {
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

  // Poll the server and clear local enrollment if admin revoked/deleted us.
  // Do nothing on network errors — we keep the plate until explicit unenroll.
  void _poll() {
    if (!mounted) return;
    final current = bind.mainGetEnrollmentOrgName();
    if (current.isEmpty) {
      // Nothing to check against — we're not enrolled locally.
      return;
    }
    final raw = bind.mainCheckEnrollmentStatus();
    try {
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      final ok = parsed['ok'] == true;
      if (!ok) return; // transient error — keep plate
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

  void _showDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        bool submitting = false;
        String? error;
        String? success;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
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
                  if (mounted) setState(() {});
                  await Future.delayed(const Duration(milliseconds: 1200));
                  if (Navigator.of(dialogCtx).canPop()) {
                    Navigator.of(dialogCtx).pop();
                  }
                } else {
                  setDialogState(() {
                    error = (parsed['error'] ?? translate('Unknown error')).toString();
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
                        fontSize: 12,
                        color: Theme.of(ctx).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      enabled: !submitting,
                      decoration: InputDecoration(
                        hintText: translate('Invitation code'),
                        border: const OutlineInputBorder(),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      onSubmitted: (_) => submit(),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(error!,
                          style:
                              const TextStyle(color: Color(0xFFE57373), fontSize: 12)),
                    ],
                    if (success != null) ...[
                      const SizedBox(height: 10),
                      Text(success!,
                          style:
                              const TextStyle(color: Color(0xFF7FE08F), fontSize: 12)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      submitting ? null : () => Navigator.of(dialogCtx).pop(),
                  child: Text(translate('Cancel')),
                ),
                ElevatedButton(
                  onPressed: submitting ? null : submit,
                  child: Text(submitting
                      ? translate('Connecting...')
                      : translate('Connect')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgName = bind.mainGetEnrollmentOrgName();
    final isEnrolled = orgName.isNotEmpty;

    if (isEnrolled) {
      return _BoundPill(
        label: orgName.isEmpty ? _kFallbackLabel : orgName,
        onClear: _clearLocal,
      );
    }
    return _ConnectButton(onTap: _showDialog);
  }
}

// Green pill shown when device is bound to an org.
class _BoundPill extends StatelessWidget {
  const _BoundPill({required this.label, required this.onClear});
  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F4D2A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF41CE5C), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, size: 16, color: Color(0xFF7FE08F)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: onClear,
            child: const Padding(
              padding: EdgeInsets.all(2.0),
              child: Icon(Icons.close_rounded, size: 14, color: Color(0xFF7FE08F)),
            ),
          ),
        ],
      ),
    );
  }
}

// "Connect to organization" CTA with shield icon + hover.
class _ConnectButton extends StatefulWidget {
  const _ConnectButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<_ConnectButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.titleLarge?.color ?? Colors.white;
    final borderColor = _hover
        ? textColor.withOpacity(0.35)
        : Theme.of(context).colorScheme.background;
    final bg = _hover ? Colors.white.withOpacity(0.04) : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined,
                  size: 16, color: textColor.withOpacity(0.75)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  translate('Connect to organization'),
                  style: TextStyle(
                    color: textColor.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
