import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/constants/constants.dart';
import 'package:project/viewmodels/sales_history_view_model.dart';
import 'package:project/viewmodels/settlement_view_model.dart';
import 'package:project/views/app_color.dart';
import 'package:project/views/common_snack_bar.dart';
import 'package:provider/provider.dart';

class SettlementPage extends StatefulWidget {
  const SettlementPage({super.key});

  @override
  State<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends State<SettlementPage>
    with SingleTickerProviderStateMixin {
  bool _isDashboardExpanded = true;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  bool _isOverlayLoading = false; // 로딩 상태 (상단 버튼 차단 및 오버레이용)
  bool _isManualSync = false; // 상단 버튼을 눌렀을 때만 중앙 아이콘을 띄우기 위한 플래그

  final List<Color> _productColors = [
    const Color(0xFF0072B2),
    const Color(0xFF56B4E9),
    const Color(0xFF009E73),
    const Color(0xFFCC79A7),
    const Color(0xFF374151),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );
    _animationController.value = 1.0;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final historyVm = context.read<SalesHistoryViewModel>();
      final vm = context.read<SettlementViewModel>();
      vm.updateMyLocalData(historyVm.history);

      // ✅ 초기 리뷰 로드(선택 날짜 기준)
      await vm.loadReviews();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDashboard() {
    if (_isOverlayLoading) return;
    setState(() {
      _isDashboardExpanded = !_isDashboardExpanded;
      if (_isDashboardExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _handleSync(SettlementViewModel vm, List<dynamic> history,
      {required bool isManual}) async {
    if (_isOverlayLoading) return;

    setState(() {
      _isOverlayLoading = true;
      _isManualSync = isManual; // 버튼 클릭이면 true, 리프레시면 false
    });

    try {
      await vm.syncWithCloud(history);
      if (mounted) {
        CommonSnackBar.show(context, message: "데이터가 동기화되었습니다.");
      }
    } catch (e) {
      if (mounted) {
        CommonSnackBar.show(context, message: e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOverlayLoading = false;
          _isManualSync = false;
        });
      }
    }
  }

  Widget _buildSyncLoadingOverlay() {
    if (!_isOverlayLoading) return const SizedBox.shrink();

    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: Colors.black.withOpacity(0.02),
          child: _isManualSync
              ? Center(
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 1)
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.mainColor),
              ),
            ),
          )
              : const SizedBox
              .shrink(), // 🔥 리프레시 때는 터치만 막고 아이콘은 안 띄움
        ),
      ),
    );
  }

  Future<void> _openReviewDialog(BuildContext context) async {
    final vm = context.read<SettlementViewModel>();
    final date = vm.selectedDate;
    if (date == null) return;

    final existing = vm.myReviewForSelectedDate;

    final locationCtrl = TextEditingController(text: existing?.location ?? "");
    final authorCtrl = TextEditingController(text: existing?.author ?? "");
    final contentCtrl = TextEditingController(text: existing?.content ?? "");

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            existing == null ? "판매 소감 등록" : "판매 소감 재작성",
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("선택 날짜: $date", style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: "판매 장소")),
                TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: "작성자")),
                TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(labelText: "판매 소감"),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
            ElevatedButton(
              onPressed: () async {
                try {
                  await vm.upsertMyReview(
                    location: locationCtrl.text,
                    author: authorCtrl.text,
                    content: contentCtrl.text,
                  );
                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) {
                    CommonSnackBar.show(
                      context,
                      message: existing == null ? "소감이 등록되었습니다." : "소감이 수정되었습니다.",
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    CommonSnackBar.show(context, message: "실패: $e", isError: true);
                  }
                }
              },
              child: Text(existing == null ? "등록" : "수정"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteReviewDialog(BuildContext context) async {
    final vm = context.read<SettlementViewModel>();
    final date = vm.selectedDate;
    if (date == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("판매 소감 삭제", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text("$date 소감을 삭제할까요?\n삭제하면 복구할 수 없습니다."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("삭제"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await vm.deleteMyReviewForSelectedDate();
      if (context.mounted) {
        CommonSnackBar.show(context, message: "소감이 삭제되었습니다.");
      }
    } catch (e) {
      if (context.mounted) {
        CommonSnackBar.show(context, message: "삭제 실패: $e", isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyVm = context.watch<SalesHistoryViewModel>();
    final settlementVm = context.watch<SettlementViewModel>();
    final summary = settlementVm.getFilteredSummary();
    final sortedDates = settlementVm.allAvailableDates;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("정산 기록",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
        backgroundColor: AppColors.mainColor,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white),
            // 로딩 중에는 버튼 클릭 방지
            onPressed: _isOverlayLoading
                ? null
                : () => _handleSync(settlementVm, historyVm.history,
                isManual: true),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ✅ FAB 추가 (추가)
      floatingActionButton: settlementVm.isCurrentDeviceSelected
          ? FloatingActionButton.extended(
        backgroundColor: AppColors.mainColor,
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: Text(
          settlementVm.myReviewForSelectedDate == null ? "판매 소감" : "판매 소감 재작성",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        onPressed: _isOverlayLoading ? null : () => _openReviewDialog(context),
      ) : null,

      body: Stack(
        children: [
          Column(
            children: [
              _buildFilterBar(settlementVm, sortedDates),
              _buildCollapsibleDashboard(summary, settlementVm.selectedDate),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.mainColor,
                  backgroundColor: Colors.white,
                  onRefresh: () => _handleSync(settlementVm, historyVm.history,
                      isManual: false),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const SizedBox(height: 15),
                      _buildSectionHeader("상세 판매 품목", Icons.list_alt),
                      _buildCompactProductTable(summary),
                      const SizedBox(height: 20),

                      // ✅ 판매 소감 섹션 추가 (추가)
                      _buildSectionHeader("판매 소감", Icons.rate_review),
                      _buildReviewList(settlementVm),
                      const SizedBox(height: 110), // FAB 공간
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildSyncLoadingOverlay(), // 터치 차단 및 버튼 클릭용 로딩 레이어
        ],
      ),
    );
  }

  Widget _buildReviewList(SettlementViewModel vm) {
    if (vm.isReviewLoading) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainColor),
          ),
        ),
      );
    }

    final list = vm.reviews;
    if (list.isEmpty) return _buildEmptyBox("등록된 소감이 없습니다.");

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        children: List.generate(list.length, (i) {
          final r = list[i];
          final timeText = DateFormat('M월 d일, h시 m분 a').format(r.createdAt); //

          // ✅ 현재 기기 선택 상태에서만 "내 소감(선택 날짜)"에 대해 삭제 허용
          final canDelete = vm.isCurrentDeviceSelected &&
              vm.selectedDate != null &&
              r.date == vm.selectedDate;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onLongPress: canDelete ? () => _showDeleteReviewDialog(context) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: i == list.length - 1
                      ? null
                      : Border(bottom: BorderSide(color: Colors.grey[100]!)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${r.location} · ${r.author}",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.mainColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          "$timeText",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r.content,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFilterBar(SettlementViewModel vm, List<String> dates) {
    return Container(
      color: AppColors.mainColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
              child: _buildDropdown(vm.selectedDate, dates,
                      (v) => vm.setSelectedDate(v), Icons.calendar_today)),
          const SizedBox(width: 10),
          Expanded(child: _buildDeviceDropdown(vm)),
        ],
      ),
    );
  }

  Widget _buildCollapsibleDashboard(Map<String, dynamic> data, String? selectedDate) {
    final int total = data['total'];
    String dateDisplay = "날짜 미선택";
    if (selectedDate != null) {
      try {
        DateTime parsedDate = DateTime.parse(selectedDate);
        dateDisplay = DateFormat('yy년 M월 d일').format(parsedDate);
      } catch (e) {
        dateDisplay = selectedDate;
      }
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.mainColor,
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text("일일 판매 금액: ${AppFormat.won(total)}원",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900)),
          ),
          Text("$dateDisplay 기록",
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1.0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: _buildChartContent(data),
            ),
          ),
          GestureDetector(
            onTap: _toggleDashboard,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: double.infinity,
              height: 35,
              child: Icon(
                _isDashboardExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.white.withOpacity(0.8),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContent(Map<String, dynamic> data) {
    final int card = data['card'];
    final int cash = data['cash'];
    final Map<String, int> products = Map<String, int>.from(data['products']);

    final bool hasPaymentData = card > 0 || cash > 0;
    final bool hasProductData = products.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildChartSection(
            "결제 수단",
            _buildPaymentPieChart(card, cash),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChartLegend("카드", const Color(0xFF0B3D91)),
                const SizedBox(height: 8),
                _buildChartLegend("현금", const Color(0xFFEAB308)),
              ],
            ),
            hasData: hasPaymentData,
          ),
        ),
        Container(
          width: 1,
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          color: Colors.white.withOpacity(0.15),
        ),
        Expanded(
          child: _buildChartSection(
            "판매 비중",
            _buildProductPieChart(products),
            _buildProductLegend(products),
            hasData: hasProductData,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(String title, Widget chart, Widget legend,
      {required bool hasData}) {
    return Column(
      children: [
        Text(title,
            style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 15,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: hasData
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                  child: SizedBox(width: 125, height: 125, child: chart)),
              Expanded(child: legend),
            ],
          )
              : SizedBox(
            height: 125,
            child: Center(
              child: Text("데이터가 없습니다",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentPieChart(int card, int cash) {
    if (card == 0 && cash == 0) return const SizedBox.shrink();
    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 35,
        sections: [
          PieChartSectionData(
              value: card.toDouble(),
              color: const Color(0xFF0B3D91),
              radius: 25,
              showTitle: false),
          PieChartSectionData(
              value: cash.toDouble(),
              color: const Color(0xFFEAB308),
              radius: 25,
              showTitle: false),
        ],
      ),
    );
  }

  Widget _buildProductPieChart(Map<String, int> products) {
    if (products.isEmpty) return const SizedBox.shrink();
    int colorIdx = 0;
    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 35,
        sections: products.entries.take(5).map((e) {
          final color = _productColors[colorIdx % _productColors.length];
          colorIdx++;
          return PieChartSectionData(
              value: e.value.toDouble(),
              color: color,
              radius: 25,
              showTitle: false);
        }).toList(),
      ),
    );
  }

  Widget _buildProductLegend(Map<String, int> products) {
    final entries = products.entries.take(5).toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(entries.length, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: _buildChartLegend(
            entries[index].key.length > 5
                ? entries[index].key
                : entries[index].key,
            _productColors[index % _productColors.length],
          ),
        );
      }),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              softWrap: true,
            )),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.mainColor),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildCompactProductTable(Map<String, dynamic> summary) {
    final products = Map<String, int>.from(summary['products'] ?? {});
    final productAmounts = Map<String, int>.from(summary['productAmounts'] ?? {});

    if (products.isEmpty) return _buildEmptyBox("데이터가 없습니다.");

    final sortedEntries = products.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(
        children: sortedEntries.map((e) {
          final name = e.key;
          final count = e.value;
          final totalPay = productAmounts[name] ?? 0;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                border: name == sortedEntries.last.key
                    ? null
                    : Border(bottom: BorderSide(color: Colors.grey[100]!))),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("$count개 판매",
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.mainColor)),
                      const Text(" / ",
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600)),
                      Text("누적 ${AppFormat.won(totalPay)}원",
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.mainColor)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDropdown(
      String? value, List<String> items, Function(String?) onChanged, IconData icon) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 8),
            const Text("데이터 없음",
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }

    final String? effectiveValue =
    (value != null && items.contains(value)) ? value : items.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          dropdownColor: AppColors.mainColor,
          icon: Icon(icon, color: Colors.white, size: 14),
          isExpanded: true,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
          items: items.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDeviceDropdown(SettlementViewModel vm) {
    final otherDeviceIds =
    vm.allDevicesData.keys.where((uuid) => uuid != vm.myUuid).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: vm.selectedDeviceId,
          dropdownColor: AppColors.mainColor,
          icon: const Icon(Icons.tablet_android, color: Colors.white, size: 14),
          isExpanded: true,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
          items: [
            const DropdownMenuItem(value: "all", child: Text("전체 통합")),
            DropdownMenuItem(value: vm.myUuid, child: Text("현재 기기 (${vm.myUuid?.substring(0, 8)})")),
            ...otherDeviceIds.map((uuid) {
              return DropdownMenuItem(
                value: uuid,
                child: Text("기기 ${otherDeviceIds.indexOf(uuid) + 1} (${uuid.substring(0, 8)})"),
              );
            }),
          ],
          onChanged: (val) => vm.setSelectedDevice(val!),
        ),
      ),
    );
  }

  Widget _buildEmptyBox(String message) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Center(
          child: Text(message,
              style: const TextStyle(color: Colors.grey, fontSize: 13))),
    );
  }
}