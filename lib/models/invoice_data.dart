class InvoiceData {
  String? clientId;
  String clientName = '';
  String invoiceNumber = '';
  DateTime issueDate = DateTime.now();
  DateTime? dueDate;
  String subject = '';
  String notes = '';
  List<InvoiceItem> items = [];
  bool applyTva = false;
  String paymentMethod = 'MTN';

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get tvaAmount {
    return applyTva ? subtotal * 0.18 : 0.0;
  }

  double get totalAmount {
    return subtotal + tvaAmount;
  }
}

class InvoiceItem {
  String description;
  int quantity;
  double unitPrice;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }
}