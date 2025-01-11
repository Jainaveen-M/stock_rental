class Customer {
  final String id; // Unique ID for the customer
  final String name;
  final String phoneNumber;
  final String address;
  final String contact;

  Customer({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.address,
    required this.contact,
  });

  // Convert a Customer object to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'contact': contact,
    };
  }

  // Convert a Map to a Customer object
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phoneNumber: map['phoneNumber'] as String,
      address: map['address'] as String,
      contact: map['contact'] ?? '',
    );
  }
}
