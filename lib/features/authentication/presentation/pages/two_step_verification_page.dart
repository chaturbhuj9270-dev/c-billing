import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../common_widgets/app_top_bar.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/two_step_verification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/glassy_toast.dart';

// Flyout destination: enable/disable email OTP at login.
class TwoStepVerificationPage extends StatefulWidget {
  final bool isEmbedded;

  const TwoStepVerificationPage({super.key, this.isEmbedded = false});

  @override
  State<TwoStepVerificationPage> createState() =>
      _TwoStepVerificationPageState();
}

class _TwoStepVerificationPageState extends State<TwoStepVerificationPage> {
  late AppLocalizations _localizations;
  final _otpController = TextEditingController();
  final _service = TwoStepVerificationService.instance;

  bool _loading = true;
  bool _enabled = false;
  bool _awaitingCode = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
    _load();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final enabled = await _service.isEnabledForCurrentUser();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _loading = false;
      _awaitingCode = false;
    });
  }

  Future<void> _onToggle(bool value) async {
    if (_busy) return;
    if (value) {
      setState(() => _busy = true);
      try {
        final email = await _service.sendLoginOtp(force: true);
        if (!mounted) return;
        setState(() {
          _awaitingCode = true;
          _busy = false;
        });
        GlassyToast.show(
          context,
          '${_localizations.verificationEmailSent}: $email',
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _busy = false);
        GlassyToast.show(
          context,
          _service.messageFromFunctionsError(e),
          isError: true,
        );
      }
      return;
    }

    setState(() => _busy = true);
    try {
      await _service.setEnabled(enabled: false);
      if (!mounted) return;
      setState(() {
        _enabled = false;
        _awaitingCode = false;
        _busy = false;
        _otpController.clear();
      });
      GlassyToast.show(context, _localizations.twoStepDisabled);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      GlassyToast.show(
        context,
        _service.messageFromFunctionsError(e),
        isError: true,
      );
    }
  }

  Future<void> _confirmEnable() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      GlassyToast.show(
        context,
        _localizations.enterSixDigitCode,
        isError: true,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await _service.setEnabled(enabled: true, otp: otp);
      if (!mounted) return;
      setState(() {
        _enabled = true;
        _awaitingCode = false;
        _busy = false;
        _otpController.clear();
      });
      GlassyToast.show(context, _localizations.twoStepEnabled);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      GlassyToast.show(
        context,
        _service.messageFromFunctionsError(e),
        isError: true,
      );
    }
  }

  Future<void> _resend() async {
    setState(() => _busy = true);
    try {
      await _service.sendLoginOtp(force: true);
      if (!mounted) return;
      GlassyToast.show(context, _localizations.verificationEmailSent);
    } catch (e) {
      if (!mounted) return;
      GlassyToast.show(
        context,
        _service.messageFromFunctionsError(e),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.actionBright(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _localizations.twoStepDescription,
                        style: TextStyle(
                          height: 1.4,
                          color: AppColors.secondaryText(context),
                          fontFamily: 'Literata',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _localizations.twoStepVerification,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText(context),
                      fontFamily: 'Literata',
                    ),
                  ),
                  subtitle: Text(
                    email,
                    style: TextStyle(
                      color: AppColors.secondaryText(context),
                      fontFamily: 'Literata',
                      fontSize: 13,
                    ),
                  ),
                  value: _enabled || _awaitingCode,
                  onChanged: _busy ? null : _onToggle,
                ),
              ),
              if (_awaitingCode) ...[
                const SizedBox(height: 24),
                Text(
                  _localizations.enterCodeSentToEmail,
                  style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Literata',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Literata',
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    filled: true,
                    fillColor: AppColors.inputFill(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _confirmEnable,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.action(context),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _localizations.confirmAndEnable,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Literata',
                            ),
                          ),
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : _resend,
                  child: Text(
                    _localizations.resendVerificationEmail,
                    style: TextStyle(
                      color: AppColors.actionBright(context),
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
              ],
            ],
          );

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Column(
        children: [
          if (!widget.isEmbedded)
            AppTopBar(title: _localizations.twoStepVerification),
          Expanded(child: body),
        ],
      ),
    );
  }
}
