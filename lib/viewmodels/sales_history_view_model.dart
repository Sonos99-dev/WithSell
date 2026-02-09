import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesHistoryViewModel extends ChangeNotifier {
  static const String dateFormatStr = 'yyyy-MM-dd';
  List<dynamic> _history = [];
  List<dynamic> get history => _history;
  late SharedPreferences _prefs;

  SalesHistoryViewModel();

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    await loadHistory();
  }

  String? _selectedDate;
  String? get selectedDate => _selectedDate;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, List<dynamic>> get groupedHistory {
    Map<String, List<dynamic>> grouped = {};
    for (var record in _history) {
      String dateKey = DateFormat(dateFormatStr).format(DateTime.parse(record['date']));
      if (grouped[dateKey] == null) grouped[dateKey] = [];
      grouped[dateKey]!.add(record);
    }
    return grouped;
  }

  List<String> get sortedDates {
    final dates = groupedHistory.keys.toList();
    dates.sort((a, b) => b.compareTo(a)); // 최신순 정렬
    return dates;
  }

  List<dynamic> get displayRecords {
    if (_selectedDate == null) return [];
    return groupedHistory[_selectedDate] ?? [];
  }

  void setSelectedDate(String? date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// 로컬에서 판매 내역 불러오기
  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final String? encodedData = _prefs.getString('sales_history');

      if (encodedData != null) {
        _history = jsonDecode(encodedData);
        selectLatestDate();
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

  void selectLatestDate() {
    if (_history.isEmpty) {
      _selectedDate = null;
    } else {
      List<String> allDates = _history.map((item) {
        return DateFormat(dateFormatStr).format(DateTime.parse(item['date']));
      }).toList();

      allDates.sort((a, b) => b.compareTo(a)); // 내림차순 정렬 (최신이 위로)
      _selectedDate = allDates.first;
    }
    notifyListeners();
  }

  /// 특정 내역 삭제 (필요시)
  Future<void> deleteHistory(int salesNumber) async {
    _history.removeWhere((item) => item['salesNumber'] == salesNumber);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sales_history', jsonEncode(_history));

    if (_selectedDate != null) {
      final dates = groupedHistory.keys.toList();
      if (!dates.contains(_selectedDate)) {
        selectLatestDate();
      }
    }

    notifyListeners();
  }

  /// 전체 내역 초기화
  Future<void> clearAllHistory() async {
    _history.clear();
    await _prefs.remove('sales_history');
    notifyListeners();
  }

  /// 특정 날짜의 모든 내역 삭제
  Future<void> deleteHistoryByDate(String dateString) async {
    _history.removeWhere((item) {
      String itemDate = DateFormat(dateFormatStr).format(DateTime.parse(item['date']));
      return itemDate == dateString;
    });

    await _prefs.setString('sales_history', jsonEncode(_history));

    selectLatestDate();
    notifyListeners();
  }

  Future<void> updateCancelStatus(int salesNumber, bool isCanceled) async {
    try {
      final index = _history.indexWhere((item) => item['salesNumber'] == salesNumber);

      if (index != -1) {
        Map<String, dynamic> updatedRecord = Map<String, dynamic>.from(_history[index]);
        updatedRecord['isCanceled'] = isCanceled;

        _history[index] = updatedRecord;

        String jsonString = jsonEncode(_history);
        await _prefs.setString('sales_history', jsonString);

        notifyListeners();
      }
    } catch (e) {
      debugPrint("결제 취소 중 오류 발생: $e");
    }
  }
}