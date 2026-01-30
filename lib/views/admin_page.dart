import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/models/product_category.dart';
import 'package:project/viewmodels/admin_auth_view_model.dart';
import 'package:project/viewmodels/admin_view_model.dart';
import 'package:project/viewmodels/product_view_model.dart';
import 'package:project/views/add_product_page.dart';
import 'package:project/views/admin_auth_view.dart';
import 'package:project/views/app_color.dart';
import 'package:project/views/sales_history_base_dialog.dart' show SalesHistoryBaseDialog;
import 'package:provider/provider.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _isAuthenticated = false;

  ProductCategory _selectedCategory = ProductCategory.all;

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return AdminAuthView(
        onAuthenticated: () => setState(() => _isAuthenticated = true),
      );
    }

    final adminVm = context.watch<AdminViewModel>();
    final filteredProducts = _selectedCategory == ProductCategory.all
        ? adminVm.products
        : adminVm.products.where((p) => p.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("관리자 모드",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
        backgroundColor: AppColors.mainColor,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 30,),
            onPressed: () => _showChangePasswordDialog(context),
            tooltip: '비밀번호 변경',
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 30,),
            onPressed: () => setState(() => _isAuthenticated = false),
            tooltip: '로그아웃',
          )
        ],
      ),
      body: adminVm.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.mainColor))
          : Column(
        children: [
          _buildDashboard(adminVm),
          _buildCategoryBar(),
          Expanded(child: _buildProductList(adminVm, filteredProducts)),
        Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 75),
        child: Column(
          children: [
            const Text(
              "withSell v1.0.0",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            TextButton.icon(
              onPressed: () {
                showLicensePage(
                  context: context,
                  applicationName: 'withSell',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2026 withSell. All rights reserved.',
                );
              },
              icon: const Icon(Icons.description_outlined, size: 18, color: Colors.grey),
              label: const Text(
                "Open Source License",
                style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
        ],
      ),
      floatingActionButton: _buildFabMenu(context, adminVm),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDashboard(AdminViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      decoration: BoxDecoration(
        color: AppColors.mainColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("전체 상품", "${vm.products.length}개"),
          _buildStatDivider(),
          _buildStatItem("할인 적용", "${vm.products.where((e) => e.discountQuantity > 0).length}건"),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3));
  }

  Widget _buildCategoryBar() {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ProductCategory.values.length,
        itemBuilder: (context, index) {
          final category = ProductCategory.values[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              showCheckmark: false,
              label: Text(category.label),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category);
                }
              },
              selectedColor: AppColors.mainColor,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(
                  color: isSelected ? AppColors.mainColor : Colors.grey[300]!,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductList(AdminViewModel vm, List<dynamic> filteredList) {
    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _selectedCategory == ProductCategory.all
                  ? "등록된 상품이 없습니다."
                  : "${_selectedCategory.label} 카테고리에 상품이 없습니다.",
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 120),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final p = filteredList[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddProductPage(product: p))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: AppColors.mainColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(Icons.edit_note_rounded, color: AppColors.mainColor, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(p.category.label, style: TextStyle(color: AppColors.mainColor, fontWeight: FontWeight.w900, fontSize: 12)),
                              const SizedBox(width: 8),
                              const Text("•", style: TextStyle(color: Colors.grey)),
                              const SizedBox(width: 8),
                              Text("No.${p.productNumber}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(p.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(
                            p.discountQuantity > 0
                                ? "${p.price}원 (${p.discountQuantity}개 구매 시 ${p.discountPrice}원 할인 적용중)"
                                : "${p.price}원 (할인 없음)",
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      onPressed: () => _showDeleteConfirm(context, vm, p.productNumber, p.name),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFabMenu(BuildContext context, AdminViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: FloatingActionButton.extended(
              heroTag: "sync_data",
              onPressed: () async {
                await vm.syncAndSave();
                if (context.mounted) {
                  context.read<ProductViewModel>().setProducts(vm.products);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("서버와 동기화되었습니다."), behavior: SnackBarBehavior.floating));
                }
              },
              backgroundColor: Colors.white,
              elevation: 4,
              icon: Icon(Icons.sync_rounded, color: AppColors.mainColor),
              label: Text("목록 동기화", style: TextStyle(color: AppColors.mainColor, fontWeight: FontWeight.w900, fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: FloatingActionButton.extended(
              heroTag: "add_page",
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductPage())),
              backgroundColor: Colors.orangeAccent,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text("상품 추가", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, AdminViewModel vm, int id, String name) {
    showDialog(
      context: context,
      builder: (context) => SalesHistoryBaseDialog(
          title: "상품 삭제",
          content: "'$name' 상품을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.",
          icon: Icons.delete_sweep_rounded,
          iconColor: Colors.redAccent,
          subTextColor: Colors.red[300]!,
          isDangerDialog: true,
          onConfirm: () async {
            await vm.deleteProduct(id);
            if (context.mounted) {
              context.read<ProductViewModel>().setProducts(vm.products);
              Navigator.pop(context);
            }
          }
      )
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final newController = TextEditingController();
    final confirmPwController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => SalesHistoryBaseDialog(
        title: "비밀번호 변경",
        content: "새로운 비밀번호를 입력해주세요.",
        icon: Icons.password_rounded,
        iconColor: Colors.orangeAccent,
        customContent: Column( // SalesHistoryBaseDialog에 customContent가 있다면 활용
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              enableInteractiveSelection: false,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 20, letterSpacing: 8),
              decoration: _inputDecoration("새 비밀번호 (4자리)", Icons.vpn_key_outlined),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPwController,
              obscureText: false,
              keyboardType: TextInputType.number,
              maxLength: 4,
              enableInteractiveSelection: false,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 20, letterSpacing: 8),
              decoration: _inputDecoration("비밀번호 확인", Icons.check),
            ),
          ],
        ),
        onConfirm: () async {
          final authVm = context.read<AdminAuthViewModel>();
          String newPw = newController.text.trim();
          String confirmPw = confirmPwController.text.trim();
          if (newPw.isEmpty || confirmPw.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("사용할 비밀번호를 입력해주세요.")),
            );
            return;
          }
          if (newPw.length != 4) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("비밀번호는 반드시 4자리여야 합니다."), backgroundColor: Colors.redAccent),
            );
            return;
          }
          bool success = await authVm.updatePassword(newPw, confirmPw);
          if (context.mounted) {
            if (success) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("비밀번호가 성공적으로 변경되었습니다.")),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("두 입력칸 모두 비밀번호를 동일하게 입력해주세요"), backgroundColor: Colors.redAccent,),
              );
            }
          }
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 18, color: AppColors.mainColor, fontWeight: FontWeight.w900),
      prefixIcon: Icon(icon, size: 22),
      filled: true,
      fillColor: const Color(0xFFF1F3F5),
      counterText: "",
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.mainColor, width: 1.5),
      ),
    );
  }
}