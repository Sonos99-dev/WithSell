import 'package:flutter/material.dart';
import 'package:project/viewmodels/admin_view_model.dart';
import 'package:provider/provider.dart';
import '../viewmodels/product_view_model.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
          onPressed: () async {
            try {
              // 1. 동기화 실행
              final updatedList = await context.read<AdminViewModel>().syncAndSave();
              // 2. 상품 화면 ViewModel에 데이터 전달
              context.read<ProductViewModel>().setProducts(updatedList);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("업데이트 완료")),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("업데이트 실패")),
              );
            }
          },
          child: const Text("상품 목록 불러오기"),
        ),
      ),
    );
  }
}