class TransporterModel {
  int? id;
  String name;
  String phone;
  String createdAt;

  TransporterModel({
    this.id,
    required this.name,
    required this.phone,
    required this.createdAt,
  });

  factory TransporterModel.fromMap(Map<String, dynamic> map) {
    return TransporterModel(
      id: map['id'],
      name: map['name'],
      phone: map['phone'] ?? '',
      createdAt: map['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'createdAt': createdAt,
    };
  }
}