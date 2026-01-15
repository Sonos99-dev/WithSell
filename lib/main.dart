import 'package:firebase_app_check/firebase_app_check.dart' show FirebaseAppCheck, AndroidProvider;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:project/viewmodels/admin_view_model.dart';
import 'package:project/views/main_screen.dart';
import 'package:provider/provider.dart';

import 'repositories/product_repository.dart';
import 'services/firestore_service.dart';
import 'viewmodels/product_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,   // Android
  );
  final productRepository = ProductRepository(FireStoreService());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProductViewModel(),
          ),
        ChangeNotifierProvider(
          create: (_) => AdminViewModel(productRepository),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MainScreen(),
      ),
    ),
  );
}

