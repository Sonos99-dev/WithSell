import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:project/viewmodels/admin_view_model.dart';
import 'package:project/views/app_color.dart';
import 'package:provider/provider.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _colorController = TextEditingController(text: "#000000");
  final _discountPriceController = TextEditingController();
  final _discountQuantityController = TextEditingController();

  Color _selectedColor = Colors.red;
  bool _isDiscountEnabled = false; // 할인 설정 여부 상태 변수

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테두리 색상 선택'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              String hexCode = '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';
              _colorController.text = hexCode;
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("새 상품 등록", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.mainColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_nameController, "상품명", Icons.shopping_bag),
              _buildTextField(_priceController, "기본 가격", Icons.attach_money, isNumber: true),

              // 테두리 색상 선택
              GestureDetector(
                onTap: _pickColor,
                child: AbsorbPointer(
                  child: _buildTextField(
                    _colorController,
                    "테두리 색상 (클릭하여 선택)",
                    Icons.color_lens,
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(10),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),

              const Divider(height: 30),

              // 할인 설정 체크박스
              Row(
                children: [
                  Checkbox(
                    value: _isDiscountEnabled,
                    activeColor: AppColors.mainColor,
                    onChanged: (value) {
                      setState(() {
                        _isDiscountEnabled = value ?? false;
                        if (!_isDiscountEnabled) {
                          _discountPriceController.clear();
                          _discountQuantityController.clear();
                        }
                      });
                    },
                  ),
                  const Text("할인 혜택 적용하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),

              // 체크박스 클릭 시에만 필드 노출
              if (_isDiscountEnabled) ...[
                const SizedBox(height: 10),
                _buildTextField(_discountQuantityController, "할인 적용 개수 (예: 3)", Icons.onetwothree, isNumber: true),
                _buildTextField(_discountPriceController, "할인 시 개당 가격", Icons.discount, isNumber: true),
              ],

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.mainColor),
                  onPressed: _submitForm,
                  child: const Text("상품 등록하기", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, Widget? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          border: const OutlineInputBorder(),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        // 할인 필드가 아닐 때만 필수값 검사 (할인 필드는 선택 사항이므로 validator 제외 혹은 조건부 적용)
        validator: (value) {
          if (!_isDiscountEnabled && (controller == _discountPriceController || controller == _discountQuantityController)) {
            return null;
          }
          if (value == null || value.isEmpty) return "필수 입력 항목입니다.";
          return null;
        },
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final adminVm = context.read<AdminViewModel>();

      // 할인 설정이 꺼져있거나 입력이 비어있으면 0으로 처리
      int dPrice = 0;
      int dQty = 0;

      if (_isDiscountEnabled) {
        dPrice = int.tryParse(_discountPriceController.text) ?? 0;
        dQty = int.tryParse(_discountQuantityController.text) ?? 0;
      }

      await adminVm.addProduct(
        name: _nameController.text,
        price: int.parse(_priceController.text),
        borderColor: _colorController.text,
        discountPrice: dPrice,
        discountQuantity: dQty,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("상품이 성공적으로 등록되었습니다.")));
      }
    }
  }
}