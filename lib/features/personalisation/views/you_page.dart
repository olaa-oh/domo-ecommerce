import 'package:domo/common/styles/style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domo/features/authentication/models/user_model.dart';
import 'package:domo/data/repos/auth_repository.dart';
import 'package:domo/features/authentication/controllers/auth_controller.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final AuthenticationRepository _authRepository = Get.find();
  final AuthController _authController = Get.put(AuthController());
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser != null) {
        // Fetch user name method from AuthRepository
        final userName = await _authRepository.getUserName(currentUser.uid);
        
        final userDoc = await _authRepository.getUserDocument(currentUser.uid);
        
        setState(() {
          _nameController.text = userDoc['fullName'] ?? userName;
          _phoneController.text = userDoc['phoneNumber'] ?? '';
          _roleController.text = userDoc['role'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Error', 
        'Could not load user data',
        backgroundColor: Colors.red[100]
      );
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() async {
    final currentUser = _authRepository.currentUser;
    if (currentUser != null) {
      try {
        await _authRepository.updateUserProfile({
          'fullName': _nameController.text,
          'role': _roleController.text,
        });

        setState(() {
          _isEditing = false;
        });

        Get.snackbar(
          'Success', 
          'Profile updated successfully',
          backgroundColor: Colors.green[100]
        );
      } catch (e) {
        Get.snackbar(
          'Error', 
          'Could not update profile',
          backgroundColor: Colors.red[100]
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'User Profile', 
          style: Theme.of(context).textTheme.headlineSmall
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _isEditing ? _saveChanges : _toggleEditMode,
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
        onRefresh: () async {
          await _loadUserData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildProfileField(
                  context, 
                  controller: _nameController, 
                  label: 'Full Name', 
                  icon: Icons.person_outline,
                  isEditable: _isEditing
                ),
                const SizedBox(height: 15),
                _buildProfileField(
                  context, 
                  controller: _phoneController, 
                  label: 'Phone Number', 
                  icon: Icons.phone_outlined,
                  isEditable: false,  // Phone number should not be editable
                ),
                const SizedBox(height: 15),
                // _buildProfileField(
                //   context, 
                //   controller: _roleController, 
                //   label: 'Role', 
                //   icon: Icons.work_outline,
                //   isEditable: _isEditing
                // ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => _authController.signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.button,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(
    BuildContext context, {
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    bool isEditable = true,
  }) {
    return TextField(
      controller: controller,
      enabled: isEditable,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        fillColor: isEditable 
          ? Theme.of(context).inputDecorationTheme.fillColor 
          : Colors.grey[200],
        filled: true,
      ),
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    super.dispose();
  }
}