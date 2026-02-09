import 'package:firebase_app_check/firebase_app_check.dart' show FirebaseAppCheck, AndroidProvider;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:project/viewmodels/admin_auth_view_model.dart';
import 'package:project/viewmodels/admin_view_model.dart';
import 'package:project/viewmodels/sales_history_view_model.dart';
import 'package:project/viewmodels/settlement_view_model.dart';
import 'package:project/views/app_initializer.dart';
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminViewModel(ProductRepository(FireStoreService()))),
        ChangeNotifierProvider(create: (_) => ProductViewModel()),
        ChangeNotifierProvider(create: (_) => SalesHistoryViewModel()),
        ChangeNotifierProvider(create: (_) => SettlementViewModel()),
        ChangeNotifierProvider(create: (_) => AdminAuthViewModel()),
      ],
      child: const AppInitializer(),
    ),
  );
}