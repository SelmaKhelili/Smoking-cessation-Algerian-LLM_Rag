import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/core/network/url_data.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../widgets/auth_scaffold.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/social_button.dart';
// Import UserData

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _smokingStartAgeController = TextEditingController();
  final _cigarettesPerDayController = TextEditingController();
  final _smokingYearsController = TextEditingController();
  
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _acceptedTerms = false;
  String? _selectedGender;

  // --- Validation Logic ---

  void _handleSignUp() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms & Conditions')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          // convert dd/mm/yyyy → yyyy-mm-dd
          'date_of_birth': _dobController.text.split('/').reversed.join('-'),
          'gender': _selectedGender,
          'smoking_start_age': int.tryParse(_smokingStartAgeController.text),
          'cigarettes_per_day': int.tryParse(_cigarettesPerDayController.text),
          'smoking_years': int.tryParse(_smokingYearsController.text),
        }),
      );

      if (response.statusCode != 201) {
        final body = jsonDecode(response.body);
        throw Exception(body['error']);
      }

      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'New Account',
      child: SingleChildScrollView(
        child: Form( // Wrap content in Form
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // --- Full Name ---
              AuthTextField(
                label: 'Full Name',
                hint: 'Name',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Name is required';
                  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                    return 'Name must contain only letters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // --- Email ---
              AuthTextField(
                label: 'Email',
                hint: 'example@gmail.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email is required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // --- Date of Birth ---
              GestureDetector(
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000, 1, 1),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFFFF8025), // Orange
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                          dialogBackgroundColor: Colors.white,
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    String formatted = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                    setState(() {
                      _dobController.text = formatted;
                    });
                  }
                },
                child: AbsorbPointer(
                  child: AuthTextField(
                    label: 'Date of Birth',
                    hint: 'dd/mm/yyyy',
                    controller: _dobController,
                    keyboardType: TextInputType.datetime,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Date of Birth is required';
                      if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) {
                        return 'Format must be dd/mm/yyyy';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // --- Gender ---
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (v) => setState(() => _selectedGender = v),
                validator: (value) => value == null ? 'Select a gender' : null,
              ),
              const SizedBox(height: 16),

              // --- Smoking Start Age ---
              AuthTextField(
                label: 'Smoking Start Age',
                hint: 'e.g., 18',
                controller: _smokingStartAgeController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'This field is required';
                  if (int.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- Cigarettes per Day ---
              AuthTextField(
                label: 'Cigarettes per Day',
                hint: 'e.g., 10',
                controller: _cigarettesPerDayController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'This field is required';
                  if (int.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- Smoking Years ---
              AuthTextField(
                label: 'Smoking Years',
                hint: 'e.g., 5',
                controller: _smokingYearsController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'This field is required';
                  if (int.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // --- Password ---
              AuthTextField(
                label: 'Password',
                hint: '********',
                controller: _passwordController,
                obscure: _obscure1,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Password is required';
                  if (value.length < 8 || value.length > 16) {
                    return 'Password must be between 8-16 characters';
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure1 ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                ),
              ),
              const SizedBox(height: 16),
              
              // --- Confirm Password ---
              AuthTextField(
                label: 'Confirm Password',
                hint: '********',
                controller: _confirmController,
                obscure: _obscure2,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please confirm password';
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure2 ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // --- Terms Checkbox ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    activeColor: const Color(0xFFFF8025),
                    onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                          children: [
                            TextSpan(text: 'By continuing, you agree to '),
                            TextSpan(
                              text: 'Terms of Use',
                              style: TextStyle(color: Color(0xFFFF8025)),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy.',
                              style: TextStyle(color: Color(0xFFFF8025)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // --- Sign Up Button ---
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8025),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  onPressed: _handleSignUp,
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // --- Social Login Section ---
              const Center(
                child: Text(
                  'or sign up with',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SocialButton(
                    onTap: () {},
                    child: Image.asset('assets/icons/google.png', width: 46, height: 46),
                  ),
                  const SizedBox(width: 16),
                  SocialButton(
                    onTap: () {},
                    child: Image.asset('assets/icons/apple.png', width: 40, height: 40),
                  ),
                  const SizedBox(width: 16),
                  SocialButton(
                    onTap: () {},
                    child: Image.asset('assets/icons/facebook.png', width: 40, height: 40),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // --- Login Link ---
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.login);
                  },
                  child: const Text(
                    'already have an account? Log in',
                    style: TextStyle(color: Color(0xFFFF8025)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
