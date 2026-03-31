import 'package:equatable/equatable.dart';

/// States for biometric authentication
sealed class BiometricState extends Equatable {
  const BiometricState();

  @override
  List<Object?> get props => [];
}

class BiometricInitial extends BiometricState {
  const BiometricInitial();
}

class BiometricAvailable extends BiometricState {
  final bool canUseFace;
  final bool canUseFingerprint;
  final bool isBiometricEnabled;

  const BiometricAvailable({
    required this.canUseFace,
    required this.canUseFingerprint,
    required this.isBiometricEnabled,
  });

  @override
  List<Object?> get props => [canUseFace, canUseFingerprint, isBiometricEnabled];
}

class BiometricNotAvailable extends BiometricState {
  const BiometricNotAvailable();
}

class BiometricAuthenticating extends BiometricState {
  const BiometricAuthenticating();
}

class BiometricAuthenticated extends BiometricState {
  const BiometricAuthenticated();
}

class BiometricAuthFailed extends BiometricState {
  final String message;

  const BiometricAuthFailed(this.message);

  @override
  List<Object?> get props => [message];
}

class BiometricAuthCancelled extends BiometricState {
  const BiometricAuthCancelled();
}
