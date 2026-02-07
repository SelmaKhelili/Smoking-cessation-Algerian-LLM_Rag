import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'set_password_state.dart';

class SetPasswordCubit extends Cubit<SetPasswordState> {
  SetPasswordCubit() : super(const SetPasswordState());

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  void toggleNewPasswordVisibility() {
    emit(state.copyWith(isNewPasswordObscured: !state.isNewPasswordObscured));
  }

  void toggleConfirmPasswordVisibility() {
    emit(state.copyWith(
        isConfirmPasswordObscured: !state.isConfirmPasswordObscured));
  }

  Future<void> submitPasswordChange() async {
    if (!formKey.currentState!.validate()) return;

    // specific validation: do passwords match?
    if (newPasswordController.text != confirmController.text) {
      emit(state.copyWith(
        status: SetPasswordStatus.failure,
        errorMessage: "Passwords do not match",
      ));
      return;
    }

    emit(state.copyWith(status: SetPasswordStatus.loading));

    try {
      // TODO: Implement your API call to change the password here
      // await authRepository.changePassword(newPasswordController.text);

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      emit(state.copyWith(status: SetPasswordStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: SetPasswordStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  @override
  Future<void> close() {
    newPasswordController.dispose();
    confirmController.dispose();
    return super.close();
  }
}
