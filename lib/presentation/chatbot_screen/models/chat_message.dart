class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final String? downloadUrl;
  final String? paymentUrl;
  final int? orderId;
  final int? transactionId;
  bool isPaid;

  ChatMessage({
    required this.message,
    required this.isUser,
    DateTime? timestamp,
    this.downloadUrl,
    this.paymentUrl,
    this.orderId,
    this.transactionId,
    this.isPaid = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'message': message,
        'isUser': isUser,
        if (orderId != null) 'order_id': orderId,
        if (transactionId != null) 'transaction_id': transactionId,
      };
}
