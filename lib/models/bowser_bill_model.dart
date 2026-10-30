class BowserBillModel {
  int? id;
  int? transporterId;
  String? transporterName; // For UI display
  String vehicleNo;
  double loadWeight;
  double unloadWeight;
  double rent;
  double carRent;
  double totalRent;
  double primeMoverRent;
  double bowzerRent;
  String createdAt;

  BowserBillModel({
    this.id,
    this.transporterId,
    this.transporterName,
    required this.vehicleNo,
    required this.loadWeight,
    required this.unloadWeight,
    required this.rent,
    required this.carRent,
    required this.totalRent,
    required this.primeMoverRent,
    required this.bowzerRent,
    required this.createdAt,
  });

  factory BowserBillModel.fromMap(Map<String, dynamic> map) {
    return BowserBillModel(
      id: map['id'],
      transporterId: map['transporterId'],
      transporterName: map['transporterName'],
      vehicleNo: map['vehicleNo'] ?? '',
      loadWeight: (map['loadWeight'] as num?)?.toDouble() ?? 0.0,
      unloadWeight: (map['unloadWeight'] as num?)?.toDouble() ?? 0.0,
      rent: (map['rent'] as num?)?.toDouble() ?? 0.0,
      carRent: (map['carRent'] as num?)?.toDouble() ?? 0.0,
      totalRent: (map['totalRent'] as num?)?.toDouble() ?? 0.0,
      primeMoverRent: (map['primeMoverRent'] as num?)?.toDouble() ?? 0.0,
      bowzerRent: (map['bowzerRent'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transporterId': transporterId,
      'vehicleNo': vehicleNo,
      'loadWeight': loadWeight,
      'unloadWeight': unloadWeight,
      'rent': rent,
      'carRent': carRent,
      'totalRent': totalRent,
      'primeMoverRent': primeMoverRent,
      'bowzerRent': bowzerRent,
      'createdAt': createdAt,
    };
  }
}