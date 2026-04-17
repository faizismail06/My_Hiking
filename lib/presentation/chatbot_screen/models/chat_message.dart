class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final String? downloadUrl;
  final String? paymentUrl;
  final int? orderId;
  final int? transactionId;
  final String? paymentMethod;
  final int? totalPayment;
  final String? transactionCreatedAt;
  final String? paymentCode;
  final String? paymentCodeLabel;
  final String? paymentInstruction;
  final String? deeplinkUrl;
  final String? qrCodeUrl;
  final String? qrString;
  bool isPaid;

  ChatMessage({
    required this.message,
    required this.isUser,
    DateTime? timestamp,
    this.downloadUrl,
    this.paymentUrl,
    this.orderId,
    this.transactionId,
    this.paymentMethod,
    this.totalPayment,
    this.transactionCreatedAt,
    this.paymentCode,
    this.paymentCodeLabel,
    this.paymentInstruction,
    this.deeplinkUrl,
    this.qrCodeUrl,
    this.qrString,
    this.isPaid = false,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? message,
    bool? isUser,
    DateTime? timestamp,
    String? downloadUrl,
    String? paymentUrl,
    int? orderId,
    int? transactionId,
    String? paymentMethod,
    int? totalPayment,
    String? transactionCreatedAt,
    String? paymentCode,
    String? paymentCodeLabel,
    String? paymentInstruction,
    String? deeplinkUrl,
    String? qrCodeUrl,
    String? qrString,
    bool? isPaid,
  }) {
    return ChatMessage(
      message: message ?? this.message,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      orderId: orderId ?? this.orderId,
      transactionId: transactionId ?? this.transactionId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalPayment: totalPayment ?? this.totalPayment,
      transactionCreatedAt: transactionCreatedAt ?? this.transactionCreatedAt,
      paymentCode: paymentCode ?? this.paymentCode,
      paymentCodeLabel: paymentCodeLabel ?? this.paymentCodeLabel,
      paymentInstruction: paymentInstruction ?? this.paymentInstruction,
      deeplinkUrl: deeplinkUrl ?? this.deeplinkUrl,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      qrString: qrString ?? this.qrString,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'isUser': isUser,
        'is_paid': isPaid,
        if (orderId != null) 'order_id': orderId,
        if (transactionId != null) 'transaction_id': transactionId,
      };
}
