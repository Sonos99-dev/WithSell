import 'package:flutter/material.dart';import 'package:project/viewmodels/admin_view_model.dart';
import 'package:project/viewmodels/product_view_model.dart';
import 'package:project/views/add_product_page.dart';
import 'package:project/views/app_color.dart';
import 'package:provider/provider.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _isAuthenticated = false;
  final TextEditingController _pwController = TextEditingController();
  final String _adminPassword = "0000"; // 초기 비밀번호

  // 헥사코드를 컬러로 변환하는 헬퍼 함수
  Color _hexToColor(String hexCode) {
    try {
      hexCode = hexCode.replaceAll('#', '');
      if (hexCode.length == 6) {
        hexCode = 'FF$hexCode';
      }
      return Color(int.parse('0x$hexCode'));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    // 페이지 진입 시 최신 목록 불러오기
    Future.microtask(() => context.read<AdminViewModel>().loadFromLocal());
  }

  @override
  Widget build(BuildContext context) {
    // 1. 비밀번호 인증 전 화면
    if (!_isAuthenticated) {
      return _buildAuthView();
    }

    // 2. 인증 후 관리자 화면
    final adminVm = context.watch<AdminViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("관리자 모드",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.mainColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => setState(() => _isAuthenticated = false),
          )
        ],
      ),
      body: adminVm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Text(
              "등록된 상품 총 ${adminVm.products.length}개 (클릭하여 수정)",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: _buildProductList(adminVm)),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 220,
            height: 90,
            child: FloatingActionButton.extended(
              heroTag: "add_page",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddProductPage()),
                );
              },
              backgroundColor: Colors.orangeAccent,
              icon: const Icon(Icons.add, color: Colors.white, size: 40,),
              label: const Text("새 상품 등록", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 220,
            height: 90,
            child: FloatingActionButton.extended(
              heroTag: "sync_data",
              onPressed: () async {
                await adminVm.syncAndSave();
                if (context.mounted) {
                  context.read<ProductViewModel>().setProducts(adminVm.products);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("서버와 동기화되었습니다.")),
                  );
                }
              },
              backgroundColor: AppColors.mainColor,
              icon: const Icon(Icons.sync, color: Colors.white, size: 40),
              label: const Text("목록 동기화", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // 비밀번호 입력 화면
  Widget _buildAuthView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("관리자 인증", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.mainColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              TextField(
                controller: _pwController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "관리자 비밀번호",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.password),
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _checkPassword(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("접속하기", style: TextStyle(color: Colors.white, fontSize: 18)),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _checkPassword() {
    if (_pwController.text == _adminPassword) {
      setState(() => _isAuthenticated = true);
      _pwController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("비밀번호가 일치하지 않습니다."), backgroundColor: Colors.red),
      );
    }
  }

  // 상품 리스트 뷰
  Widget _buildProductList(AdminViewModel vm) {
    if (vm.products.isEmpty) {
      return const Center(child: Text("상품이 없습니다. 동기화 버튼을 눌러보세요."));
    }
    return ListView.separated(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 100,
      ),
      itemCount: vm.products.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final p = vm.products[index];
        final Color themeColor = _hexToColor(p.borderColor);

        return ListTile(
          onTap: () {
            // 상품 클릭 시 수정 페이지로 이동하며 기존 데이터 전달
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddProductPage(product: p),
              ),
            );
          },
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Icon(Icons.edit, color: Colors.white, size: 20),
            ),
          ),
          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("기본가: ${p.price}원 / ${p.discountQuantity}개 구매 시 ${p.discountPrice}원 할인 적용중"),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _showDeleteConfirm(context, vm, p.productNumber, p.name),
          ),
        );
      },
    );
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirm(BuildContext context, AdminViewModel vm, int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("상품 삭제"),
        content: Text("'$name' 상품을 영구 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          TextButton(
            onPressed: () async {
              await vm.deleteProduct(id);
              if (context.mounted) {
                // 삭제 후 메인 화면 데이터 갱신
                context.read<ProductViewModel>().setProducts(vm.products);
                Navigator.pop(context);
              }
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}