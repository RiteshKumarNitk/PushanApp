import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:printing/printing.dart';
// Actually better to pass a generic Map or DTO to decouple, but for speed we'll use the model structure we know.
// Let's assume we pass the data needed directly.

class InvoiceService {
  static Future<Uint8List> generateInvoice({
    required String orderId,
    required DateTime date,
    required String customerName,
    required String customerBusiness,
    required String customerAddress,
    required List<Map<String, dynamic>> items, // {name, quantity, unit_price, total}
    required double grandTotal,
  }) async {
    final pdf = pw.Document();
    
    // Custom Font handling could go here (e.g. GoogleFonts.cormorantGaramond)
    // For now using standard fonts

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("SHAHI CHAI ORDERS", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.brown900)),
                        pw.Text("Royal Indian Tea Wholesalers", style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Text("INVOICE", style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.brown900)),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Info Row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Bill To:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(customerBusiness.isNotEmpty ? customerBusiness : customerName),
                      if (customerAddress.isNotEmpty) pw.Text(customerAddress),
                      pw.Text("VIP Member"),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Invoice #: INV-${orderId.substring(0, 8).toUpperCase()}"),
                      pw.Text("Date: ${date.day}/${date.month}/${date.year}"),
                      pw.Text("Due Date: On Receipt"),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Items Table
              pw.Table.fromTextArray(
                context: context,
                border: null,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.brown900),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                headerHeight: 25,
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
                headers: ['Item Description', 'Quantity', 'Unit Price', 'Total'],
                data: items.map((item) {
                  return [
                    item['name'],
                    '${item['quantity']}',
                    'INR ${item['unit_price']}',
                    'INR ${item['total']}',
                  ];
                }).toList(),
              ),

              pw.Divider(),

              // Total
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text("Grand Total: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Text("INR ${grandTotal.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: PdfColors.brown900)),
                  ],
                ),
              ),

              pw.SizedBox(height: 50),

              // Footer
              pw.Divider(color: PdfColors.grey),
              pw.Center(
                child: pw.Text("Thank you for your business. For any queries, contact admin@shahichai.com", style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
