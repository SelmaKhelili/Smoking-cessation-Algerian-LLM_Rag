import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/core/userdata/user_data.dart'; 

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _userData = UserData();
  final ImagePicker _picker = ImagePicker();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  late TextEditingController _phoneController;
  
  String? _tempImagePath;
  bool _isSaving = false;
  String? _errorMessage;
  String? _errorField; // To highlight specific field

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _userData.name.value);
    _emailController = TextEditingController(text: _userData.email.value);
    _dobController = TextEditingController(text: _userData.dob.value);
    _phoneController = TextEditingController(text: _userData.phone.value);
    _tempImagePath = _userData.imagePath.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _tempImagePath = image.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    // Clear previous errors
    setState(() {
      _errorMessage = null;
      _errorField = null;
      _isSaving = true;
    });

    // Basic validation
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Username cannot be empty';
        _errorField = 'username';
        _isSaving = false;
      });
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Email cannot be empty';
        _errorField = 'email';
        _isSaving = false;
      });
      return;
    }

    final result = await _userData.updateBackend(
      newName: _nameController.text,
      newEmail: _emailController.text,
      newPhone: _phoneController.text,
      newDob: _dobController.text,
      newImagePath: _tempImagePath,
    );

    setState(() {
      _isSaving = false;
    });

    if (result['success'] == true) {
      // Success - navigate back with success message
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile Updated Successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Show error message
      setState(() {
        _errorMessage = result['error'];
        _errorField = result['field']; // Highlight specific field
      });
      
      // Also show as snackbar for immediate feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Update failed'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Color _getFieldBorderColor(String fieldName) {
    if (_errorField == fieldName) {
      return Colors.red;
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider bgImage;
    if (_tempImagePath?.startsWith('assets/') ?? false) {
      bgImage = AssetImage(_tempImagePath!);
    } else if (_tempImagePath?.isNotEmpty ?? false) {
      bgImage = FileImage(File(_tempImagePath!));
    } else {
      bgImage = const AssetImage('assets/images/default_avatar.png');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFF8025)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFFFF8025),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFFEEF2FF),
                      backgroundImage: bgImage,
                      radius: 50,
                      child: _tempImagePath == null || _tempImagePath!.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 40,
                              color: Color(0xFFFF8025),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF8025),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Show error message if any
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            _buildLabeledField('Full Name', _nameController, fieldName: 'username'),
            _buildLabeledField('Email', _emailController, fieldName: 'email', readOnly: true),
            _buildLabeledField('Date of Birth', _dobController, fieldName: 'date_of_birth'),
            _buildLabeledField('Phone number', _phoneController, fieldName: 'phone'),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8025),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                  disabledBackgroundColor: const Color(0xFFFF8025).withOpacity(0.5),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Update Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledField(
    String label,
    TextEditingController controller, {
    String? fieldName,
    bool readOnly = false,
  }) {
    final hasError = fieldName != null && _errorField == fieldName;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: hasError ? Colors.red : Colors.black87,
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.error, color: Colors.red, size: 16),
                ]
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasError ? Colors.red : Colors.transparent,
                width: hasError ? 1.5 : 0,
              ),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(
                color: Color(0xFFFF8025),
                fontWeight: FontWeight.w500,
              ),
              readOnly: readOnly,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                hintStyle: TextStyle(color: const Color(0xFFFF8025).withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}