import 'package:flutter/material.dart';
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
  String? selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesHistoryViewModel>().loadHistory();
    });
  }

  Map<String, List<dynamic>> _groupHistoryByDate(List<dynamic> history) {
    Map<String, List<dynamic>> grouped = {};
    for (var record in history) {
      String dateKey = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.parse(record['date']));
      if (grouped[dateKey] == null) grouped[dateKey] = [];
      grouped[dateKey]!.add(record);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SalesHistoryViewModel>();
    final groupedData = _groupHistoryByDate(vm.history);
    final sortedDates = groupedData.keys.toList();

    if (selectedDate != null && !sortedDates.contains(selectedDate)) {
      selectedDate = sortedDates.isNotEmpty ? sortedDates.first : null;
    } else if (selectedDate == null && sortedDates.isNotEmpty) {
      selectedDate = sortedDates.first;
    }

    final displayRecords = selectedDate != null
        ? groupedData[selectedDate!] ?? []
        : [];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "판매 내역",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: AppColors.mainColor,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
            onPressed: () => _showDeleteDateDialog(context, vm, selectedDate!),
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        value: selectedDate,
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.mainColor,
                          size: 30,
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        items: sortedDates
                            .map(
                              (String date) => DropdownMenuItem(
                                value: date,
                                child: Text(date),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => selectedDate = val),
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
                                      fontWeight: FontWeight.bold,
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
                                        fontWeight: FontWeight.bold,
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
                                                    fontWeight: FontWeight.bold,
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Colors.redAccent,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "판매 내역 삭제 ($salesNumber번)",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "해당 판매 기록을 영구히 삭제하시겠습니까?\n이 작업은 취소할 수 없습니다.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red[400],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 35),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red[200]!),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () async {
                        await vm.deleteHistory(salesNumber);
                        final newGroupedData = _groupHistoryByDate(vm.history);
                        final newSortedDates = newGroupedData.keys.toList();
                        setState(() {
                          if (!newSortedDates.contains(selectedDate)) {
                            selectedDate = newSortedDates.isNotEmpty
                                ? newSortedDates.first
                                : null;
                          }
                        });
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text(
                        "삭제하기",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.red[400],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "취소",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
  }

  // 특정 날짜 삭제 확인 다이얼로그
  void _showDeleteDateDialog(
    BuildContext context,
    SalesHistoryViewModel vm,
    String date,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Colors.redAccent,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "날짜 전체 삭제",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "[$date]\n해당 날짜의 모든 판매 기록을 삭제합니다.\n정말로 진행하시겠습니까?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red[400],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 35),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red[200]!),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () async {
                        await vm.deleteHistoryByDate(date);
                        setState(() {
                          selectedDate = null;
                        });
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text(
                        "날짜 삭제",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.red[400],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "취소",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
  }

  void _showCancelConfirmDialog(
      BuildContext context,
      SalesHistoryViewModel vm,
      int salesNumber,
      ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.undo_rounded,
                  color: Colors.orange,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "결제 취소 처리",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "해당 내역을 결제 취소 상태로 변경하시겠습니까?\n내역은 유지되지만 매출 합계에서 제외됩니다.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 35),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        elevation: 5,
                        shadowColor: Colors.orangeAccent.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        vm.updateCancelStatus(salesNumber, true);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("결제가 취소되었습니다.")),
                        );
                      },
                      child: const Text(
                        "결제 취소",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.black38),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "돌아가기",
                        style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.bold),
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
  }

  void _showRestoreConfirmDialog(
      BuildContext context,
      SalesHistoryViewModel vm,
      int salesNumber,
      ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                child: const Icon(Icons.restore_rounded, color: Colors.blue, size: 50),
              ),
              const SizedBox(height: 24),
              const Text("결제 내역 복구", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                "취소된 내역을 다시 정상 판매 상태로\n복구하시겠습니까?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 35),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        foregroundColor: Colors.white,
                        elevation: 5,
                        shadowColor: AppColors.mainColor.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () async {
                        await vm.updateCancelStatus(salesNumber, false);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("판매 내역이 복구되었습니다."))
                        );
                      },
                      child: const Text("내역 복구", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.black38),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("돌아가기", style: TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}
