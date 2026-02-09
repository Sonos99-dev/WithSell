import 'package:flutter/material.dart';
import 'package:project/viewmodels/admin_auth_view_model.dart';
import 'package:project/viewmodels/admin_view_model.dart';import 'package:project/viewmodels/product_view_model.dart';
import 'package:project/viewmodels/sales_history_view_model.dart';
import 'package:project/viewmodels/settlement_view_model.dart';
import 'package:project/views/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  Future<bool>? _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _startLoading();
  }

  Future<bool> _startLoading() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminVM = context.read<AdminViewModel>();
      final productVM = context.read<ProductViewModel>();
      final salesVM = context.read<SalesHistoryViewModel>();
      final settlementVM = context.read<SettlementViewModel>();
      final authVM = context.read<AdminAuthViewModel>();

      await authVM.init(prefs);
      await adminVM.loadFromLocal(prefs);
      productVM.setProducts(adminVM.products);

      await salesVM.init(prefs);
      await settlementVM.init(prefs, salesVM.history);

      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return MaterialApp(
            theme: ThemeData(fontFamily: "NanumSquareRoundFont"),
            debugShowCheckedModeBanner: false,
            home: const MainScreen(),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "앱을 시작하는 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.\n\n오류: ${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
