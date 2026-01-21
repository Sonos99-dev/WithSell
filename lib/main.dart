import 'package:firebase_app_check/firebase_app_check.dart' show FirebaseAppCheck, AndroidProvider;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:project/viewmodels/admin_view_model.dart';
import 'package:project/viewmodels/sales_history_view_model.dart';
import 'package:project/views/main_screen.dart';
import 'package:provider/provider.dart';

import 'repositories/product_repository.dart';
import 'services/firestore_service.dart';
import 'viewmodels/product_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // App Check 설정
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  // 1. 필요한 서비스 및 리포지토리 준비
  final firestoreService = FireStoreService();
  final productRepo = ProductRepository(firestoreService);

  // 2. ViewModel 객체 생성
  final adminVM = AdminViewModel(productRepo);
  final productVM = ProductViewModel();
  final salesVM = SalesHistoryViewModel();

  // 3. 앱 실행 전 로컬 데이터 로드 및 연동 (핵심)
  await adminVM.loadFromLocal();
  productVM.setProducts(adminVM.products); // 여기서 데이터가 복사됨

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ProductViewModel>.value(value: productVM),
        ChangeNotifierProvider<AdminViewModel>.value(value: adminVM),
        ChangeNotifierProvider<SalesHistoryViewModel>.value(value: salesVM),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MainScreen(),
      ),
    ),
  );
}