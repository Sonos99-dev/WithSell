import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/models/review_model.dart';
import 'package:project/models/settlement_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SettlementViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late SharedPreferences _prefs;

  String? _myUuid;
  String? get myUuid => _myUuid;

  String _selectedDeviceId = "all"; // 기본값: 전체 통합
  String get selectedDeviceId => _selectedDeviceId;

  void setSelectedDevice(String id) {
    _selectedDeviceId = id;
    final available = allAvailableDates;
    if (available.isNotEmpty &&
        (_selectedDate == null || !available.contains(_selectedDate))) {
      _selectedDate = available.first;
    }
    notifyListeners();

    // ✅ 리뷰도 같은 기준으로 로드
    loadReviews();
  }

  Map<String, SettlementModel> _allDevicesData = {};
  Map<String, SettlementModel> get allDevicesData => _allDevicesData;

  String? _selectedDate;
  String? get selectedDate => _selectedDate;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // =========================
  // ✅ 리뷰 상태(추가)
  // =========================
  bool _isReviewLoading = false;
  bool get isReviewLoading => _isReviewLoading;

  List<ReviewModel> _reviews = [];
  List<ReviewModel> get reviews => _reviews;

  SettlementViewModel();

  Future<void> init(SharedPreferences prefs, List<dynamic> localHistory) async {
    _prefs = prefs;
    _myUuid = _prefs.getString('user_uuid');
    if (_myUuid == null) {
      _myUuid = const Uuid().v4();
      await _prefs.setString('user_uuid', _myUuid!);
    }

    _selectedDeviceId = "all";

    final String? cachedJson = _prefs.getString('cached_all_settlements');
    if (cachedJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(cachedJson);
        _allDevicesData = decoded.map(
              (key, value) => MapEntry(key, SettlementModel.fromJson(value)),
        );
      } catch (e) {
        debugPrint("Load Error: $e");
      }
    }

    updateMyLocalData(localHistory);

    if (localHistory.isNotEmpty) {
      List<String> allDates = localHistory.map((item) {
        return DateFormat('yyyy-MM-dd').format(DateTime.parse(item['date']));
      }).toList();
      allDates.sort((a, b) => b.compareTo(a));
      _selectedDate = allDates.first; // 최신 날짜를 기본값으로
    }

    notifyListeners();

    // ✅ 초기 리뷰 로드
    await loadReviews();
  }

  void setSelectedDate(String? date) {
    _selectedDate = date;
    notifyListeners();

    // ✅ 날짜 바뀌면 리뷰 다시 로드
    loadReviews();
  }

  // 내 기기의 데이터를 정리하여 로컬 맵에 저장
  void updateMyLocalData(List<dynamic> history) {
    if (_myUuid == null) return;

    Map<String, DailySettlement> dailyMap = {};

    for (var record in history) {
      if (record['isCanceled'] == true) continue;

      String dateKey =
      DateFormat('yyyy-MM-dd').format(DateTime.parse(record['date']));
      int amount = record['totalAmount'] as int;
      bool isCard = record['isCardPayment'] ?? false;
      List items = record['items'] ?? [];

      if (!dailyMap.containsKey(dateKey)) {
        dailyMap[dateKey] = DailySettlement(
          totalAmount: 0,
          cardAmount: 0,
          cashAmount: 0,
          productCounts: {},
          productAmounts: {},
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
        productAmounts: newAmounts,
      );
    }

    _allDevicesData[_myUuid!] =
        SettlementModel(uuid: _myUuid!, dailyData: dailyMap);
    _saveToLocal();
  }

  Future<void> syncWithCloud(List<dynamic> localHistory) async {
    _isLoading = true;
    notifyListeners();
    try {
      updateMyLocalData(localHistory);

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

      // ✅ 동기화 후 리뷰도 갱신
      await loadReviews();
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
    String encoded = jsonEncode(
      _allDevicesData.map((k, v) => MapEntry(k, v.toJson())),
    );
    await _prefs.setString('cached_all_settlements', encoded);
  }

  Map<String, dynamic> getFilteredSummary() {
    int total = 0, card = 0, cash = 0;
    Map<String, int> products = {};
    Map<String, int> productAmounts = {};

    if (_selectedDate == null) {
      return {
        'total': 0,
        'card': 0,
        'cash': 0,
        'products': {},
        'productAmounts': {},
      };
    }

    _allDevicesData.forEach((uuid, model) {
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

    // ✅ 리뷰도 갱신
    loadReviews();
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
// ✅ 현재 기기 선택 여부
  bool get isCurrentDeviceSelected => _selectedDeviceId == _myUuid;

// ✅ 현재 선택된 날짜 + 내 기기에 해당하는 리뷰(있으면 1개)
  ReviewModel? get myReviewForSelectedDate {
    if (_myUuid == null || _selectedDate == null) return null;
    // loadReviews()가 내 기기 포함해서 가져온 상태라고 가정
    return _reviews
        .where((r) => r.date == _selectedDate!)
        .cast<ReviewModel?>()
        .firstWhere((r) => r != null && true, orElse: () => null);
  }

  /// ==========================================================
  /// ✅ 리뷰 로드 (기존 로직 유지 + 1개 제한 구조와 호환)
  /// Firestore 구조:
  /// reviews/{deviceId}/items/{docId}
  /// docId = yyyy-MM-dd  (날짜별 1개 강제)
  /// ==========================================================
  Future<void> loadReviews() async {
    if (_selectedDate == null) {
      _reviews = [];
      notifyListeners();
      return;
    }

    _isReviewLoading = true;
    notifyListeners();

    try {
      final date = _selectedDate!;
      List<ReviewModel> results = [];

      if (_selectedDeviceId == "all") {
        // ✅ 핵심: reviews 컬렉션에서 문서 목록을 가져오지 말고
        // 정산에서 알고 있는 기기 uuid 목록으로 순회
        final deviceIds = _allDevicesData.keys.toList();

        // 혹시 로컬에 내 데이터만 있고 맵이 비어있을 가능성 대비
        if (_myUuid != null && !deviceIds.contains(_myUuid)) {
          deviceIds.add(_myUuid!);
        }

        final futures = deviceIds.map((deviceId) async {
          final doc = await _firestore
              .collection('reviews')
              .doc(deviceId)
              .collection('items')
              .doc(date) // ✅ 날짜 docId
              .get();

          if (!doc.exists) return <ReviewModel>[];
          return [ReviewModel.fromJson(doc.data()!)];
        }).toList();

        final lists = await Future.wait(futures);
        results = lists.expand((e) => e).toList();
      } else {
        final doc = await _firestore
            .collection('reviews')
            .doc(_selectedDeviceId)
            .collection('items')
            .doc(date)
            .get();

        results = doc.exists ? [ReviewModel.fromJson(doc.data()!)] : [];
      }

      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _reviews = results;
    } catch (e) {
      debugPrint("리뷰 로드 실패: $e");
      _reviews = [];
    } finally {
      _isReviewLoading = false;
      notifyListeners();
    }
  }

  /// ==========================================================
  /// ✅ (date, myUuid) 당 1개만: 있으면 수정, 없으면 생성
  /// docId = selectedDate
  /// ==========================================================
  Future<void> upsertMyReview({
    required String location,
    required String author,
    required String content,
  }) async {
    if (_myUuid == null || _selectedDate == null) return;

    final date = _selectedDate!;
    final newReview = ReviewModel(
      date: date,
      location: location.trim(),
      author: author.trim(),
      content: content.trim(),
      createdAt: DateTime.now(), // 수정 시에도 최신 시간으로 갱신
    );

    // ✅ 로컬 상태 업데이트: 내 기기/날짜 리뷰는 1개만 유지
    _reviews = _reviews.where((r) => r.date != date).toList();
    _reviews = [newReview, ..._reviews];
    notifyListeners();

    try {
      await _firestore
          .collection('reviews')
          .doc(_myUuid)
          .collection('items')
          .doc(date) // ✅ 날짜 docId로 1개 강제
          .set({
        ...newReview.toJson(),
        'id': date, // 선택: 식별용
        'deviceId': _myUuid,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("소감 등록/수정 실패: $e");
      rethrow;
    }
  }

  Future<void> deleteMyReviewForSelectedDate() async {
    if (_myUuid == null || _selectedDate == null) return;

    final date = _selectedDate!;
    // 로컬 먼저 제거
    _reviews = _reviews.where((r) => r.date != date).toList();
    notifyListeners();

    try {
      await _firestore
          .collection('reviews')
          .doc(_myUuid)
          .collection('items')
          .doc(date) // ✅ 날짜 docId (1개 고정)
          .delete();
    } catch (e) {
      debugPrint("소감 삭제 실패: $e");
      // 실패 시: 다시 로드해서 서버 상태로 복구(안전)
      await loadReviews();
      rethrow;
    }
  }
}