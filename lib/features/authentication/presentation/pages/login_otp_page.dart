import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/access/access_control_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/logout_service.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../core/services/two_step_verification_service.dart';
import '../../../../core/services/local_user_data_guard.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/glassy_toast.dart';
import '../../../../core/ui/subscription_screen.dart';
import '../../../../main.dart' show syncAfterLogin;
import '../../../dashboard/presentation/pages/optimized_dashboard_page.dart';
import 'login.dart';

// Shown after password login when two-step verification is enabled.
class LoginOtpPage extends StatefulWidget {
  final String email;

  const LoginOtpPage({super.key, required this.email});

  @override
  State<LoginOtpPage> createState() => _LoginOtpPageState();
}

class _LoginOtpPageState extends State<LoginOtpPage> {
  late AppLocalizations _localizations;
  final _otpController = TextEditingController();
  final _service = TwoStepVerificationService.instance;

  bool _verifying = false;
  bool _resending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
    _startResendCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = 45);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        t.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      GlassyToast.show(
        context,
        _localizations.enterSixDigitCode,
        isError: true,
      );
      return;
    }

    setState(() => _verifying = true);
    try {
      await _service.verifyLoginOtp(otp);
      if (!mounted) return;
      await _continueAfterOtp();
    } catch (e) {
      if (!mounted) return;
      GlassyToast.show(
        context,
        _service.messageFromFunctionsError(e),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _continueAfterOtp() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      GlassyToast.show(context, _localizations.pleaseRelogin, isError: true);
      await _backToLogin();
      return;
    }

    final sessionManager = SessionManager();
    sessionManager.initializeSession(user, () {
      if (mounted) {
        GlassyToast.show(context, _localizations.sessionExpired);
        LogoutService.instance.onSessionExpired(context);
      }
    });

    try {
      await AccessControlService.instance.loadForCurrentUser();
      await LocalUserDataGuard.ensureBoundToCurrentUser();
      syncAfterLogin().catchError((e) {
        debugPrint('[ERROR] Post-OTP sync failed: $e');
      });
      final isValid = await SubscriptionService().isSubscriptionValid();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => isValid
              ? const OptimizedDashboardPage()
              : const SubscriptionScreen(),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0 || _resending) return;
    setState(() => _resending = true);
    try {
      await _service.sendLoginOtp();
      if (!mounted) return;
      GlassyToast.show(context, _localizations.verificationEmailSent);
      _startResendCooldown();
    } catch (e) {
      if (!mounted) return;
      GlassyToast.show(
        context,
        _service.messageFromFunctionsError(e),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _backToLogin() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPageV2()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    AppTheme.darkScaffold,
                    AppTheme.darkSurface,
                    AppTheme.darkScaffold,
                  ]
                : const [
                    AppTheme.green50,
                    AppTheme.grey100,
                    AppTheme.green50,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.pin_outlined,
                      size: 56,
                      color: AppColors.actionBright(context),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _localizations.enterLoginCode,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText(context),
                        fontFamily: 'Literata',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _localizations.codeSentTo,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.secondaryText(context),
                        fontFamily: 'Literata',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.actionBright(context),
                        fontFamily: 'Literata',
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofocus: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        letterSpacing: 10,
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
                      onSubmitted: (_) => _verify(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _verifying ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppTheme.darkAction
                              : AppTheme.primaryLight,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _verifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _localizations.verifyAndContinue,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Literata',
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: (_resending || _resendCooldown > 0)
                          ? null
                          : _resend,
                      child: Text(
                        _resendCooldown > 0
                            ? '${_localizations.resendIn} $_resendCooldown s'
                            : _localizations.resendCode,
                        style: TextStyle(
                          color: AppColors.actionBright(context),
                          fontFamily: 'Literata',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _backToLogin,
                      child: Text(
                        _localizations.backToLogin,
                        style: TextStyle(
                          color: AppColors.secondaryText(context),
                          fontFamily: 'Literata',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
