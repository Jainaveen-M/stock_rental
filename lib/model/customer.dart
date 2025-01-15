class Customer {
  final int? dbKey;
  final int id;
  final String name;
  final String phoneNumber;
  final String address;
  final String? proofNumber;

  Customer({
    this.dbKey,
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
    this.proofNumber,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phoneNumber': phoneNumber,
        'address': address,
        'proofNumber': proofNumber,
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'] is String ? int.parse(map['id']) : map['id'],
        name: map['name'] ?? '',
        phoneNumber: map['phoneNumber'] ?? '',
        address: map['address'] ?? '',
        proofNumber: map['proofNumber'],
      );

  Customer copyWith({
    int? dbKey,
    int? id,
    String? name,
    String? phoneNumber,
    String? address,
    String? proofNumber,
  }) {
    return Customer(
      dbKey: dbKey ?? this.dbKey,
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      proofNumber: proofNumber ?? this.proofNumber,
    );
  }
}
