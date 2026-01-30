import 'package:firebase_app_check/firebase_app_check.dart' show FirebaseAppCheck, AndroidProvider;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:project/viewmodels/admin_auth_view_model.dart';
import 'package:project/viewmodels/admin_view_model.dart';
import 'package:project/viewmodels/sales_history_view_model.dart';
import 'package:project/views/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repositories/product_repository.dart';
import 'services/firestore_service.dart';
import 'viewmodels/product_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(['NanumSquareRoundFont'], // 폰트 패밀리 이름
      '''
Copyright (c) 2010, NAVER Corporation (https://www.navercorp.com/) with Reserved Font Name Nanum, Naver Nanum, NanumGothic, Naver NanumGothic, NanumMyeongjo, Naver NanumMyeongjo, NanumBrush, Naver NanumBrush, NanumPen, Naver NanumPen, Naver NanumGothicEco, NanumGothicEco, Naver NanumMyeongjoEco, NanumMyeongjoEco, Naver NanumGothicLight, NanumGothicLight, NanumBarunGothic, Naver NanumBarunGothic, NanumSquareRound, NanumBarunPen, MaruBuri, NanumSquareNeo

​

This Font Software is licensed under the SIL Open Font License, Version 1.1.
      ''',
    );
  });
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
  final prefs = await SharedPreferences.getInstance();

  await adminVM.loadFromLocal(prefs);
  productVM.setProducts(adminVM.products);
  final initialPw = prefs.getString("admin_password") ?? "0000";

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ProductViewModel>.value(value: productVM),
        ChangeNotifierProvider<AdminViewModel>.value(value: adminVM),
        ChangeNotifierProvider<SalesHistoryViewModel>.value(value: salesVM),
        ChangeNotifierProvider(create: (_) => AdminAuthViewModel(initialPw)),
      ],
      child: MaterialApp(
        theme: ThemeData(
          fontFamily: "NanumSquareRoundFont",
        ),
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
      ),
    ),
  );
}