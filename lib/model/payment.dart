class Payment {
  final int orderId;
  final double totalAmount;
  final double advanceAmount;
  final double balanceAmount;
  final DateTime paymentDate;
  final String paymentMode; // 'cash', 'card', 'upi', etc.
  final String status; // 'partial', 'completed'

  Payment({
    required this.orderId,
    required this.totalAmount,
    required this.advanceAmount,
    required this.balanceAmount,
    required this.paymentDate,
    required this.paymentMode,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
        'orderId': orderId,
        'totalAmount': totalAmount,
        'advanceAmount': advanceAmount,
        'balanceAmount': balanceAmount,
        'paymentDate': paymentDate.toIso8601String(),
        'paymentMode': paymentMode,
        'status': status,
      };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
        orderId: map['orderId'],
        totalAmount: map['totalAmount'],
        advanceAmount: map['advanceAmount'],
        balanceAmount: map['balanceAmount'],
        paymentDate: DateTime.parse(map['paymentDate']),
        paymentMode: map['paymentMode'],
        status: map['status'],
      );
}
