class CardInfo {
  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final double balance;

  CardInfo({
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    required this.balance,
  });

  factory CardInfo.fromMap(Map<String, dynamic> map) {
    return CardInfo(
      cardNumber: map['cardNumber'] ?? '',
      cardHolder: map['cardHolder'] ?? '',
      expiryDate: map['expiryDate'] ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cardNumber': cardNumber,
      'cardHolder': cardHolder,
      'expiryDate': expiryDate,
      'balance': balance,
    };
  }
} 