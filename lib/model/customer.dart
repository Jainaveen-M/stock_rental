class Customer {
  final String id;
  final String name;
  final String phoneNumber;
  final String address;

  Customer({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phoneNumber': phoneNumber,
        'address': address,
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        phoneNumber: map['phoneNumber'] ?? '',
        address: map['address'] ?? '',
      );
}
