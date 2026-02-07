part of 'set_password_cubit.dart';

enum SetPasswordStatus { initial, loading, success, failure }

class SetPasswordState extends Equatable {
  final SetPasswordStatus status;
  final String? errorMessage;
  final bool isNewPasswordObscured;
  final bool isConfirmPasswordObscured;

  const SetPasswordState({
    this.status = SetPasswordStatus.initial,
    this.errorMessage,
    this.isNewPasswordObscured = true,
    this.isConfirmPasswordObscured = true,
  });

  SetPasswordState copyWith({
    SetPasswordStatus? status,
    String? errorMessage,
    bool? isNewPasswordObscured,
    bool? isConfirmPasswordObscured,
  }) {
    return SetPasswordState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      isNewPasswordObscured: isNewPasswordObscured ?? this.isNewPasswordObscured,
      isConfirmPasswordObscured:
          isConfirmPasswordObscured ?? this.isConfirmPasswordObscured,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        isNewPasswordObscured,
        isConfirmPasswordObscured,
      ];
}
