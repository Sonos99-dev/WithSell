import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project/constants/constants.dart';
import 'package:project/models/product_category.dart';
import 'package:project/viewmodels/product_view_model.dart';
import 'package:project/viewmodels/sales_history_view_model.dart';
import 'package:project/views/app_color.dart';
import 'package:project/views/common_snack_bar.dart';
import 'package:provider/provider.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  ProductCategory _selectedCategory = ProductCategory.all;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductViewModel>();
    final filteredProducts = _selectedCategory == ProductCategory.all
        ? vm.products
        : vm.products.where((p) => p.category == _selectedCategory || p.category == ProductCategory.common).toList();

    final mq = MediaQuery.of(context);
    final size = mq.size;

    const designW = 1280.0;
    const designH = 800.0;

    final scale =
    math.min(size.width / designW, size.height / designH).clamp(0.70, 1.05);

    double s(double v) => v * scale;
    double sp(double v) => v * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(s(64) + mq.padding.top),
        child: Container(
          padding: EdgeInsets.only(top: mq.padding.top + s(8), bottom: s(8)),
          decoration: BoxDecoration(
            color: AppColors.mainColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: s(4),
                offset: Offset(0, s(2)),
              )
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: s(12)),
                  child: Row(
                    children: ProductCategory.values
                        .where((c) => c != ProductCategory.common)
                        .map((category) {
                      final isSelected = _selectedCategory == category;

                      int categoryCartCount = 0;
                      if (category == ProductCategory.all) {
                        categoryCartCount = vm.products.fold(
                          0,
                              (sum, p) => sum + vm.getQuantity(p.productNumber),
                        );
                      } else {
                        categoryCartCount = vm.products
                            .where((p) => p.category == category)
                            .fold(
                          0,
                              (sum, p) => sum + vm.getQuantity(p.productNumber),
                        );
                      }

                      return Padding(
                        padding: EdgeInsets.only(right: s(10)),
                        child: ChoiceChip(
                          showCheckmark: false,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(category.label, style: TextStyle(fontSize: sp(28)),),
                              if (categoryCartCount > 0) ...[
                                SizedBox(width: s(10)),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: s(12), vertical: s(4)),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.mainColor
                                        : Colors.redAccent,
                                    borderRadius: BorderRadius.circular(s(20)),
                                  ),
                                  child: Text(
                                    '$categoryCartCount',
                                    style: TextStyle(
                                      fontSize: sp(20),
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _selectedCategory = category);
                          },
                          selectedColor: Colors.white,
                          backgroundColor: AppColors.mainColor.withOpacity(0.8),
                          shape: StadiumBorder(
                            side: BorderSide(color: Colors.white.withOpacity(0.5)),
                          ),
                          labelStyle: TextStyle(
                            color:
                            isSelected ? AppColors.mainColor : Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: sp(22),
                          ),
                          padding: (categoryCartCount > 0)
                              ? EdgeInsets.fromLTRB(
                              s(14), s(8), s(6), s(8))
                              : EdgeInsets.symmetric(
                              horizontal: s(14), vertical: s(8)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: s(12), left: s(4)),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      vm.clearQuantities();
                    },
                    borderRadius: BorderRadius.circular(s(12)),
                    splashColor: Colors.white.withOpacity(0.3),
                    highlightColor: Colors.white.withOpacity(0.1),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: s(8), vertical: s(4)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: s(50),
                          ),
                          Text(
                            "선택 초기화",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: sp(15),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: filteredProducts.isEmpty
          ? Center(
        child: Text(
          "등록된 상품이 없습니다.",
          style: TextStyle(fontSize: sp(30)),
        ),
      )
          : LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final crossAxisCount = (w / s(520)).floor().clamp(1, 2);
          final childAspectRatio = w < 480 ? 1.8 : (w < 900 ? 1.6 : 2.10);

          return GridView.builder(
            padding: EdgeInsets.fromLTRB(s(12), s(20), s(12), s(160)),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              mainAxisSpacing: s(12),
              crossAxisSpacing: s(12),
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (_, index) {
              final p = filteredProducts[index];
              final quantity = vm.getQuantity(p.productNumber);
              final totalPrice =
              vm.getTotalPriceWithDiscount(p.productNumber);
              final discountAmount =
              vm.getDiscountAmount(p.productNumber);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(s(16)),
                  border: Border.all(
                    color: quantity > 0
                        ? AppColors.mainColor
                        : Colors.transparent,
                    width: s(5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: s(8),
                      offset: Offset(0, s(3)),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(s(16)),
                            bottomLeft: Radius.circular(s(16)),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(s(16)),
                            bottomLeft: Radius.circular(s(16)),
                          ),
                          child: p.imgUrl.isNotEmpty
                              ? CachedNetworkImage(
                            imageUrl: p.imgUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                                child: CupertinoActivityIndicator()),
                            errorWidget: (_, __, ___) =>
                            const Icon(Icons.image_not_supported,
                                color: Colors.grey),
                          )
                              : Icon(Icons.image,
                              color: Colors.grey, size: s(48)),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            s(15), s(12), s(15), s(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: TextStyle(
                                fontSize: sp(32),
                                fontWeight: FontWeight.w900,
                                color: quantity > 0
                                    ? AppColors.mainColor
                                    : Colors.black,
                                height: 1.1,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: s(4)),
                            Text(
                              "${AppFormat.won(p.price)} 원",
                              style: TextStyle(
                                fontSize: sp(30),
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (discountAmount > 0)
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: s(14),
                                          vertical: s(4)),
                                      decoration: BoxDecoration(
                                        color:
                                        const Color(0xFFFFEFF0),
                                        borderRadius:
                                        BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        "할인 -${AppFormat.won(discountAmount)}원",
                                        style: TextStyle(
                                          color: const Color(
                                              0xFFE5484D),
                                          fontWeight:
                                          FontWeight.w800,
                                          fontSize: sp(17),
                                        ),
                                      ),
                                    ),
                                  ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(width: s(8)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(height: s(2)),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              "${AppFormat.won(totalPrice)}원",
                                              style: TextStyle(
                                                fontSize: sp(35),
                                                fontWeight: FontWeight.w900,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 7,),

                                Container(
                                  height: s(56),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius:
                                    BorderRadius.circular(s(15)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildCircularQtyBtn(
                                        Icons.remove,
                                        Colors.blue,
                                            () {
                                          if (quantity > 0) {
                                            vm.setQuantity(
                                                p.productNumber,
                                                quantity - 1);
                                          }
                                        },
                                        s,
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: s(15)),
                                        child: Text(
                                          "$quantity",
                                          style: TextStyle(
                                            fontSize: sp(30),
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      _buildCircularQtyBtn(
                                        Icons.add,
                                        Colors.red,
                                            () => vm.setQuantity(
                                            p.productNumber,
                                            quantity + 1),
                                        s,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Visibility(
        visible: filteredProducts.isNotEmpty && vm.getTotalCartPrice() != 0,
        child: SizedBox(
          width: size.width * 0.95,
          height: s(120),
          child: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF2E7D32),
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            onPressed: () => _showPaymentMethodDialog(context, s, sp),
            label: Text(
              "${AppFormat.won(vm.getTotalCartPrice())}원 결제하기",
              style: TextStyle(
                fontSize: sp(45),
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            icon: Icon(Icons.payment, color: Colors.white, size: s(55)),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCircularQtyBtn(
      IconData icon,
      Color color,
      VoidCallback onPressed,
      double Function(double) s,
      ) {
    final btnSize = s(56);     // 터치/시각 크기
    final radius = s(14);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: btnSize,
          height: btnSize,     // ✅ double.infinity 대신 고정
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Center(
              child: Icon(icon, color: color, size: s(28)),
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentMethodDialog(
      BuildContext context,
      double Function(double) s,
      double Function(double) sp,
      ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final w = MediaQuery.of(context).size.width;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(s(25))),
          elevation: 10,
          child: Container(
            width: math.min(w * 0.92, s(700)),
            padding: EdgeInsets.symmetric(vertical: s(10), horizontal: s(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.close, size: s(50)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Text(
                  "결제 방법",
                  style: TextStyle(
                    fontSize: sp(40),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(height: s(8)),
                Text(
                  "진행하실 결제 수단을 선택해 주세요.",
                  style: TextStyle(fontSize: sp(26), color: Colors.grey),
                ),
                SizedBox(height: s(25)),
                Row(
                  children: [
                    _buildPaymentOption(
                      context,
                      s: s,
                      sp: sp,
                      title: "현금 또는 계좌 이체",
                      subtitle: "CASH",
                      icon: Icons.monetization_on_rounded,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        _showSaveDialog(context, false, s, sp);
                      },
                    ),
                    SizedBox(width: s(12)),
                    _buildPaymentOption(
                      context,
                      s: s,
                      sp: sp,
                      title: "카드 결제",
                      subtitle: "CARD",
                      icon: Icons.credit_card_rounded,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _showSaveDialog(context, true, s, sp);
                      },
                    ),
                  ],
                ),
                SizedBox(height: s(10)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
        required double Function(double) s,
        required double Function(double) sp,
      }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: s(250),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(s(20)),
            border: Border.all(color: color.withOpacity(0.2), width: s(3)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: s(10),
                offset: Offset(0, s(4)),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: s(80), color: color),
              SizedBox(height: s(10)),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: sp(26), fontWeight: FontWeight.w900),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: sp(20),
                  fontWeight: FontWeight.w900,
                  color: color.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaveDialog(
      BuildContext context,
      bool isCardPayment,
      double Function(double) s,
      double Function(double) sp,
      ) {
    final vm = context.read<ProductViewModel>();
    final int finalTotal = vm.getTotalCartPrice();
    final selectedProducts =
    vm.products.where((p) => vm.getQuantity(p.productNumber) > 0).toList();

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

            final w = MediaQuery.of(context).size.width;

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(s(25))),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 1.0,
                  maxWidth: math.min(w * 0.95, s(600)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(s(25)),
                    border: Border(
                      left: BorderSide(
                        color: isCardPayment ? Colors.blue : Colors.orange,
                        width: s(10),
                      ),
                    ),
                    color: Colors.white,
                  ),
                  padding: EdgeInsets.fromLTRB(s(18), s(8), s(18), s(18)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "결제 영수증 확인",
                            style: TextStyle(
                              fontSize: sp(35),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: s(50)),
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
                              SizedBox(height: s(8)),
                              Text(
                                "결제 수단: ${isCardPayment ? '카드 결제 (CARD)' : '현금 결제 (CASH)'}",
                                style: TextStyle(
                                  fontSize: sp(26),
                                  color: isCardPayment ? Colors.blue : Colors.orange,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: s(15)),
                              Container(
                                padding: EdgeInsets.all(s(12)),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(s(15)),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            "품명",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: sp(28),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            "수량",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: sp(28),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            "금액",
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: sp(28),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    SizedBox(height: 8,),
                                    ...selectedProducts.map((p) {
                                      return Padding(
                                        padding: EdgeInsets.symmetric(vertical: s(5)),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    p.name,
                                                    style: TextStyle(
                                                      fontSize: sp(28),
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    "${vm.getQuantity(p.productNumber)}개",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: sp(28),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    "${AppFormat.won(vm.getTotalPriceWithDiscount(p.productNumber))}원",
                                                    textAlign: TextAlign.right,
                                                    style: TextStyle(
                                                      fontSize: sp(28),
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Divider(thickness: 0.2),
                                          ],
                                        ),
                                      );
                                    }),
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "최종 합계",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: sp(35),
                                          ),
                                        ),
                                        Text(
                                          "${AppFormat.won(finalTotal)}원",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: sp(40),
                                            color: AppColors.mainColor,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              if (!isCardPayment) ...[
                                SizedBox(height: s(20)),
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
                                      }, s, sp);
                                    },
                                    focusNode: cashFocusNode,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: sp(40),
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: "받은 금액",
                                      filled: true,
                                      floatingLabelBehavior: FloatingLabelBehavior.always,
                                      hintText: "클릭하여 현금을 입력하세요.",
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: sp(30),
                                        fontWeight: FontWeight.normal,
                                      ),
                                      fillColor: Colors.white,
                                      labelStyle: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: sp(35),
                                        color: cashFocusNode.hasFocus
                                            ? AppColors.mainColor
                                            : AppColors.mainDarkColor,
                                      ),
                                      suffixText: cashController.text.isEmpty ? "" : " 원",
                                      suffixStyle: TextStyle(
                                        fontSize: sp(40),
                                        fontWeight: FontWeight.w900,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.mainColor,
                                          width: s(3),
                                        ),
                                        borderRadius: BorderRadius.circular(s(15)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.mainColor,
                                          width: s(2),
                                        ),
                                        borderRadius: BorderRadius.circular(s(15)),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: s(16)),
                                Visibility(
                                  visible: !isAccountTransfer,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "거스름 돈",
                                        style: TextStyle(
                                          fontSize: sp(30),
                                          fontWeight: FontWeight.w900,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        "${change < 0 ? 0 : AppFormat.won(change)} 원",
                                        style: TextStyle(
                                          fontSize: sp(35),
                                          fontWeight: FontWeight.w900,
                                          color: change >= 0
                                              ? AppColors.mainColor
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: s(20)),
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
                                  borderRadius: BorderRadius.circular(s(15)),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: EdgeInsets.symmetric(vertical: s(18), horizontal: s(16)),
                                    decoration: BoxDecoration(
                                      color: (isAccountTransfer)
                                          ? AppColors.mainColor
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(s(15)),
                                      border: Border.all(
                                        color: (isAccountTransfer)
                                            ? AppColors.mainColor
                                            : Colors.grey[400]!,
                                        width: s(2.5),
                                      ),
                                      boxShadow: (isAccountTransfer)
                                          ? [
                                        BoxShadow(
                                          color: AppColors.mainColor
                                              .withOpacity(0.4),
                                          blurRadius: s(10),
                                          offset: Offset(0, s(4)),
                                        )
                                      ]
                                          : [],
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          (isAccountTransfer)
                                              ? Icons.check_circle_rounded
                                              : Icons.account_balance_wallet_outlined,
                                          color: (isAccountTransfer)
                                              ? Colors.white
                                              : AppColors.mainColor,
                                          size: s(50),
                                        ),
                                        SizedBox(width: s(12)),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "계좌 이체로 결제하기",
                                                style: TextStyle(
                                                  fontSize: sp(30),
                                                  fontWeight: FontWeight.w900,
                                                  color: (isAccountTransfer)
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                "상품 금액이 자동으로 입력됩니다",
                                                style: TextStyle(
                                                  fontSize: sp(22),
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
                              ],
                              SizedBox(height: s(12)),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: s(12)),
                      SizedBox(
                        width: double.infinity,
                        height: s(90),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mainColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(s(15))),
                            elevation: 5,
                          ),
                          onPressed: (!isCardPayment && change < 0)
                              ? null
                              : () async {
                            await vm.saveSelection(isCardPayment);
                            vm.clearQuantities();
                            if (context.mounted) {
                              context
                                  .read<SalesHistoryViewModel>()
                                  .loadHistory();
                              Navigator.pop(context);
                              CommonSnackBar.show(context,
                                  message: "결제가 정상적으로 완료되었습니다.");
                            }
                          },
                          child: Text(
                            (!isCardPayment && change < 0) ? "금액 부족" : "결제 완료 및 저장",
                            style: TextStyle(
                              fontSize: sp(35),
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
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

  void _showCashInputPad(
      BuildContext context,
      Function(int) onConfirm,
      double Function(double) s,
      double Function(double) sp,
      ) {
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
            final w = MediaQuery.of(context).size.width;

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(s(25))),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                  maxWidth: math.min(w * 0.95, s(800)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(s(18)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "현금 입력 패드",
                            style: TextStyle(
                              fontSize: sp(35),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh_rounded,
                                color: Colors.orange, size: s(70)),
                            onPressed: () => setPadState(() {
                              currentTotal = 0;
                              for (var unit in cashUnits) {
                                unit['count'] = 0;
                              }
                            }),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            vertical: s(12), horizontal: s(18)),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(s(15)),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          "${currentTotal.toString().replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (Match m) => '${m[1]},')} 원",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: sp(45),
                            fontWeight: FontWeight.w900,
                            color: AppColors.mainColor,
                          ),
                        ),
                      ),
                      SizedBox(height: s(12)),
                      Flexible(
                        child: SingleChildScrollView(
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: w < 420 ? 3 : 4,
                              mainAxisSpacing: s(12),
                              crossAxisSpacing: s(12),
                              childAspectRatio: 0.8,
                            ),
                            itemCount: cashUnits.length,
                            itemBuilder: (context, index) {
                              int count = cashUnits[index]['count'];
                              return Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(s(15)),
                                elevation: 2,
                                child: InkWell(
                                  onTap: () {
                                    setPadState(() {
                                      currentTotal +=
                                      cashUnits[index]['value'] as int;
                                      cashUnits[index]['count'] += 1;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(s(15)),
                                  splashColor:
                                  AppColors.mainColor.withOpacity(0.3),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius:
                                      BorderRadius.circular(s(15)),
                                      border: Border.all(
                                        color: count > 0
                                            ? AppColors.mainColor
                                            : Colors.grey[300]!,
                                        width: count > 0 ? s(2) : s(1),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.all(s(8)),
                                            child: Image.asset(
                                              "assets/image/${cashUnits[index]['img']}",
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (context, error, stackTrace) =>
                                                  Icon(
                                                    Icons.monetization_on,
                                                    size: s(36),
                                                    color: Colors.grey,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: double.infinity,
                                          height: s(35),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: count > 0
                                                ? AppColors.mainColor
                                                : Colors.grey[100],
                                            borderRadius: BorderRadius.only(
                                              bottomLeft:
                                              Radius.circular(s(12)),
                                              bottomRight:
                                              Radius.circular(s(12)),
                                            ),
                                          ),
                                          child: Text(
                                            "$count 개",
                                            style: TextStyle(
                                              fontSize: sp(24),
                                              fontWeight: FontWeight.w900,
                                              color: count > 0
                                                  ? Colors.white
                                                  : Colors.grey[700],
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
                      SizedBox(height: s(20)),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: s(15)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(s(15)),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "취소",
                                style: TextStyle(
                                  fontSize: sp(30),
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: s(12)),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.mainColor,
                                padding: EdgeInsets.symmetric(vertical: s(15)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(s(15)),
                                ),
                              ),
                              onPressed: () {
                                onConfirm(currentTotal);
                                Navigator.pop(context);
                              },
                              child: Text(
                                "금액 적용",
                                style: TextStyle(
                                  fontSize: sp(30),
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
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
