import 'package:domo/features/authentication/controllers/auth_controller.dart';
import 'package:domo/features/authentication/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domo/common/styles/style.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OTPVerificationPage extends StatelessWidget {
  OTPVerificationPage({Key? key}) : super(key: key);

  final controller = Get.find<AuthController>();
  final otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Determine if this is a registration or login flow
    final isRegistration = Get.arguments is UserModel;
    final UserModel? userModel = isRegistration ? Get.arguments as UserModel : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Phone Number'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter Verification Code',
              style: AppTheme.textTheme.titleLarge,
            ),
            const SizedBox(height: 30),
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: otpController,
              onChanged: (value) {},
              onCompleted: (value) {
                // Handle OTP verification based on flow
                if (isRegistration && userModel != null) {
                  controller.verifyOTP(value, userModel);
                } else {
                  controller.verifyOtpSignin(value);
                }
              },
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                activeColor: AppTheme.button,
                inactiveColor: AppTheme.button.withOpacity(0.5),
                selectedColor: AppTheme.button,
              ),
            ),
            const SizedBox(height: 30),
            Obx(() => controller.isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(AppTheme.button),
                      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                        const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                      ),
                    ),
                    onPressed: () {
                      if (otpController.text.length == 6) {
                        // Handle OTP verification based on flow
                        if (isRegistration && userModel != null) {
                          controller.verifyOTP(otpController.text, userModel);
                        } else {
                          controller.verifyOtpSignin(otpController.text);
                        }
                      }
                    },
                    child: Text('Verify',
                        style: AppTheme.textTheme.bodySmall!.copyWith(
                          color: AppTheme.background,
                        )),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}