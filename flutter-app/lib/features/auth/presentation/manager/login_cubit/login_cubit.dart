import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/core/network/url_data.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(const LoginState());

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Secure storage instance
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordObscured: !state.isPasswordObscured));
  }

  Future<void> loginSubmitted() async {
    if (!formKey.currentState!.validate()) return;

    emit(state.copyWith(status: LoginStatus.loading));

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(body['error'] ?? 'Login failed');
      }

      // Save JWT token and userId securely
      await storage.write(key: 'jwt_token', value: body['token']);
      await storage.write(key: 'user_id', value: body['user']['id'].toString());

      // Print in console to verify
      print('### JWT Token saved: ${body['token']}');
      print('### User ID saved: ${body['user']['id']}');

      emit(state.copyWith(status: LoginStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> googleSignIn() async {}

  @override
  Future<void> close() {
    emailController.dispose();
    passwordController.dispose();
    return super.close();
  }
}
