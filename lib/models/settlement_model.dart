class SettlementModel {
  final String uuid;
  final Map<String, DailySettlement> dailyData; // Key: "yyyy-MM-dd"

  SettlementModel({required this.uuid, required this.dailyData});Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'dailyData': dailyData.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory SettlementModel.fromJson(Map<String, dynamic> json) {
    var dailyMap = json['dailyData'] as Map<String, dynamic>? ?? {};
    return SettlementModel(
      uuid: json['uuid'] ?? '',
      dailyData: dailyMap.map((k, v) => MapEntry(k, DailySettlement.fromJson(v))),
    );
  }
}

class DailySettlement {
  final int totalAmount;
  final int cardAmount;
  final int cashAmount;
  final Map<String, int> productCounts;

  DailySettlement({
    required this.totalAmount,
    required this.cardAmount,
    required this.cashAmount,
    required this.productCounts,
  });

  Map<String, dynamic> toJson() => {
    'totalAmount': totalAmount,
    'cardAmount': cardAmount,
    'cashAmount': cashAmount,
    'productCounts': productCounts,
  };

  factory DailySettlement.fromJson(Map<String, dynamic> json) {
    return DailySettlement(
      totalAmount: json['totalAmount'] ?? 0,
      cardAmount: json['cardAmount'] ?? 0,
      cashAmount: json['cashAmount'] ?? 0,
      productCounts: Map<String, int>.from(json['productCounts'] ?? {}),
    );
  }
}