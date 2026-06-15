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
  final List<Map<String, dynamic>>? mountains;

  // Static FAQ fields
  final String? source;        // 'static_faq' atau 'gemini_api'
  final String? intent;        // e.g. 'list_mountains', 'payment_info'
  final String? responseType;  // e.g. 'text', 'buttons', 'mountain_cards', 'route_cards'
  final Map<String, dynamic>? data; // data payload untuk buttons, routes, dll

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
    this.mountains,
    this.source,
    this.intent,
    this.responseType,
    this.data,
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
    List<Map<String, dynamic>>? mountains,
    String? source,
    String? intent,
    String? responseType,
    Map<String, dynamic>? data,
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
      mountains: mountains ?? this.mountains,
      source: source ?? this.source,
      intent: intent ?? this.intent,
      responseType: responseType ?? this.responseType,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'isUser': isUser,
        'is_paid': isPaid,
        if (orderId != null) 'order_id': orderId,
        if (transactionId != null) 'transaction_id': transactionId,
        if (mountains != null) 'mountains': mountains,
        if (source != null) 'source': source,
        if (intent != null) 'intent': intent,
        if (responseType != null) 'type': responseType,
        if (data != null) 'data': data,
      };
}
