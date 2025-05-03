import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domo/common/styles/style.dart';
import 'package:domo/features/authentication/controllers/auth_controller.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  // Create a global form key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // final AuthController authController = Get.find(AuthController());
    final AuthController authController = Get.find<AuthController>();

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
                TextFormField(
                  controller: authController.fullNameController,
                  decoration: InputDecoration(
                    hintText: 'Full Name',
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
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: authController.phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Phone Number',
                    hintStyle: TextStyle(
                      color: AppTheme.button.withOpacity(0.5),
                    ),
                    prefixIcon: const Icon(Icons.phone, color: AppTheme.button),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  validator: authController.validatePhone,
                ),
                const SizedBox(height: 30),

                // User Role Selection
                Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Radio<String>(
                          value: 'customer',
                          groupValue: authController.userType.value,
                          onChanged: (value) {
                            authController.userType.value = value!;
                          },
                        ),
                        Text(
                          'Customer',
                          style: AppTheme.textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 20),
                        Radio<String>(
                          value: 'artisan',
                          groupValue: authController.userType.value,
                          onChanged: (value) {
                            authController.userType.value = value!;
                          },
                        ),
                        Text(
                          'Artisan',
                          style: AppTheme.textTheme.bodyMedium,
                        ),
                      ],
                    )),

                const SizedBox(height: 20),

                // OTP Request Button or OTP Input based on state
                Obx(() => !authController.isOtpSent.value
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.button,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: authController.isLoading.value
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  if (authController.userType.value.isEmpty) {
                                    Get.snackbar(
                                        'Error', 'Please select a user type');
                                    return;
                                  }
                                  authController.sendOTP();
                                }
                              },
                        child: authController.isLoading.value
                            ? const CircularProgressIndicator(
                                color: AppTheme.background)
                            : Text(
                                'Send OTP',
                                style: AppTheme.textTheme.labelLarge!.copyWith(
                                  color: AppTheme.background,
                                ),
                              ),
                      )
                    : Column(
                        children: [
                          Text(
                            'Enter the 6-digit OTP sent to your phone',
                            style: AppTheme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 15),
                          PinCodeTextField(
                            appContext: context,
                            length: 6,
                            controller: authController.otpController,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {},
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(8),
                              activeColor: AppTheme.button,
                              inactiveColor: AppTheme.button.withOpacity(0.5),
                              selectedColor: AppTheme.button,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Obx(() => Text(
                                    authController.resendTimer.value > 0
                                        ? 'Resend OTP in ${authController.resendTimer.value}s'
                                        : 'Didn\'t receive OTP?',
                                    style: AppTheme.textTheme.bodySmall,
                                  )),
                              const SizedBox(width: 5),
                              Obx(() => TextButton(
                                    onPressed:
                                        authController.resendTimer.value > 0 ||
                                                authController.isLoading.value
                                            ? null
                                            : () => authController.sendOTP(),
                                    child: Text(
                                      'Resend',
                                      style: AppTheme.textTheme.bodySmall!
                                          .copyWith(
                                        color:
                                            authController.resendTimer.value > 0
                                                ? Colors.grey
                                                : AppTheme.button,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.button,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: authController.isLoading.value
                                ? null
                                : () => authController.registerUser(),
                            child: authController.isLoading.value
                                ? const CircularProgressIndicator(
                                    color: AppTheme.background)
                                : Text(
                                    'Register',
                                    style:
                                        AppTheme.textTheme.labelLarge!.copyWith(
                                      color: AppTheme.background,
                                    ),
                                  ),
                          ),
                        ],
                      )),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Get.toNamed('/login'),
                  child: Text(
                    'Already have an account? Login',
                    style: AppTheme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
