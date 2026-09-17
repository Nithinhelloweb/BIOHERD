import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:bioherd/core/theme/hallmark_tokens.dart';
import 'package:bioherd/core/widgets/bioherd_button.dart';

class TwoFactorDialog extends StatefulWidget {
  final String phoneNumber;
  final Function(String code) onVerify;
  final VoidCallback onCancel;

  const TwoFactorDialog({
    super.key,
    required this.phoneNumber,
    required this.onVerify,
    required this.onCancel,
  });

  @override
  State<TwoFactorDialog> createState() => _TwoFactorDialogState();
}

class _TwoFactorDialogState extends State<TwoFactorDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _hasError = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _codeController.text.trim();
    if (code.length == 6 && RegExp(r'^\d{6}$').hasMatch(code)) {
      widget.onVerify(code);
    } else {
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? HallmarkTokens.darkSurface : HallmarkTokens.surfaceCard;
    final textColor = isDark ? HallmarkTokens.darkTextPrimary : HallmarkTokens.textPrimary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HallmarkTokens.radiusLg)),
      backgroundColor: surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(HallmarkTokens.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(HallmarkTokens.spaceSm),
                  decoration: BoxDecoration(
                    color: HallmarkTokens.terracotta.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(HallmarkTokens.radiusMd),
                  ),
                  child: const Icon(
                    PhosphorIconsRegular.shieldCheck,
                    color: HallmarkTokens.terracotta,
                    size: 28,
                  ),
                ),
                const SizedBox(width: HallmarkTokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Two-Factor Verification',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '2-Step Security for +91 ${widget.phoneNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? HallmarkTokens.darkTextSecondary : HallmarkTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: HallmarkTokens.spaceLg),
            Text(
              'Enter the 6-digit TOTP verification code from your Authenticator app (e.g. Google Authenticator):',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? HallmarkTokens.darkTextSecondary : HallmarkTokens.textSecondary,
              ),
            ),
            const SizedBox(height: HallmarkTokens.spaceMd),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: '000000',
                counterText: '',
                filled: true,
                fillColor: isDark ? HallmarkTokens.darkBackground : HallmarkTokens.surfacePaper,
                errorText: _hasError ? 'Enter a valid 6-digit number' : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(HallmarkTokens.radiusMd),
                  borderSide: BorderSide(
                    color: _hasError ? HallmarkTokens.alertCritical : HallmarkTokens.forestMoss,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(HallmarkTokens.radiusMd),
                  borderSide: const BorderSide(
                    color: HallmarkTokens.forestMoss,
                    width: 2.0,
                  ),
                ),
              ),
              onChanged: (val) {
                if (_hasError) setState(() => _hasError = false);
                if (val.length == 6) {
                  _submit();
                }
              },
            ),
            const SizedBox(height: HallmarkTokens.spaceXl),
            Row(
              children: [
                Expanded(
                  child: BioHerdButton(
                    label: 'Cancel',
                    variant: BioHerdButtonVariant.secondary,
                    onPressed: widget.onCancel,
                  ),
                ),
                const SizedBox(width: HallmarkTokens.spaceMd),
                Expanded(
                  child: BioHerdButton(
                    label: 'Verify Code',
                    variant: BioHerdButtonVariant.primary,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
