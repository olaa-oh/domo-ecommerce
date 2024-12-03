import 'package:domo/features/authentication/controllers/auth_controller.dart';
import 'package:domo/features/authentication/views/forget_password.dart';
import 'package:domo/features/authentication/views/register_page.dart';
import 'package:domo/common/styles/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
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
                const SizedBox(height: 110),
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
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Login to your account",
                    style: AppTheme.textTheme.titleMedium!.copyWith(
                      fontSize: 27,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter your phone number',
                    hintStyle: TextStyle(
                      color: AppTheme.button.withOpacity(0.5),
                    ),
                    prefixIcon: const Icon(Icons.phone, color: AppTheme.button),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(AppTheme.button),
                    padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                    ),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final controller = Get.put(AuthController());
                      String phoneNumber = phoneController.text.trim();

                      // Send OTP and navigate to OTP verification page
                      controller.signIn(phoneNumber);
                      Get.toNamed('/verify-otp');
                    }
                  },
                  child: Text(
                    'Login',
                    style: AppTheme.textTheme.labelLarge!.copyWith(
                      color: AppTheme.background,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Do not have an account? ",
                      style: AppTheme.textTheme.titleMedium!.copyWith(
                        color: AppTheme.button,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(() => const RegisterPage());
                      },
                      child: Text(
                        "Sign Up",
                        style: AppTheme.textTheme.titleMedium!.copyWith(
                          color: AppTheme.darkBackground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}