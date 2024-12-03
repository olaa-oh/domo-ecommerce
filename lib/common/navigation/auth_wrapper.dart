import 'package:domo/common/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppRouterWrapper extends StatelessWidget {
  final Widget? child;

  const AppRouterWrapper({Key? key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final router = Get.put(AppRouter());

    return Obx(() {
      if (router.isLoading.value) {
        return const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }
      return child ?? const SizedBox.shrink();
    });
  }
}