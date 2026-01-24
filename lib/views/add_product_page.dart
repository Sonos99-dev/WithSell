import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:project/models/product_model.dart'; // 모델 임포트 추가
import 'package:project/viewmodels/admin_view_model.dart';
import 'package:project/views/app_color.dart';
import 'package:provider/provider.dart';

class AddProductPage extends StatefulWidget {
  final ProductModel? product; // 수정 시 데이터를 받기 위한 변수 추가

  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  // 수정 여부 판단 변수
  bool get isEditing => widget.product != null;

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _colorController;
  late TextEditingController _discountPriceController;
  late TextEditingController _discountQuantityController;
  late TextEditingController _imgUrlController;

  Color _selectedColor = Colors.red;
  bool _isDiscountEnabled = false;

  @override
  void initState() {
    super.initState();

    // 1. 컨트롤러 및 초기값 설정 (수정 모드일 경우 기존 데이터 채우기)
    _nameController = TextEditingController(text: widget.product?.name ?? "");
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? "");
    _colorController = TextEditingController(text: widget.product?.borderColor ?? "#000000");
    _discountPriceController = TextEditingController(text: isEditing ? widget.product?.discountPrice.toString() : "");
    _discountQuantityController = TextEditingController(text: isEditing ? widget.product?.discountQuantity.toString() : "");
    _imgUrlController = TextEditingController(text: widget.product?.imgUrl ?? "");

    // 2. 초기 색상 및 할인 체크박스 상태 설정
    if (isEditing) {
      _selectedColor = _hexToColor(widget.product!.borderColor);
      // 할인가가 0보다 크면 체크박스 활성화로 간주
      _isDiscountEnabled = widget.product!.discountQuantity > 0;
    }
  }

  // 헥사코드를 Color 객체로 변환
  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
    } catch (e) {
      return Colors.red;
    }
  }

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
        // 제목 동적 변경
        title: Text(isEditing ? "상품 정보 수정" : "새 상품 등록",
            style: const TextStyle(color: Colors.white)),
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
              _buildTextField(_imgUrlController, "이미지 URL (Firebase Storage 등)", Icons.image),

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

              if (_isDiscountEnabled) ...[
                const SizedBox(height: 10),
                _buildTextField(_discountQuantityController, "할인 적용 개수 (예: 3)", Icons.onetwothree, isNumber: true),
                _buildTextField(_discountPriceController, "갯수 충족시 할인 금액 (예: 1000)", Icons.discount, isNumber: true),
              ],

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.mainColor),
                  onPressed: _submitForm,
                  // 버튼 텍스트 동적 변경
                  child: Text(isEditing ? "수정 완료하기" : "상품 등록하기",
                      style: const TextStyle(color: Colors.white, fontSize: 18)),
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

      int dPrice = 0;
      int dQty = 0;

      if (_isDiscountEnabled) {
        dPrice = int.tryParse(_discountPriceController.text) ?? 0;
        dQty = int.tryParse(_discountQuantityController.text) ?? 0;
      }

      if (isEditing) {
        // [수정 모드]: updateProduct 호출
        await adminVm.updateProduct(
          productNumber: widget.product!.productNumber,
          name: _nameController.text,
          price: int.parse(_priceController.text),
          borderColor: _colorController.text,
          discountPrice: dPrice,
          discountQuantity: dQty,
          imgUrl: _imgUrlController.text,
        );
      } else {
        // [등록 모드]: addProduct 호출
        await adminVm.addProduct(
          name: _nameController.text,
          price: int.parse(_priceController.text),
          borderColor: _colorController.text,
          discountPrice: dPrice,
          discountQuantity: dQty,
          imgUrl: _imgUrlController.text,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isEditing ? "상품이 수정되었습니다." : "상품이 성공적으로 등록되었습니다."))
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _colorController.dispose();
    _discountPriceController.dispose();
    _discountQuantityController.dispose();
    super.dispose();
  }
}