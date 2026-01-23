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
      String dateKey = DateFormat('yyyy-MM-dd').format(DateTime.parse(record['date']));
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

    final displayRecords = selectedDate != null ? groupedData[selectedDate!] ?? [] : [];


    return Scaffold(
      backgroundColor: Colors.grey[50], // 배경색을 연한 그레이로 변경하여 카드 부각
      appBar: AppBar(
        title: const Text("판매 내역", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: AppColors.mainColor,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
            onPressed: () => _showDeleteDateDialog(context, vm, selectedDate!),
          )
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.history.isEmpty
          ? const Center(child: Text("판매 내역이 없습니다.", style: TextStyle(fontSize: 22, color: Colors.grey)))
          : Column(
        children: [
          // 1. 날짜 선택 영역 (기존 스타일 유지하되 여백 조정)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedDate,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: AppColors.mainColor, size: 30),
                  style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                  items: sortedDates.map((String date) => DropdownMenuItem(value: date, child: Text(date))).toList(),
                  onChanged: (val) => setState(() => selectedDate = val),
                ),
              ),
            ),
          ),

          // 2. 판매 기록 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: displayRecords.length,
              itemBuilder: (context, index) {
                final record = displayRecords[index];
                final List items = record['items'];
                final DateTime time = DateTime.parse(record['date']);
                final bool isCard = record['isCardPayment'] ?? false;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border(left: BorderSide(color: isCard ? Colors.blue : Colors.orange, width: 8)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.mainDarkColor.withOpacity(0.1),
                        child: Text("${record['salesNumber']}", style: TextStyle(color: AppColors.mainDarkColor, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      title: Row(
                        children: [
                          Text(
                            "금액 ${record['totalAmount']}원",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                          ),
                          const SizedBox(width: 12),
                          // 세련된 배지 디자인
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCard ? Colors.blue[50] : Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isCard ? "카드" : "현금",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isCard ? Colors.blue[700] : Colors.orange[800]),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text("결제시각: ${DateFormat('HH:mm:ss').format(time)}", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_sweep_outlined, size: 32, color: Colors.red[300]),
                        onPressed: () => _showDeleteOneDialog(context, vm, record['salesNumber']),
                      ),
                      children: [
                        // 영수증 상세 내역 영역
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              ...items.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 20, color: AppColors.mainColor),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(item['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500))),
                                    Text("${item['quantity']}개", style: const TextStyle(fontSize: 18, color: Colors.grey)),
                                    const SizedBox(width: 15),
                                    Text("${item['totalPrice']}원", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
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

  // 1. 단일 삭제 확인 다이얼로그 (버튼 위치 변경 및 취소 강조)
  void _showDeleteOneDialog(BuildContext context, SalesHistoryViewModel vm, int salesNumber) {
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
                child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 50),
              ),
              const SizedBox(height: 24),
              Text(
                "판매 내역 삭제 ($salesNumber번)",
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: Colors.redAccent),
              ),
              const SizedBox(height: 12),
              Text(
                "해당 판매 기록을 영구히 삭제하시겠습니까?\n이 작업은 취소할 수 없습니다.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.red[400], height: 1.5),
              ),
              const SizedBox(height: 35),
              Row(
                children: [
                  // 삭제하기 버튼 (좌측으로 이동, 덜 강조됨)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red[200]!),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () async {
                        await vm.deleteHistory(salesNumber);
                        final newGroupedData = _groupHistoryByDate(vm.history);
                        final newSortedDates = newGroupedData.keys.toList();
                        setState(() {
                          if (!newSortedDates.contains(selectedDate)) {
                            selectedDate = newSortedDates.isNotEmpty ? newSortedDates.first : null;
                          }
                        });
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text("삭제하기", style: TextStyle(fontSize: 18, color: Colors.red[400], fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // 취소 버튼 (우측으로 이동, 배경색으로 강하게 강조)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200], // 혹은 AppColors.mainColor로 변경 가능
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("취소", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  // 2. 특정 날짜 삭제 확인 다이얼로그 (버튼 위치 변경 및 취소 강조)
  void _showDeleteDateDialog(BuildContext context, SalesHistoryViewModel vm, String date) {
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
                child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 50),
              ),
              const SizedBox(height: 24),
              Text(
                "날짜 전체 삭제",
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: Colors.redAccent),
              ),
              const SizedBox(height: 12),
              Text(
                "[$date]\n해당 날짜의 모든 판매 기록을 삭제합니다.\n정말로 진행하시겠습니까?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.red[400], height: 1.5),
              ),
              const SizedBox(height: 35),
              Row(
                children: [
                  // 날짜 삭제 버튼 (좌측)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color:  Colors.red[200]!),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () async {
                        await vm.deleteHistoryByDate(date);
                        setState(() {
                          selectedDate = null;
                        });
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text("날짜 삭제", style: TextStyle(fontSize: 18, color: Colors.red[400], fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // 취소 버튼 (우측, 배경색 강조)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("취소", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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