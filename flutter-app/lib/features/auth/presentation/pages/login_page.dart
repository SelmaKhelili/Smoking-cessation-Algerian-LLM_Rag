import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../../../core/widgets/social_button.dart';
import '../widgets/auth_scaffold.dart';
import '../manager/login_cubit/login_cubit.dart';

// Define your colors in a central theme file in the future
const Color kPrimaryColor = Color(0xFFFF8025);

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    // Access the cubit provided above
    final cubit = context.read<LoginCubit>();

    return AuthScaffold(
      title: 'Log In',
      child: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state.status == LoginStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Authentication Failed')),
            );
          } else if (state.status == LoginStatus.success) {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Form(
              key: cubit.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  // Header
                  const Column(
                    children: [
                      Text(
                        'Welcome',
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'to use SaiApp please Login',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Inputs
                  AuthTextField(
                    label: 'Email or Mobile Number',
                    hint: 'example@gmail.com',
                    controller: cubit.emailController,
                    keyboardType: TextInputType.emailAddress,
                    // Add validator logic here if AuthTextField supports it
                  ),
                  const SizedBox(height: 20),
                  AuthTextField(
                    label: 'Password',
                    hint: '********',
                    controller: cubit.passwordController,
                    obscure: state.isPasswordObscured,
                    suffixIcon: IconButton(
                      icon: Icon(
                        state.isPasswordObscured
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => cubit.togglePasswordVisibility(),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                      },
                      child: const Text(
                        'Forgot Password',
                        style: TextStyle(color: kPrimaryColor, fontSize: 13),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Login Button
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
                      onPressed: state.status == LoginStatus.loading
                          ? null
                          : () => cubit.loginSubmitted(),
                      child: state.status == LoginStatus.loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Log In',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Social Login Divider
                  const Center(
                    child: Text(
                      'or sign up with',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Social Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SocialButton(
                        onTap: () => cubit.googleSignIn(), // Example usage
                        child: Image.asset(
                          'assets/icons/google.png',
                          width: 46,
                          height: 46,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SocialButton(
                        onTap: () {}, // Add method to cubit if needed
                        child: Image.asset(
                          'assets/icons/apple.png',
                          width: 40,
                          height: 40,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SocialButton(
                        onTap: () {}, // Add method to cubit if needed
                        child: Image.asset(
                          'assets/icons/facebook.png',
                          width: 40,
                          height: 40,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Sign Up Link
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.signup);
                      },
                      child: const Text(
                        "Don't have an account? Sign Up",
                        style: TextStyle(color: kPrimaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
