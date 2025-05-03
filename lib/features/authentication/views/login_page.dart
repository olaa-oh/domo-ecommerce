import 'package:domo/features/authentication/controllers/auth_controller.dart';
import 'package:domo/features/authentication/views/register_page.dart';
import 'package:domo/common/styles/style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class Login extends StatelessWidget {
  Login({super.key});

  // Create a global form key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // final AuthController authController = Get.put(AuthController());
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
                  controller: authController.phoneController,
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
                  validator: authController.validatePhone,
                ),
                const SizedBox(height: 30),
                
                // OTP Request Button or OTP Input based on state
                Obx(() => !authController.isOtpSent.value
                  ? ElevatedButton(
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
                      onPressed: authController.isLoading.value 
                        ? null 
                        : () {
                            if (_formKey.currentState!.validate()) {
                              authController.sendOTP();
                            }
                          },
                      child: authController.isLoading.value
                        ? const CircularProgressIndicator(color: AppTheme.background)
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
                              onPressed: authController.resendTimer.value > 0 || authController.isLoading.value
                                ? null
                                : () => authController.sendOTP(),
                              child: Text(
                                'Resend',
                                style: AppTheme.textTheme.bodySmall!.copyWith(
                                  color: authController.resendTimer.value > 0
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
                          onPressed: authController.isLoading.value 
                            ? null 
                            : () {
                                // Validate OTP before proceeding
                                final otpValidation = authController.validateOTP(authController.otpController.text);
                                if (otpValidation != null) {
                                  Get.snackbar('Error', otpValidation, backgroundColor: Colors.red);
                                  return;
                                }
                                authController.loginUser();
                              },
                          child: authController.isLoading.value
                            ? const CircularProgressIndicator(color: AppTheme.background)
                            : Text(
                                'Login',
                                style: AppTheme.textTheme.labelLarge!.copyWith(
                                  color: AppTheme.background,
                                ),
                              ),
                        )                      ],
                    )
                ),
                
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                     onPressed: () => Get.toNamed('/register'),
                     child: Text(
                      "Do not have an account?Sign Up",
                      style: AppTheme.textTheme.titleMedium!.copyWith(
                        color: AppTheme.button,
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