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

    if (selectedDate == null && sortedDates.isNotEmpty) {
      selectedDate = sortedDates.first;
    }

    final displayRecords = selectedDate != null ? groupedData[selectedDate!] ?? [] : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("판매 내역", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.mainColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.white),
            onPressed: () async {
              await vm.injectMockData();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("목업 데이터가 주입되었습니다."))
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            onPressed: () => _showDeleteAllDialog(context, vm),
          )
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.history.isEmpty
          ? const Center(child: Text("판매 내역이 없습니다.", style: TextStyle(fontSize: 20)))
          : Column(
        children: [
          // --- 1. 날짜 선택 드롭다운 영역 ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.mainColor, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedDate,
                  isExpanded: true,
                  icon: Icon(Icons.calendar_today, color: AppColors.mainColor),
                  style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                  items: sortedDates.map((String date) {
                    return DropdownMenuItem<String>(
                      value: date,
                      child: Text(date),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedDate = newValue;
                    });
                  },
                ),
              ),
            ),
          ),
          const Divider(height: 1),

          // --- 2. 선택된 날짜의 판매 기록 리스트 ---
          Expanded(
            child: displayRecords.isEmpty
                ? const Center(child: Text("해당 날짜의 내역이 없습니다."))
                : ListView.builder(
              itemCount: displayRecords.length,
              itemBuilder: (context, index) {
                final record = displayRecords[index];
                final List items = record['items'];
                final DateTime time = DateTime.parse(record['date']);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueGrey,
                      child: Text("${record['salesNumber']}", style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(
                      "총 결제: ${record['totalAmount']}원",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("판매 시각: ${DateFormat('HH:mm:ss').format(time)}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                      onPressed: () => _showDeleteOneDialog(context, vm, record['salesNumber']),
                    ),
                    children: [
                      const Divider(),
                      ...items.map((item) => ListTile(
                        title: Text(item['name']),
                        trailing: Text("${item['quantity']}개 / ${item['totalPrice']}원"),
                      )),
                      const SizedBox(height: 10),
                    ],
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
  void _showDeleteOneDialog(BuildContext context, SalesHistoryViewModel vm, int salesNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("내역 삭제 ($salesNumber번)"),
        content: const Text("이 판매 내역을 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          TextButton(
            onPressed: () {
              vm.deleteHistory(salesNumber);
              setState(() {
                if (vm.history.isEmpty) {
                  selectedDate = null;
                }
              });
              Navigator.pop(context);
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 전체 삭제 다이얼로그
  void _showDeleteAllDialog(BuildContext context, SalesHistoryViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("전체 내역 초기화"),
        content: const Text("모든 기록을 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          TextButton(
            onPressed: () {
              vm.clearAllHistory();
              setState(() {
                selectedDate = null;
              });
              Navigator.pop(context);
            },
            child: const Text("전체 삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}