import 'package:domo/features/authentication/views/login_page.dart';
import 'package:domo/common/styles/style.dart';
// import 'package:domo/src/features/authentication/screens/login_pages/otp.dart';
import 'package:flutter/material.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: AppTheme.background,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              // crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 10,
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () {
                      // go back to login page
                      Navigator.pop(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Login(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      size: 30,
                      color: AppTheme.text,
                    ),
                  ),
                  // ),
                ),
                const SizedBox(
                  height: 60,
                ),
                Container(
                  height: size.height * 0.3,
                  width: size.width * 0.5,
                  // padding: EdgeInsets.all(30),
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/onboard/donutWorry.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Text(
                  'Forgot Password?',
                  style: AppTheme.textTheme.titleMedium!.copyWith(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.button),
                ),
                const SizedBox(height: 5),
                Text("Donut worry, we got you covered.",
                    style: AppTheme.textTheme.titleMedium!.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.button)),
                const SizedBox(height: 20),
                Text(
                  'Enter your phone number to reset your password',
                  style: AppTheme.textTheme.bodyMedium!.copyWith(
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter your phone number',
                    hintStyle: TextStyle(
                      color: AppTheme.button.withOpacity(0.5),
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                ElevatedButton(
                    onPressed: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => VerifyOTPPage(),
                      //   ),
                      // );
                    },
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(AppTheme.button)),
                    child: Text(
                      "Reset",
                      style: AppTheme.textTheme.bodyLarge!
                          .copyWith(color: AppTheme.background),
                    ))
              ],
            ),
          ),
        ));
  }
}
