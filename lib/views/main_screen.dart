import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/viewmodels/sales_history_view_model.dart';
import 'package:project/viewmodels/settlement_view_model.dart';
import 'package:project/views/admin_page.dart';
import 'package:project/views/app_color.dart';
import 'package:project/views/common_snack_bar.dart';
import 'package:project/views/sales_history_page.dart';
import 'package:project/views/settlement_page.dart';
import 'product_page.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 4개의 메뉴 리스트
  final List<Widget> _pages = [
    const ProductPage(), // 1번: 기존 상품 페이지
    const SalesHistoryPage(), // 2번: 검색 (추후 분리)
    const SettlementPage(), // 3번: 장바구니 (추후 분리)
    const AdminPage(), // 4번: 마이페이지 (추후 분리)
  ];

  void _onItemTapped(int index) {
    // 🔥 판매 내역 탭(index 1)을 눌렀을 때 처리
    if (index == 1) {
      context.read<SalesHistoryViewModel>().selectLatestDate();
    }
    if (index == 2) {
      final salesVm = context.read<SalesHistoryViewModel>();
      final settlementVm = context.read<SettlementViewModel>();

      settlementVm.updateMyLocalData(salesVm.history);
      settlementVm.resetSelection();
      }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime? _lastBackPressed;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        final now = DateTime.now();
        final last = _lastBackPressed;

        if (last == null || now.difference(last) > const Duration(seconds: 2)) {
          _lastBackPressed = now;

          ScaffoldMessenger.of(context).clearSnackBars();
          CommonSnackBar.show(context, message: '한 번 더 누르면 앱이 종료됩니다');
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.white.withOpacity(0.1),
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            backgroundColor: AppColors.mainColor,
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.white,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 4,
                  color: Color(0x55000000),
                ),
              ],
            ),
            selectedIconTheme: const IconThemeData(size: 35),

            unselectedItemColor: Colors.white54,
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 4,
                  color: Color(0x55000000),
                ),
              ],
            ),
            unselectedIconTheme: const IconThemeData(size: 24),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.list_outlined),
                label: '상품 목록',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long),
                label: '판매 내역',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calculate_rounded),
                label: '정산 기록',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.manage_accounts),
                label: '관리자 설정',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
