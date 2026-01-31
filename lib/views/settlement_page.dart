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

class _SettlementPageState extends State<SettlementPage> with SingleTickerProviderStateMixin {
  bool _isDashboardExpanded = true;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  bool _isOverlayLoading = false; // 로딩 상태 (상단 버튼 차단 및 오버레이용)
  bool _isManualSync = false;     // 상단 버튼을 눌렀을 때만 중앙 아이콘을 띄우기 위한 플래그

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final historyVm = context.read<SalesHistoryViewModel>();
      context.read<SettlementViewModel>().updateMyLocalData(historyVm.history);
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

  // 🔥 통합 동기화 로직
  Future<void> _handleSync(SettlementViewModel vm, List<dynamic> history, {required bool isManual}) async {
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

  // 🔥 중앙 오버레이 (상단 버튼 클릭 시에만 중앙 아이콘 표시, 리프레시 때는 터치만 차단)
  Widget _buildSyncLoadingOverlay() {
    if (!_isOverlayLoading) return const SizedBox.shrink();

    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true, // 모든 터치 이벤트 차단 (상단 버튼 및 리스트 조작 불가)
        child: Container(
          color: Colors.black.withOpacity(0.02), // 아주 살짝 어둡게 하여 터치 차단 시각화
          child: _isManualSync
              ? Center( // 🔥 상단 버튼 클릭 시에만 중앙 로딩 아이콘 표시
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 1)
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainColor),
              ),
            ),
          )
              : const SizedBox.shrink(), // 🔥 리프레시 때는 터치만 막고 아이콘은 안 띄움
        ),
      ),
    );
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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
        backgroundColor: AppColors.mainColor,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white),
            // 로딩 중에는 버튼 클릭 방지
            onPressed: _isOverlayLoading ? null : () => _handleSync(settlementVm, historyVm.history, isManual: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
                  // 🔥 당겨서 새로고침 할 때 isManual을 false로 전달
                  onRefresh: () => _handleSync(settlementVm, historyVm.history, isManual: false),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const SizedBox(height: 15),
                      _buildSectionHeader("상세 판매 품목", Icons.list_alt),
                      _buildCompactProductTable(summary),
                      const SizedBox(height: 20),
                      _buildSectionHeader("기기별 판매 현황 (${settlementVm.selectedDate})", Icons.devices),
                      _buildCompactDeviceTable(settlementVm),
                      const SizedBox(height: 80),
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

  // --- 이하 헬퍼 위젯 (차트 등 데이터가 없으면 범례 숨김 처리 포함) ---

  Widget _buildFilterBar(SettlementViewModel vm, List<String> dates) {
    return Container(
      color: AppColors.mainColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(child: _buildDropdown(vm.selectedDate, dates, (v) => vm.setSelectedDate(v), Icons.calendar_today)),
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
        dateDisplay = selectedDate; // 파싱 실패 시 원본 유지
      }
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.mainColor,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text("일일 판매 금액: ${AppFormat.won(total)}원",
                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
          ),
          Text("$dateDisplay 기록",
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w700)),
          SizedBox(height: 10,),
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
                _isDashboardExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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

  Widget _buildChartSection(String title, Widget chart, Widget legend, {required bool hasData}) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15, fontWeight: FontWeight.w900)),
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
                  child: SizedBox(width: 125, height: 125, child: chart)
              ),
              Expanded(child: legend),
            ],
          )
              : SizedBox(
            height: 125,
            child: Center(
              child: Text(
                  "데이터가 없습니다",
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)
              ),
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
          PieChartSectionData(value: card.toDouble(), color: const Color(0xFF0B3D91), radius: 25, showTitle: false),
          PieChartSectionData(value: cash.toDouble(), color: const Color(0xFFEAB308), radius: 25, showTitle: false),
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
          return PieChartSectionData(value: e.value.toDouble(), color: color, radius: 25, showTitle: false);
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
            entries[index].key.length > 5 ? entries[index].key : entries[index].key,
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
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
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
          )
        ),
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
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildCompactProductTable(Map<String, dynamic> summary) {
    // getFilteredSummary에서 넘겨받은 데이터
    final products = Map<String, int>.from(summary['products'] ?? {});
    final productAmounts = Map<String, int>.from(summary['productAmounts'] ?? {});

    if (products.isEmpty) return _buildEmptyBox("데이터가 없습니다.");

    // 수량 많은 순 정렬
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
          final totalPay = productAmounts[name] ?? 0; // 누적 합계 금액

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                border: name == sortedEntries.last.key ? null : Border(bottom: BorderSide(color: Colors.grey[100]!))),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("$count개 판매", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.mainColor)),
                      Text(" / ", style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                      Text("누적 ${AppFormat.won(totalPay)}원",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.mainColor)),
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

  Widget _buildCompactDeviceTable(SettlementViewModel vm) {
    final devices = vm.allDevicesData.values.toList();
    devices.sort((a, b) {
      if (a.uuid == vm.myUuid) return -1; // a가 내 기기면 앞으로
      if (b.uuid == vm.myUuid) return 1;  // b가 내 기기면 뒤로
      return 0;
    });

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: devices.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[100]),
        itemBuilder: (context, index) {
          final dev = devices[index];
          final daily = dev.dailyData[vm.selectedDate];
          final isMe = dev.uuid == vm.myUuid;
          return ListTile(
            dense: true,
            leading: Icon(isMe ? Icons.stars : Icons.tablet_android, color: isMe ? Colors.orange : Colors.grey, size: 18),
            title: Text(isMe ? "내 기기 (현재) (${dev.uuid.substring(0, 8)})" : "기기$index, (${dev.uuid.substring(0, 8)})",
                style: TextStyle(fontWeight: isMe ? FontWeight.w900 : FontWeight.w900, fontSize: 13)),
            trailing: Text("${AppFormat.won(daily?.totalAmount ?? 0)}원",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          );
        },
      ),
    );
  }

  // lib/views/settlement_page.dart 의 _buildDropdown 부분 수정

  Widget _buildDropdown(String? value, List<String> items, Function(String?) onChanged, IconData icon) {
    // 1. 목록이 비어있을 경우 (해당 기기에 데이터가 아예 없는 날짜 등)
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10)
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 8),
            const Text("데이터 없음", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }

    // 2. 🔥 중요: 현재 선택된 날짜(value)가 새롭게 필터링된 목록(items)에 포함되어 있는지 확인
    // 기기를 바꿨을 때 이전 기기의 날짜가 현재 기기에 없을 경우 items.first(가장 최신 날짜)를 보여줍니다.
    final String? effectiveValue = (value != null && items.contains(value)) ? value : items.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue, // 검증된 값 사용
          dropdownColor: AppColors.mainColor,
          icon: Icon(icon, color: Colors.white, size: 14),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
          items: items.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDeviceDropdown(SettlementViewModel vm) {
    final otherDeviceIds = vm.allDevicesData.keys.where((uuid) => uuid != vm.myUuid).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: vm.selectedDeviceId,
          dropdownColor: AppColors.mainColor,
          icon: const Icon(Icons.tablet_android, color: Colors.white, size: 14),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
          items: [
            const DropdownMenuItem(value: "all", child: Text("전체 통합")),
            DropdownMenuItem(value: vm.myUuid, child: Text("현재 기기")),

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
      child: Center(child: Text(message, style: const TextStyle(color: Colors.grey, fontSize: 13))),
    );
  }
}