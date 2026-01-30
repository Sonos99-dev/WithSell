import 'package:flutter/material.dart';
import 'package:project/models/product_category.dart';
import 'package:project/models/product_model.dart';
import 'package:project/viewmodels/admin_view_model.dart';
import 'package:project/views/app_color.dart';
import 'package:project/views/common_snack_bar.dart';
import 'package:provider/provider.dart';

class AddProductPage extends StatefulWidget {
  final ProductModel? product;

  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  bool get isEditing => widget.product != null;

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _discountPriceController;
  late TextEditingController _discountQuantityController;
  late TextEditingController _imgUrlController;
  late ProductCategory _selectedCategory;
  bool _isDiscountEnabled = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? "");
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? "");
    _discountPriceController = TextEditingController(text: isEditing ? widget.product?.discountPrice.toString() : "");
    _discountQuantityController = TextEditingController(text: isEditing ? widget.product?.discountQuantity.toString() : "");
    _imgUrlController = TextEditingController(text: widget.product?.imgUrl ?? "");
    _selectedCategory = widget.product?.category ?? ProductCategory.etc;

    if (isEditing) {
      _isDiscountEnabled = widget.product!.discountQuantity > 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 밝은 회색 배경
      appBar: AppBar(
        title: Text(isEditing ? "상품 정보 수정" : "새 상품 등록",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        backgroundColor: AppColors.mainColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("상품 정보"),
              _buildInputCard([
                _buildTextField(_nameController, "상품명", Icons.shopping_bag_outlined),
                const SizedBox(height: 16),
                _buildCategoryDropdown(),
                const SizedBox(height: 16),
                _buildTextField(_priceController, "판매 가격 (원)", Icons.payments_outlined, isNumber: true),
                const SizedBox(height: 16),
                _buildTextField(_imgUrlController, "이미지 URL", Icons.image_outlined),
              ]),

              const SizedBox(height: 24),
              _buildDiscountSection(),

              const SizedBox(height: 40),
              _buildSubmitButton(),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
    );
  }

  // 흰색 카드 배경
  Widget _buildInputCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<ProductCategory>(
      value: _selectedCategory,
      decoration: _inputDecoration("카테고리", Icons.category_outlined),
      items: ProductCategory.values.where((e) => e != ProductCategory.all).map((cat) {
        return DropdownMenuItem(value: cat, child: Text(cat.label));
      }).toList(),
      onChanged: (val) => setState(() => _selectedCategory = val!),
    );
  }

  Widget _buildDiscountSection() {
    return Container(
      decoration: BoxDecoration(
        color: _isDiscountEnabled ? Colors.orangeAccent.withOpacity(0.15) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 2,
          color: _isDiscountEnabled ? Colors.orangeAccent : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text("다량 구매 할인 적용",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: _isDiscountEnabled ? AppColors.mainColor : Colors.black)),
            subtitle: Text(_isDiscountEnabled ? "할인 혜택이 활성화되었습니다." : "할인 혜택을 설정하려면 켜주세요.", style: TextStyle(fontSize: 16),),
            value: _isDiscountEnabled,
            activeColor: AppColors.mainColor,
            onChanged: (val) => setState(() => _isDiscountEnabled = val),
          ),
          if (_isDiscountEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 12,
                  children: [
                    _buildInlineField(_discountQuantityController, "0", 60),
                    const Text("개 구매 시",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    _buildInlineField(_discountPriceController, "0", 120),
                    const Text("원 할인하기",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 문장 안에 들어갈 작은 텍스트 필드 빌더
  Widget _buildInlineField(TextEditingController controller, String hint, double width) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.mainColor
        ),
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.mainColor.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.mainColor, width: 2),
          ),
        ),
        validator: (value) {
          if (_isDiscountEnabled && (value == null || value.isEmpty)) return "";
          return null;
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, Widget? suffixIcon}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: _inputDecoration(label, icon).copyWith(suffixIcon: suffixIcon),
      validator: (value) {
        if (!_isDiscountEnabled && (controller == _discountPriceController || controller == _discountQuantityController)) return null;
        if (value == null || value.isEmpty) return "필수 입력";
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 30),
      filled: true,
      fillColor: const Color(0xFFF1F3F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      floatingLabelStyle: const TextStyle(color: AppColors.mainColor, fontWeight: FontWeight.w900, fontSize: 22),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.mainColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mainColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        onPressed: _submitForm,
        child: Text(isEditing ? "수정 완료" : "상품 등록",
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final adminVm = context.read<AdminViewModel>();
      int dPrice = _isDiscountEnabled ? (int.tryParse(_discountPriceController.text) ?? 0) : 0;
      int dQty = _isDiscountEnabled ? (int.tryParse(_discountQuantityController.text) ?? 0) : 0;

      if (isEditing) {
        await adminVm.updateProduct(
          productNumber: widget.product!.productNumber,
          name: _nameController.text,
          price: int.parse(_priceController.text),
          discountPrice: dPrice,
          discountQuantity: dQty,
          imgUrl: _imgUrlController.text,
          category: _selectedCategory,
        );
      } else {
        await adminVm.addProduct(
          name: _nameController.text,
          price: int.parse(_priceController.text),
          discountPrice: dPrice,
          discountQuantity: dQty,
          imgUrl: _imgUrlController.text,
          category: _selectedCategory,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        CommonSnackBar.show(context, message: isEditing ? "상품이 수정되었습니다." : "상품이 성공적으로 등록되었습니다.");
      }
    }
  }
}