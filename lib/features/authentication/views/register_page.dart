import 'package:domo/features/authentication/controllers/auth_controller.dart';
import 'package:domo/features/authentication/views/login_page.dart';
import 'package:domo/common/styles/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _pin2Controller = TextEditingController();

  final _role = 'customer'.obs;
  bool _obscurePin = true;
  bool _obscurePin2 = true;

  void setRole(String value) => _role.value = value;

  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (!RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(value)) {
      return 'Please enter your country code';
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _pin2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 70),
                Container(
                  height: 100,
                  width: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.background,
                    image: DecorationImage(
                      image: AssetImage('assets/images/domoologo.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Create your new account",
                    style: AppTheme.textTheme.titleMedium!.copyWith(
                      fontSize: 27,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Adam Eve',
                    hintStyle: TextStyle(
                      color: AppTheme.button.withOpacity(0.5),
                    ),
                    prefixIcon:
                        const Icon(Icons.person, color: AppTheme.button),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                // Phone number field
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    hintText: '+233012345678',
                    hintStyle: TextStyle(
                      color: AppTheme.button.withOpacity(0.5),
                    ),
                    prefixIcon: const Icon(Icons.phone, color: AppTheme.button),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: validatePhoneNumber,
                ),
                const SizedBox(height: 30),
                // PIN field
                TextFormField(
                  controller: _pinController,
                  obscureText: _obscurePin,
                  decoration: InputDecoration(
                    hintText: 'Enter your PIN',
                    hintStyle: TextStyle(
                      color: AppTheme.button.withOpacity(0.5),
                    ),
                    prefixIcon: const Icon(Icons.lock, color: AppTheme.button),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePin ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.button,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePin = !_obscurePin;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your PIN';
                    }
                    if (value.length != 4) {
                      return 'PIN must be 4 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                // Confirm PIN field
                TextFormField(
                  controller: _pin2Controller,
                  obscureText: _obscurePin2,
                  decoration: InputDecoration(
                    hintText: 'Re-enter your PIN',
                    hintStyle: TextStyle(
                      color: AppTheme.button.withOpacity(0.5),
                    ),
                    prefixIcon: const Icon(Icons.lock, color: AppTheme.button),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePin2 ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.button,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePin2 = !_obscurePin2;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please re-enter your PIN';
                    }
                    if (value != _pinController.text) {
                      return 'PINs do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                Text(
                  "Select your role",
                  style: AppTheme.textTheme.titleMedium,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Obx(() => Radio<String>(
                          value: 'customer',
                          groupValue: _role.value,
                          onChanged: (value) => setRole(value!),
                        )),
                    const Text('Customer'),
                    const SizedBox(width: 30),
                    Obx(() => Radio<String>(
                          value: 'artisan',
                          groupValue: _role.value,
                          onChanged: (value) => setRole(value!),
                        )),
                    const Text('Artisan'),
                  ],
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all<Color>(AppTheme.button),
                    padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                    ),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (_role.value.isEmpty) {
                        Get.snackbar('Error', 'Please select a role');
                      } else {
                        final controller = Get.put(AuthController());
                        controller.registerUser(
                          name: _nameController.text,
                          phone: _phoneController.text,
                          pin: _pinController.text,
                          role: _role.value,
                        );
                      }
                    }
                  },
                  child: Text(
                    'Sign Up',
                    style: AppTheme.textTheme.titleMedium!.copyWith(
                      color: AppTheme.background,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: AppTheme.textTheme.titleMedium!.copyWith(
                        color: AppTheme.button,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(() => const Login());
                      },
                      child: Text(
                        "Log In",
                        style: AppTheme.textTheme.titleMedium!.copyWith(
                          color: AppTheme.darkBackground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
