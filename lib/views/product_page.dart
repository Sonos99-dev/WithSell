import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductViewModel>();
    final products = vm.products;

    return Padding(
      padding: EdgeInsets.only(top: 20, left: 5, right: 5, bottom: 10),
      child: Scaffold(
        body: products.isEmpty
            ? Center(child: Text("상품이 없습니다.\n관리자 페이지를 통해 상품을 등록하고 불러와 보세요", style: TextStyle(fontSize: 30, color: Colors.black87), textAlign: TextAlign.center,))
            : GridView.builder(
          padding: EdgeInsets.only(
            top: 30,
            left: 12,
            right: 12,
            bottom: 70,
          ),
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
                                  color: Colors.black,
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
                      child: Container(color: Colors.black,),
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
                _showPaymentMethodDialog(context);
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

  void _showPaymentMethodDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 10,
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Text(
                  "결제 방법",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
                ),
                const SizedBox(height: 10),
                const Text("진행하실 결제 수단을 선택해 주세요.",
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
                const SizedBox(height: 35),
                Row(
                  children: [
                    _buildPaymentOption(
                      context,
                      title: "현금 또는 계좌 이체",
                      subtitle: "CASH",
                      icon: Icons.monetization_on_rounded,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        _showSaveDialog(context, false);
                      },
                    ),
                    const SizedBox(width: 20),
                    _buildPaymentOption(
                      context,
                      title: "카드 결제",
                      subtitle: "CARD",
                      icon: Icons.credit_card_rounded,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _showSaveDialog(context, true);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption(BuildContext context,
      {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2), width: 2),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: color),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color.withOpacity(0.6))),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaveDialog(BuildContext context, bool isCardPayment) {
    final vm = context.read<ProductViewModel>();
    final int finalTotal = vm.getTotalCartPrice();
    final selectedProducts = vm.products.where((p) => vm.getQuantity(p.productNumber) > 0).toList();

    final TextEditingController cashController = TextEditingController();
    final FocusNode cashFocusNode = FocusNode();


    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isAccountTransfer = cashController.text == finalTotal.toString();
            cashFocusNode.addListener(() {
              if (context.mounted) setDialogState(() {});
            });
            int receivedAmount = int.tryParse(cashController.text) ?? 0;
            int change = receivedAmount - finalTotal;

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                  maxWidth: 500,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border(
                        left: BorderSide(
                            color: isCardPayment ? Colors.blue : Colors.orange,
                            width: 10)),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("결제 영수증 확인",
                              style: TextStyle(
                                  fontSize: 30, fontWeight: FontWeight.w900)),
                          IconButton(
                            icon: const Icon(Icons.close, size: 35),
                            onPressed: () {
                              cashFocusNode.dispose();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              Text(
                                "결제 수단: ${isCardPayment ? '카드 결제 (CARD)' : '현금 결제 (CASH)'}",
                                style: TextStyle(
                                    fontSize: 20,
                                    color: isCardPayment
                                        ? Colors.blue
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  children: [
                                    const Row(
                                      children: [
                                        Expanded(flex: 3, child: Text("품명", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                                        Expanded(flex: 1, child: Text("수량", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                                        Expanded(flex: 2, child: Text("금액", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    ...selectedProducts.map((p) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          children: [
                                            Expanded(flex: 3, child: Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500))),
                                            Expanded(flex: 1, child: Text("${vm.getQuantity(p.productNumber)}개", textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.grey))),
                                            Expanded(flex: 2, child: Text("${vm.getTotalPriceWithDiscount(p.productNumber)}원", textAlign: TextAlign.right, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    const Divider(height: 30),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("최종 합계", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
                                        Text("$finalTotal원", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 30, color: AppColors.mainColor)),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              if (!isCardPayment) ...[
                                const SizedBox(height: 25),
                                Visibility(
                                  visible: !isAccountTransfer,
                                  child: TextField(
                                    controller: cashController,
                                    readOnly: true,
                                    onTap: () {
                                      _showCashInputPad(context, (totalAmount) {
                                        setDialogState(() {
                                          cashController.text = totalAmount.toString();
                                        });
                                      });
                                    },
                                    focusNode: cashFocusNode,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: "받은 금액",
                                      filled: true,
                                      floatingLabelBehavior: FloatingLabelBehavior.always,
                                      hintText: "클릭하여 현금을 입력하세요.",
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 20,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      fillColor: Colors.white,
                                      labelStyle: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: cashFocusNode.hasFocus
                                              ? AppColors.mainColor
                                              : AppColors.mainDarkColor
                                      ),
                                      suffixText: cashController.text.isEmpty ? "" : " 원",
                                      suffixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                      focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColors.mainColor,
                                              width: 3),
                                          borderRadius: BorderRadius.circular(15)),
                                      enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColors.mainColor,
                                              width: 2),
                                          borderRadius: BorderRadius.circular(15)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                InkWell(
                                  onTap: () {
                                    setDialogState(() {
                                      if (isAccountTransfer) {
                                        cashController.clear();
                                      } else {
                                        cashController.text = finalTotal.toString();
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(15),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: (isAccountTransfer)
                                          ? AppColors.mainColor
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: (isAccountTransfer)
                                            ? AppColors.mainColor
                                            : Colors.grey[400]!,
                                        width: 2.5,
                                      ),
                                      boxShadow: (isAccountTransfer)
                                          ? [BoxShadow(color: AppColors.mainColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
                                          : [],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          (isAccountTransfer)
                                              ? Icons.check_circle_rounded
                                              : Icons.account_balance_wallet_outlined,
                                          color: (isAccountTransfer) ? Colors.white : AppColors.mainColor,
                                          size: 30,
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "계좌 이체로 결제하기",
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: (isAccountTransfer) ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                "상품 금액이 자동으로 입력됩니다",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: (isAccountTransfer)
                                                      ? Colors.white.withOpacity(0.8)
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("거스름돈", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    Text(
                                      "${change < 0 ? 0 : change} 원",
                                      style: TextStyle(
                                          fontSize: 35,
                                          fontWeight: FontWeight.w900,
                                          color: change >= 0
                                              ? AppColors.mainColor
                                              : Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 65,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mainColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            elevation: 5,
                          ),
                          onPressed: (!isCardPayment && change < 0)
                              ? null
                              : () async {
                            await vm.saveSelection(isCardPayment);
                            vm.clearQuantities();
                            if (context.mounted) {
                              context.read<SalesHistoryViewModel>().loadHistory();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("결제가 정상적으로 완료되었습니다.")));
                            }
                          },
                          child: Text(
                              (!isCardPayment && change < 0)
                                  ? "금액 부족"
                                  : "결제 완료 및 저장",
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCashInputPad(BuildContext context, Function(int) onConfirm) {
    int currentTotal = 0;

    final List<Map<String, dynamic>> cashUnits = [
      {'value': 50000, 'img': 'ic_bill_50000_won.png', 'count': 0},
      {'value': 10000, 'img': 'ic_bill_10000_won.png', 'count': 0},
      {'value': 5000, 'img': 'ic_bill_5000_won.png', 'count': 0},
      {'value': 1000, 'img': 'ic_bill_1000_won.png', 'count': 0},
      {'value': 500, 'img': 'ic_coin_500_won.png', 'count': 0},
      {'value': 100, 'img': 'ic_coin_100_won.png', 'count': 0},
      {'value': 50, 'img': 'ic_coin_50_won.png', 'count': 0},
      {'value': 10, 'img': 'ic_coin_10_won.png', 'count': 0},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPadState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                  maxWidth: 650,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("현금 입력 패드", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: Colors.orange, size: 35),
                            onPressed: () => setPadState(() {
                              currentTotal = 0;
                              for (var unit in cashUnits) { unit['count'] = 0; }
                            }),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          "${currentTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} 원",
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 35, fontWeight: FontWeight.w900, color: AppColors.mainColor),
                        ),
                      ),

                      const SizedBox(height: 15),
                      Flexible(
                        child: SingleChildScrollView(
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: cashUnits.length,
                            itemBuilder: (context, index) {
                              int count = cashUnits[index]['count'];
                              return Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                elevation: 2,
                                child: InkWell(
                                  onTap: () {
                                    setPadState(() {
                                      currentTotal += cashUnits[index]['value'] as int;
                                      cashUnits[index]['count'] += 1;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(15),
                                  splashColor: AppColors.mainColor.withOpacity(0.3),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: count > 0 ? AppColors.mainColor : Colors.grey[300]!,
                                        width: count > 0 ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Image.asset(
                                              "assets/image/${cashUnits[index]['img']}",
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.monetization_on, size: 40, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: double.infinity,
                                          height: 30,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: count > 0 ? AppColors.mainColor : Colors.grey[100],
                                            borderRadius: const BorderRadius.only(
                                              bottomLeft: Radius.circular(12),
                                              bottomRight: Radius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            "$count 개",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: count > 0 ? Colors.white : Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text("취소", style: TextStyle(fontSize: 20, color: Colors.grey)),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.mainColor,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              onPressed: () {
                                onConfirm(currentTotal);
                                Navigator.pop(context);
                              },
                              child: const Text("금액 적용",
                                  style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
