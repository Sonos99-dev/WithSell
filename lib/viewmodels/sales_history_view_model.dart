import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesHistoryViewModel extends ChangeNotifier {
  List<dynamic> _history = [];
  List<dynamic> get history => _history;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 로컬에서 판매 내역 불러오기
  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? encodedData = prefs.getString('sales_history');

      if (encodedData != null) {
        _history = jsonDecode(encodedData);
      } else {
        _history = [];
      }
    } catch (e) {
      debugPrint("판매 내역 로드 실패: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 특정 내역 삭제 (필요시)
  Future<void> deleteHistory(int salesNumber) async {
    _history.removeWhere((item) => item['salesNumber'] == salesNumber);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sales_history', jsonEncode(_history));
    notifyListeners();
  }

  /// 전체 내역 초기화
  Future<void> clearAllHistory() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sales_history');
    notifyListeners();
  }

  /// 특정 날짜의 모든 내역 삭제
  Future<void> deleteHistoryByDate(String dateString) async {
    // 해당 날짜(yyyy-MM-dd)와 일치하지 않는 데이터들만 남김
    _history.removeWhere((item) {
      String itemDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(item['date']));
      return itemDate == dateString;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sales_history', jsonEncode(_history));

    notifyListeners();
  }

  /// 목업
  Future<void> injectMockData() async {
    final prefs = await SharedPreferences.getInstance();

    // 서로 다른 3일간의 데이터 생성
    List<Map<String, dynamic>> mockHistory = [
      // 1. 오늘 데이터
      {
        'id': 1001,
        'salesNumber': 3,
        'totalAmount': 15000,
        'date': DateTime.now().toIso8601String(),
        'items': [
          {'name': '상품 A', 'quantity': 2, 'totalPrice': 10000},
          {'name': '상품 B', 'quantity': 1, 'totalPrice': 5000},
        ]
      },
      // 2. 어제 데이터
      {
        'id': 1002,
        'salesNumber': 2,
        'totalAmount': 20000,
        'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'items': [
          {'name': '상품 C', 'quantity': 4, 'totalPrice': 20000},
        ]
      },
      // 3. 그저께 데이터
      {
        'id': 1003,
        'salesNumber': 1,
        'totalAmount': 8000,
        'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'items': [
          {'name': '상품 A', 'quantity': 1, 'totalPrice': 5000},
          {'name': '상품 D', 'quantity': 1, 'totalPrice': 3000},
        ]
      }
    ];

    await prefs.setString('sales_history', jsonEncode(mockHistory));
    await loadHistory(); // 화면 갱신을 위해 다시 로드
  }
}