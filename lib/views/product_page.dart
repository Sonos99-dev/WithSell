import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:project/viewmodels/product_view_model.dart';
import 'package:project/viewmodels/sales_history_view_model.dart';
import 'package:project/views/app_color.dart';
import 'package:provider/provider.dart';

class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  Color _hexToColor(String hexCode) {
    try {
      hexCode = hexCode.replaceAll('#', '');
      if (hexCode.length == 6) {
        hexCode = 'FF' + hexCode;
      }
      return Color(int.parse('0x$hexCode'));
    } catch (e) {
      return Colors.grey; // 변환 실패 시 기본색
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductViewModel>();
    final products = vm.products; //

    return Padding(
      padding: EdgeInsets.only(top: 20, left: 5, right: 5, bottom: 10),
      child: Scaffold(
        body: products.isEmpty
            ? Center(child: Text("상품이 없습니다.\n관리자 페이지를 통해 상품을 등록하고 불러와 보세요", style: TextStyle(fontSize: 30, color: Colors.black87), textAlign: TextAlign.center,))
            : GridView.builder(
          padding: EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
            MediaQuery.of(context).orientation == Orientation.landscape
                ? 2
                : 1,
            childAspectRatio: 1.6,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (_, index) {
            final p = products[index];
            final quantity = vm.getQuantity(p.productNumber);
            final totalPrice = vm.getTotalPriceWithDiscount(p.productNumber);
            final discountAmount = vm.getDiscountAmount(p.productNumber);
            final Color borderColor = _hexToColor(p.borderColor).withOpacity(0.8);
            final Color textColor = _hexToColor(p.borderColor);

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: borderColor,
                  width: 7
                )
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Product info View
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              p.name,
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                    color: Color(0x33000000),
                                  ),
                                ],
                              ),
                              maxLines: 3,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "가격: ${p.price}원",
                              style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: borderColor),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  iconSize: 80,
                                  color: Colors.blueAccent,
                                  onPressed: () {
                                    if (quantity > 0) {
                                      vm.setQuantity(
                                          p.productNumber, quantity - 1);
                                    }
                                  },
                                ),
                                Text(
                                  "$quantity",
                                  style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  iconSize: 80,
                                  icon: Icon(Icons.add),
                                  color: Colors.redAccent,
                                  onPressed: () {
                                    vm.setQuantity(
                                        p.productNumber, quantity + 1);
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                                children: [
                                  TextSpan(
                                    text: "할인 된 금액: ",
                                    style: TextStyle(
                                      color: Colors.grey
                                    )
                                  ),
                                  TextSpan(
                                      text: " $discountAmount",
                                      style: TextStyle(
                                          fontSize: 25,
                                          color: Colors.black54
                                      )
                                  ),
                                  TextSpan(
                                      text: " 원"
                                  )
                                ],
                              ),
                            ),
                            SizedBox(height: 5),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black, // 기본 색(나머지)
                                ),
                                children: [
                                  const TextSpan(
                                    text: "총 금액: ",
                                  ),
                                  TextSpan(
                                    text: "$totalPrice",
                                    style: TextStyle(
                                      fontSize: 35,
                                      color: textColor
                                    )
                                  ),
                                  TextSpan(
                                    text: " 원"
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
      
                    // img
                    Expanded(
                      flex: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: p.imgUrl.isNotEmpty
                            ? Image.network(
                          p.imgUrl,
                          fit: BoxFit.cover,
                        )
                            : Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.image,
                              size: 50, color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Visibility(
          visible: products.isNotEmpty && vm.getTotalCartPrice() != 0,
          child: SizedBox(
            width: 300,
            height: 100,
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.mainColor,
              foregroundColor: Colors.white,
              onPressed: () {
                _showSaveDialog(context);
              },
              label: Text(
                "계산하기",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              icon: Icon(
                Icons.calculate_rounded,
                size: 50,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    final vm = context.read<ProductViewModel>();
    final int finalTotal = vm.getTotalCartPrice();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 420,
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.close, size: 40),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Text(
                  "계산하기",
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 25,
                      color: Colors.black87,

                    ),
                    children: [
                      TextSpan(
                          text: "총 금액 "
                      ),
                      TextSpan(
                          text: "$finalTotal",
                          style: TextStyle(
                              fontSize: 35,
                              color: AppColors.mainColor,
                              fontWeight: FontWeight.bold
                          )
                      ),
                      TextSpan(
                          text: " 원"
                      )
                    ],
                  ),
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: AppColors.mainColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      try {
                        await vm.saveSelection();
                        vm.clearQuantities();
                        if (context.mounted) {
                          context.read<SalesHistoryViewModel>().loadHistory();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("판매 내역이 저장되었습니다."),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("저장 실패: $e"), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: Text(
                      "판매 내역 저장하기",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 4,
                            color: Color(0x55000000),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
