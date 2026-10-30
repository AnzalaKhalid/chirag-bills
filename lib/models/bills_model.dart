class BillModel {
  int? id;
  int? transporterId; // <-- NEW
  String? transporterName; // <-- NEW (Fetched from DB JOIN)
  String vehicleNo;
  String loadingDate;
  String unloadingDate;
  double loadingWeight;
  String loadingStation;
  double ratePerMt;
  double unloadingWeight;
  String unloadingStation;
  double gainLoss;
  double gainLossRate;
  double tripAmount;
  double remainingAmount;
  double toPay;

  BillModel({
    this.id,
    this.transporterId,
    this.transporterName,
    required this.vehicleNo,
    required this.loadingDate,
    required this.unloadingDate,
    required this.loadingWeight,
    required this.loadingStation,
    required this.ratePerMt,
    required this.unloadingWeight,
    required this.unloadingStation,
    required this.gainLoss,
    required this.gainLossRate,
    required this.tripAmount,
    required this.remainingAmount,
    required this.toPay,
  });

  factory BillModel.fromMap(Map<String, dynamic> map) {
    return BillModel(
      id: map['id'],
      transporterId: map['transporterId'],
      transporterName: map['transporterName'],
      vehicleNo: map['vehicleNo'] ?? '',
      loadingDate: map['loadingDate'] ?? '',
      unloadingDate: map['unloadingDate'] ?? '',
      loadingWeight: (map['loadingWeight'] as num?)?.toDouble() ?? 0.0,
      loadingStation: map['loadingStation'] ?? '',
      ratePerMt: (map['ratePerMt'] as num?)?.toDouble() ?? 0.0,
      unloadingWeight: (map['unloadingWeight'] as num?)?.toDouble() ?? 0.0,
      unloadingStation: map['unloadingStation'] ?? '',
      gainLoss: (map['gainLoss'] as num?)?.toDouble() ?? 0.0,
      gainLossRate: (map['gainLossRate'] as num?)?.toDouble() ?? 0.0,
      tripAmount: (map['tripAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      toPay: (map['toPay'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transporterId': transporterId,
      'vehicleNo': vehicleNo,
      'loadingDate': loadingDate,
      'unloadingDate': unloadingDate,
      'loadingWeight': loadingWeight,
      'loadingStation': loadingStation,
      'ratePerMt': ratePerMt,
      'unloadingWeight': unloadingWeight,
      'unloadingStation': unloadingStation,
      'gainLoss': gainLoss,
      'gainLossRate': gainLossRate,
      'tripAmount': tripAmount,
      'remainingAmount': remainingAmount,
      'toPay': toPay,
    };
  }

  BillModel copyWith({
    int? id,
    int? transporterId,
    String? transporterName,
    String? vehicleNo,
    double? ratePerMt,
    String? loadingDate,
    String? unloadingDate,
    double? loadingWeight,
    double? unloadingWeight,
    String? loadingStation,
    String? unloadingStation,
    double? gainLoss,
    double? gainLossRate,
    double? toPay,
    double? tripAmount,
    double? remainingAmount,
  }) {
    return BillModel(
      id: id ?? this.id,
      transporterId: transporterId ?? this.transporterId,
      transporterName: transporterName ?? this.transporterName,
      vehicleNo: vehicleNo ?? this.vehicleNo,
      ratePerMt: ratePerMt ?? this.ratePerMt,
      loadingDate: loadingDate ?? this.loadingDate,
      unloadingDate: unloadingDate ?? this.unloadingDate,
      loadingWeight: loadingWeight ?? this.loadingWeight,
      unloadingWeight: unloadingWeight ?? this.unloadingWeight,
      loadingStation: loadingStation ?? this.loadingStation,
      unloadingStation: unloadingStation ?? this.unloadingStation,
      gainLoss: gainLoss ?? this.gainLoss,
      gainLossRate: gainLossRate ?? this.gainLossRate,
      toPay: toPay ?? this.toPay,
      tripAmount: tripAmount ?? this.tripAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
    );
  }
}