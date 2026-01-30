import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';import 'package:project/models/settlement_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SettlementViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SharedPreferences _prefs;

  String? _myUuid;
  String? get myUuid => _myUuid;

  String _selectedDeviceId = "all"; // 기본값: 전체 통합
  String get selectedDeviceId => _selectedDeviceId;

  void setSelectedDevice(String id) {
    _selectedDeviceId = id;
    final available = allAvailableDates;
    if (available.isNotEmpty && (_selectedDate == null || !available.contains(_selectedDate))) {
      _selectedDate = available.first;
    }
    notifyListeners();
  }

  Map<String, SettlementModel> _allDevicesData = {};
  Map<String, SettlementModel> get allDevicesData => _allDevicesData;

  String? _selectedDate;
  String? get selectedDate => _selectedDate;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SettlementViewModel(this._prefs);

  Future<void> init(List<dynamic> localHistory) async {
    _myUuid = _prefs.getString('user_uuid');
    if (_myUuid == null) {
      _myUuid = const Uuid().v4();
      await _prefs.setString('user_uuid', _myUuid!);
    }

    // 1. 기기 선택 초기화
    _selectedDeviceId = "all";

    // 2. 로컬 캐시 로드
    final String? cachedJson = _prefs.getString('cached_all_settlements');
    if (cachedJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(cachedJson);
        _allDevicesData = decoded.map((key, value) => MapEntry(key, SettlementModel.fromJson(value)));
      } catch (e) {
        debugPrint("Load Error: $e");
      }
    }

    // 3. 내 로컬 데이터 업데이트 (여기서 _allDevicesData에 내 데이터가 들어감)
    updateMyLocalData(localHistory);

    // 4. 🔥 날짜 설정:
    // SalesHistoryViewModel에 이미 정렬된 날짜가 있으므로
    // 탭 이동 시에는 그곳의 데이터를 참조하는 것이 가장 정확합니다.
    if (localHistory.isNotEmpty) {
      List<String> allDates = localHistory.map((item) {
        return DateFormat('yyyy-MM-dd').format(DateTime.parse(item['date']));
      }).toList();
      allDates.sort((a, b) => b.compareTo(a));
      _selectedDate = allDates.first; // 최신 날짜를 기본값으로
    }

    notifyListeners();
  }

  void setSelectedDate(String? date) {
    _selectedDate = date;
    notifyListeners();
  }

  // 내 기기의 데이터를 정리하여 로컬 맵에 저장
  void updateMyLocalData(List<dynamic> history) {
    if (_myUuid == null) return;

    Map<String, DailySettlement> dailyMap = {};

    for (var record in history) {
      if (record['isCanceled'] == true) continue;

      String dateKey = DateFormat('yyyy-MM-dd').format(DateTime.parse(record['date']));
      int amount = record['totalAmount'] as int;
      bool isCard = record['isCardPayment'] ?? false;
      List items = record['items'] ?? [];

      if (!dailyMap.containsKey(dateKey)) {
        dailyMap[dateKey] = DailySettlement(
            totalAmount: 0,
            cardAmount: 0,
            cashAmount: 0,
            productCounts: {},
            productAmounts: {}
        );
      }

      var current = dailyMap[dateKey]!;
      int newTotal = current.totalAmount + amount;
      int newCard = current.cardAmount + (isCard ? amount : 0);
      int newCash = current.cashAmount + (!isCard ? amount : 0);

      Map<String, int> newProducts = Map.from(current.productCounts);
      Map<String, int> newAmounts = Map.from(current.productAmounts);

      for (var item in items) {
        String name = item['name'];
        int qty = item['quantity'];
        int itemTotal = item['totalPrice'] ?? 0;

        newProducts[name] = (newProducts[name] ?? 0) + qty;
        newAmounts[name] = (newAmounts[name] ?? 0) + itemTotal;
      }

      dailyMap[dateKey] = DailySettlement(
        totalAmount: newTotal,
        cardAmount: newCard,
        cashAmount: newCash,
        productCounts: newProducts,
        productAmounts: newAmounts
      );
    }

    _allDevicesData[_myUuid!] = SettlementModel(uuid: _myUuid!, dailyData: dailyMap);
    _saveToLocal();
    // notifyListeners()는 필요에 따라 외부에서 호출하거나 여기서 호출
  }

  // 클라우드와 동기화 (SettlementPage에서 호출됨)
  Future<void> syncWithCloud(List<dynamic> localHistory) async {
    _isLoading = true;
    notifyListeners();
    try {
      updateMyLocalData(localHistory);

      // 내 데이터 업로드
      await _firestore
          .collection('settlements')
          .doc(_myUuid)
          .set(_allDevicesData[_myUuid!]!.toJson())
          .timeout(const Duration(seconds: 5));

      // 모든 기기 데이터 가져오기
      final snapshot = await _firestore
          .collection('settlements')
          .get()
          .timeout(const Duration(seconds: 5));

      Map<String, SettlementModel> temp = {};
      for (var doc in snapshot.docs) {
        temp[doc.id] = SettlementModel.fromJson(doc.data());
      }
      _allDevicesData = temp;
      _saveToLocal();
    } on TimeoutException {
      throw '시간 초과: 네트워크 상태를 확인해주세요.';
    } on SocketException {
      throw '네트워크 연결 없음: 인터넷 연결을 확인해주세요.';
    } catch (e) {
      throw '동기화 중 오류가 발생했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveToLocal() async {
    String encoded = jsonEncode(_allDevicesData.map((k, v) => MapEntry(k, v.toJson())));
    await _prefs.setString('cached_all_settlements', encoded);
  }

  // 🔥 UI에서 사용하는 필터링된 요약 데이터 계산
  Map<String, dynamic> getFilteredSummary() {
    int total = 0, card = 0, cash = 0;
    Map<String, int> products = {};
    Map<String, int> productAmounts = {};

    if (_selectedDate == null) return {'total': 0, 'card': 0, 'cash': 0, 'products': {}, 'productAmounts': {}};

    _allDevicesData.forEach((uuid, model) {
      // 'all'이거나 선택된 기기 ID와 일치할 때만 합산
      if (_selectedDeviceId == "all" || _selectedDeviceId == uuid) {
        final daily = model.dailyData[_selectedDate];
        if (daily != null) {
          total += daily.totalAmount;
          card += daily.cardAmount;
          cash += daily.cashAmount;
          daily.productCounts.forEach((name, qty) {
            products[name] = (products[name] ?? 0) + qty;
          });
          daily.productAmounts.forEach((name, amt) {
            productAmounts[name] = (productAmounts[name] ?? 0) + amt;
          });
        }
      }
    });

    return {
      'total': total,
      'card': card,
      'cash': cash,
      'products': products,
      'productAmounts': productAmounts,
    };
  }

  void resetSelection() {
    _selectedDeviceId = _myUuid ?? "all";

    final dates = allAvailableDates;
    if (dates.isNotEmpty) {
      _selectedDate = dates.first;
    }
    notifyListeners();
  }


  List<String> get allAvailableDates {
    final Set<String> dateSet = {};

    if (_selectedDeviceId == "all") {
      for (var device in _allDevicesData.values) {
        dateSet.addAll(device.dailyData.keys);
      }
    } else {
      final selectedDeviceData = _allDevicesData[_selectedDeviceId];
      if (selectedDeviceData != null) {
        dateSet.addAll(selectedDeviceData.dailyData.keys);
      }
    }

    List<String> sortedList = dateSet.toList();
    sortedList.sort((a, b) => b.compareTo(a));

    return sortedList;
  }
}