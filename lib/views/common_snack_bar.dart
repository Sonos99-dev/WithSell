import 'package:flutter/material.dart';
import 'app_color.dart'; // AppColors가 정의된 파일

class CommonSnackBar {
  static void show(BuildContext context, {
    required String message,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : AppColors.mainColor,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}