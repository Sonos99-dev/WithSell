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

  Future<void> updateCancelStatus(int salesNumber, bool isCanceled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = _history.indexWhere((item) => item['salesNumber'] == salesNumber);

      if (index != -1) {
        Map<String, dynamic> updatedRecord = Map<String, dynamic>.from(_history[index]);
        updatedRecord['isCanceled'] = isCanceled;

        _history[index] = updatedRecord;

        String jsonString = jsonEncode(_history);
        await prefs.setString('sales_history', jsonString);

        notifyListeners();
      }
    } catch (e) {
      debugPrint("결제 취소 중 오류 발생: $e");
    }
  }
}