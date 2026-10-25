import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/access/access_control_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/language_service.dart';
import '../../../../core/services/logout_service.dart';
import '../../../../core/services/session_manager.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../core/services/local_user_data_guard.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/glassy_toast.dart';
import '../../../../core/ui/subscription_screen.dart';
import '../../../../main.dart' show syncAfterLogin;
import '../../../dashboard/presentation/pages/optimized_dashboard_page.dart';
import 'login.dart';

// Shown after signup (or login) until Firebase emailVerified is true.
class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({super.key, required this.email});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  late AppLocalizations _localizations;
  bool _checking = false;
  bool _resending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
    // Periodically reload in case the user verified in another tab/app.
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _checkVerified(silent: true);
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  Future<void> _resendEmail() async {
    if (_resending || _resendCooldown > 0) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      GlassyToast.show(context, _localizations.pleaseRelogin, isError: true);
      return;
    }

    setState(() => _resending = true);
    try {
      await user.sendEmailVerification();
      if (!mounted) return;
      GlassyToast.show(context, _localizations.verificationEmailSent);
      _startResendCooldown();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      GlassyToast.show(
        context,
        e.message ?? _localizations.failedToSendVerificationEmail,
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;
      GlassyToast.show(
        context,
        _localizations.failedToSendVerificationEmail,
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _checkVerified({bool silent = false}) async {
    if (_checking) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!silent && mounted) {
        GlassyToast.show(
          context,
          _localizations.pleaseRelogin,
          isError: true,
        );
      }
      return;
    }

    if (!silent) setState(() => _checking = true);
    try {
      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;
      if (refreshed == null || !refreshed.emailVerified) {
        if (!silent && mounted) {
          GlassyToast.show(
            context,
            _localizations.emailNotVerifiedYet,
            isError: true,
          );
        }
        return;
      }

      _autoCheckTimer?.cancel();
      if (!mounted) return;
      await _continueAfterVerified(refreshed);
    } catch (e) {
      if (!silent && mounted) {
        GlassyToast.show(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted && !silent) setState(() => _checking = false);
    }
  }

  Future<void> _continueAfterVerified(User user) async {
    GlassyToast.show(context, _localizations.emailVerifiedSuccess);

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
        debugPrint('[ERROR] Post-verify sync failed: $e');
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
      debugPrint('[ERROR] Post-verify navigation failed: $e');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _backToLogin() async {
    _autoCheckTimer?.cancel();
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
    final email = widget.email.isNotEmpty
        ? widget.email
        : (FirebaseAuth.instance.currentUser?.email ?? '');

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
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryLight.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Icon(
                        Icons.mark_email_unread_outlined,
                        size: 36,
                        color: AppColors.actionBright(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _localizations.verifyYourEmail,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _localizations.verificationEmailSentTo,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.secondaryText(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.actionBright(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _localizations.clickLinkInEmail,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.secondaryText(context),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _checking
                            ? null
                            : () => _checkVerified(silent: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppTheme.darkAction
                              : AppTheme.primaryLight,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _checking
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _localizations.iHaveVerified,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: (_resending || _resendCooldown > 0)
                            ? null
                            : _resendEmail,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.actionBright(context),
                          side: BorderSide(
                            color: AppTheme.primaryLight.withValues(alpha: 0.55),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _resending
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: AppColors.actionBright(context),
                                ),
                              )
                            : Text(
                                _resendCooldown > 0
                                    ? '${_localizations.resendIn} $_resendCooldown s'
                                    : _localizations.resendVerificationEmail,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _backToLogin,
                      child: Text(
                        _localizations.backToLogin,
                        style: TextStyle(
                          color: AppColors.secondaryText(context),
                          fontWeight: FontWeight.w500,
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
