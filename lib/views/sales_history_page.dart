import 'package:flutter/material.dart';
import 'package:project/viewmodels/admin_auth_view_model.dart';
import 'package:project/views/common_snack_bar.dart';
import 'package:project/views/sales_history_base_dialog.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/sales_history_view_model.dart';
import 'app_color.dart';

class SalesHistoryPage extends StatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  State<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesHistoryViewModel>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SalesHistoryViewModel>();
    final sortedDates = vm.sortedDates;
    final currentSelectedDate = vm.selectedDate;
    final displayRecords = vm.displayRecords;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "판매 내역",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        backgroundColor: AppColors.mainColor,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
            onPressed: () => _showDeleteDateDialog(context, vm, currentSelectedDate!),
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.mainColor,))
          : vm.history.isEmpty
          ? const Center(
              child: Text(
                "판매 내역이 없습니다.",
                style: TextStyle(fontSize: 22, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentSelectedDate,
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.mainColor,
                          size: 30,
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                        items: sortedDates
                            .map(
                              (String date) => DropdownMenuItem(
                                value: date,
                                child: Text(date),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => vm.setSelectedDate(val),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: displayRecords.length,
                    itemBuilder: (context, index) {
                      final record = displayRecords[index];
                      final List items = record['items'];
                      final DateTime time = DateTime.parse(record['date']);
                      final bool isCard = record['isCardPayment'] ?? false;
                      final bool isCanceled = record['isCanceled'] ?? false;

                      return GestureDetector(
                        onLongPress: () => _showDeleteOneDialog(
                          context,
                          vm,
                          record['salesNumber'],
                        ),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isCanceled ? 0.4 : 1.0,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border(
                                left: BorderSide(
                                  color: isCanceled
                                      ? Colors.grey
                                      : (isCard ? Colors.blue : Colors.orange),
                                  width: 8,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Theme(
                              data: Theme.of(
                                context,
                              ).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: isCanceled
                                      ? Colors.grey[300]
                                      : AppColors.mainDarkColor.withOpacity(
                                          0.1,
                                        ),
                                  child: Text(
                                    "${record['salesNumber']}",
                                    style: TextStyle(
                                      color: isCanceled
                                          ? Colors.grey
                                          : AppColors.mainDarkColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      "금액 ${record['totalAmount']}원",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                        decoration: isCanceled
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCanceled
                                            ? Colors.grey[200]
                                            : (isCard
                                                  ? Colors.blue[50]
                                                  : Colors.orange[50]),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isCanceled
                                            ? "취소됨"
                                            : (isCard ? "카드" : "현금"),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: isCanceled
                                              ? Colors.grey[700]
                                              : (isCard
                                                    ? Colors.blue[700]
                                                    : Colors.orange[800]),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    isCanceled
                                        ? "결제 취소된 내역입니다"
                                        : "결제시각: ${DateFormat('a h시 m분').format(time)}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                trailing: isCanceled
                                    ? IconButton(
                                        icon: const Icon(
                                            Icons.settings_backup_restore_rounded,
                                            size: 32 ,
                                            color: Colors.blueGrey
                                        ),
                                  onPressed: () =>
                                      _showRestoreConfirmDialog(
                                          context,
                                          vm,
                                          record['salesNumber']
                                      ),
                                )
                                    : IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 32,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () =>
                                            _showCancelConfirmDialog(
                                              context,
                                              vm,
                                              record['salesNumber'],
                                            ),
                                      ),
                                children: [
                                  Container(
                                    margin: const EdgeInsets.all(16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        ...items.map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle_outline,
                                                  size: 20,
                                                  color: AppColors.mainColor,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    item['name'],
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  "${item['quantity']}개",
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(width: 15),
                                                Text(
                                                  "${item['totalPrice']}원",
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

 // 단일 삭제 확인 다이얼로그
  void _showDeleteOneDialog(
    BuildContext context,
    SalesHistoryViewModel vm,
    int salesNumber,
  ) {
    showDialog(
      context: context,
      builder: (context) => SalesHistoryBaseDialog(
          title: "판매 내역 삭제 ($salesNumber번)",
          content: "해당 판매 기록을 영구히 삭제하시겠습니까?\n이 작업은 취소할 수 없습니다",
          icon: Icons.delete_sweep_rounded,
          iconColor: Colors.redAccent,
          subTextColor: Colors.red[300]!,
          isDangerDialog: true,
          onConfirm: () async {
            _confirmAdminPassword(context, () async {
              await vm.deleteHistory(salesNumber);
              if (context.mounted) Navigator.pop(context);
            }
          );
        }
      )
    );
  }

  void _showDeleteDateDialog(
    BuildContext context,
    SalesHistoryViewModel vm,
    String date,
  ) {
    showDialog(
      context: context,
      builder: (context) => SalesHistoryBaseDialog(
          title: "날짜 전체 삭제",
          content: "[$date]\n해당 날짜의 모든 판매 기록을 삭제합니다.\n정말로 진행하시겠습니까?",
          icon: Icons.delete_sweep_rounded,
          iconColor: Colors.redAccent,
          subTextColor: Colors.red[300]!,
          isDangerDialog: true,
          onConfirm: () async {
            _confirmAdminPassword(context, () async {
              await vm.deleteHistoryByDate(date);
              if (context.mounted) Navigator.pop(context);
            }
          );
        }
      )
    );
  }

  void _showCancelConfirmDialog(
      BuildContext context,
      SalesHistoryViewModel vm,
      int salesNumber,
      ) {
    showDialog(
      context: context,
      builder: (context) => SalesHistoryBaseDialog(
          title: "결제 취소 처리",
          content: "해당 내역을 결제 취소 상태로 변경하시겠습니까?\n내역은 유지되지만 매출 합계에서 제외됩니다.",
          icon: Icons.undo_rounded,
          iconColor: Colors.orange,
          yesText: "결제 취소",
          noText: "돌아가기",
          onConfirm: () async {
            vm.updateCancelStatus(salesNumber, true);
            if (context.mounted) Navigator.pop(context);
            CommonSnackBar.show(context, message: "결제가 취소되었습니다.");
          }
      )
    );
  }

  void _showRestoreConfirmDialog(
      BuildContext context,
      SalesHistoryViewModel vm,
      int salesNumber,
      ) {
    showDialog(
      context: context,
      builder: (context) => SalesHistoryBaseDialog(
          title: "결제 내역 복구",
          content: "취소된 내역을 다시 판매 완료 상태로\n복구하시겠습니까?",
          icon: Icons.restore_rounded,
          iconColor: Colors.blue,
          yesText: "내역 복구",
          noText: "돌아가기",
          onConfirm: () async {
            vm.updateCancelStatus(salesNumber, false);
            if (context.mounted) Navigator.pop(context);
            CommonSnackBar.show(context, message: "판매 내역이 복구되었습니다.");
          }
      )
    );
  }

  void _confirmAdminPassword(BuildContext context, Function onSuccess) {
    final TextEditingController pwController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => SalesHistoryBaseDialog(
        title: "관리자 인증",
        content: "삭제 권한 확인을 위해 비밀번호를 입력해주세요.",
        icon: Icons.lock_outline,
        iconColor: Colors.orange,
        customContent: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 15),
            TextField(
              controller: pwController,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "비밀번호 4자리",
                filled: true,
                fillColor: Colors.grey[100],
                counterText: "",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        onConfirm: () {
          final authVm = context.read<AdminAuthViewModel>();
          if (authVm.checkPassword(pwController.text)) {
            Navigator.pop(context);
            onSuccess();
          } else {
            CommonSnackBar.show(context, message: "비밀번호가 일치하지 않습니다.", isError: true);
          }
        },
      ),
    );
  }
}
