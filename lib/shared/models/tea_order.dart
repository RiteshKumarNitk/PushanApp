class TeaOrder {
  final String id;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final String? adminNotes;
  final String? invoiceUrl;
  final List<Map<String, dynamic>> items;

  TeaOrder({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    this.adminNotes,
    this.invoiceUrl,
    this.items = const [],
  });

  factory TeaOrder.fromJson(Map<String, dynamic> json) {
    return TeaOrder(
      id: json['id'],
      status: json['status'] ?? 'requested',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      adminNotes: json['admin_notes'],
      invoiceUrl: json['invoice_url'],
      items: json['tea_order_items'] != null 
          ? List<Map<String, dynamic>>.from(json['tea_order_items']) 
          : [],
    );
  }
}
