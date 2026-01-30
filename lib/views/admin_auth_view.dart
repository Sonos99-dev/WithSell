// lib/views/admin_auth_view.dart
import 'package:flutter/material.dart';
import 'package:project/viewmodels/admin_auth_view_model.dart';
import 'package:provider/provider.dart';
import 'app_color.dart';

class AdminAuthView extends StatefulWidget {
  final Function() onAuthenticated;
  const AdminAuthView({super.key, required this.onAuthenticated});

  @override
  State<AdminAuthView> createState() => _AdminAuthViewState();
}

class _AdminAuthViewState extends State<AdminAuthView> {
  final TextEditingController _pwController = TextEditingController();

  void _handleAuth() {
    final authVm = context.read<AdminAuthViewModel>();
    if (authVm.checkPassword(_pwController.text)) {
      widget.onAuthenticated();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("비밀번호가 일치하지 않습니다."), backgroundColor: Colors.red),
      );
    }
    _pwController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 80, color: AppColors.mainColor),
            const SizedBox(height: 20),
            const Text("관리자 인증", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("앱 설치 후 최초의 비밀번호는 '0000' 입니다.\n 비밀번호를 잊으신 경우 앱을 재설치 해주세요.", style: TextStyle(fontSize: 16, color: Colors.black54), textAlign: TextAlign.center,),
            const SizedBox(height: 30),
            SizedBox(
              width: 250,
              child: TextField(
                controller: _pwController,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                enableInteractiveSelection: false,
                decoration: InputDecoration(
                  hintText: "비밀번호 입력",
                  filled: true,
                  fillColor: Colors.grey[100],
                  counterText: "",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _handleAuth(),
                onChanged: (value) {
                  if (value.length == 4) {
                    _handleAuth();
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleAuth,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.mainColor, minimumSize: const Size(250, 50)),
              child: const Text("접속", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}