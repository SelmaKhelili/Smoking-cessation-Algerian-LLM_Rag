part of 'login_cubit.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  final LoginStatus status;
  final String? errorMessage;
  final bool isPasswordObscured;

  const LoginState({
    this.status = LoginStatus.initial,
    this.errorMessage,
    this.isPasswordObscured = true,
  });

  LoginState copyWith({
    LoginStatus? status,
    String? errorMessage,
    bool? isPasswordObscured,
  }) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: errorMessage, // Clear error if not provided (optional logic) or overwrite
      isPasswordObscured: isPasswordObscured ?? this.isPasswordObscured,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, isPasswordObscured];
}
