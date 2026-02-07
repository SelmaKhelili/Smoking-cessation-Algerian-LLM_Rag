import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../widgets/auth_scaffold.dart';
import '../manager/set_password/set_password_cubit.dart';

const Color kPrimaryColor = Color(0xFFFF8025);

class SetPasswordPage extends StatelessWidget {
  const SetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SetPasswordCubit(),
      child: const _SetPasswordView(),
    );
  }
}

class _SetPasswordView extends StatelessWidget {
  const _SetPasswordView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SetPasswordCubit>();

    return AuthScaffold(
      title: 'Change Password',
      child: BlocConsumer<SetPasswordCubit, SetPasswordState>(
        listener: (context, state) {
          if (state.status == SetPasswordStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Error occurred')),
            );
          } else if (state.status == SetPasswordStatus.success) {
            // Navigate to login after successful password change
            Navigator.pushReplacementNamed(context, AppRoutes.profilepage);
          }
        },
        builder: (context, state) {
          return Form(
            key: cubit.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                
                // New Password Field
                AuthTextField(
                  label: 'New Password',
                  hint: '********',
                  controller: cubit.newPasswordController,
                  obscure: state.isNewPasswordObscured,
                  suffixIcon: IconButton(
                    icon: Icon(
                      state.isNewPasswordObscured
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => cubit.toggleNewPasswordVisibility(),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Confirm Password Field
                AuthTextField(
                  label: 'Confirm New Password',
                  hint: '********',
                  controller: cubit.confirmController,
                  obscure: state.isConfirmPasswordObscured,
                  suffixIcon: IconButton(
                    icon: Icon(
                      state.isConfirmPasswordObscured
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => cubit.toggleConfirmPasswordVisibility(),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: state.status == SetPasswordStatus.loading
                        ? null
                        : () => cubit.submitPasswordChange(),
                    child: state.status == SetPasswordStatus.loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create New Password',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
