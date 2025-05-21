import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../../themes/app_theme.dart';
import 'dart:math';

class TicketPurchaseScreen extends StatelessWidget {
  final String centreName;
  final String eventTitle;
  final String eventType;
  final double amount;
  final String transactionId;
  final DateTime purchaseDateTime;
  final String ticketType;
  final int quantity;
  final String eventDate;
  final String eventTime;
  final String userName;

  const TicketPurchaseScreen({
    Key? key,
    required this.centreName,
    required this.eventTitle,
    required this.eventType,
    required this.amount,
    required this.transactionId,
    required this.purchaseDateTime,
    required this.ticketType,
    required this.quantity,
    required this.eventDate,
    required this.eventTime,
    required this.userName,
  }) : super(key: key);

  String _generateTicketId() {
    Random random = Random();
    String ticketId = '';
    for (int i = 0; i < 8; i++) {
      ticketId += random.nextInt(10).toString();
    }
    return ticketId;
  }

  Future<void> _generateAndSavePDF() async {
    final pdf = pw.Document();
    final pricePerTicket = amount / quantity;

    for (int i = 0; i < quantity; i++) {
      final ticketId = _generateTicketId();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('TICKNGO',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold
                            )
                          ),
                          pw.Text('v1.0.0'),
                        ],
                      ),
                      pw.BarcodeWidget(
                        data: '$userName-$ticketId',
                        width: 100,
                        height: 100,
                        barcode: pw.Barcode.qrCode(),
                      ),
                    ]
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    centreName,
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    eventTitle,
                    style: pw.TextStyle(fontSize: 18),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(),
                  _buildPDFInfoRow('Type', eventType),
                  _buildPDFInfoRow('Catégorie', ticketType),
                  _buildPDFInfoRow('Prix', '${pricePerTicket.toStringAsFixed(0)} FCFA'),
                  _buildPDFInfoRow('Date', '$eventDate à $eventTime'),
                  pw.Divider(),
                  _buildPDFInfoRow('ID Ticket', ticketId),
                  _buildPDFInfoRow('Date d\'achat',
                    '${purchaseDateTime.day}/${purchaseDateTime.month}/${purchaseDateTime.year} '
                    '${purchaseDateTime.hour}:${purchaseDateTime.minute}'),
                ],
              ),
            );
          },
        ),
      );
    }

    final output = await getTemporaryDirectory();
    final pdfFile = File('${output.path}/tickets.pdf');
    await pdfFile.writeAsBytes(await pdf.save());

    final downloadDir = Directory('/storage/emulated/0/Download');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }

    final savedFile = File('${downloadDir.path}/tickets_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await pdfFile.copy(savedFile.path);

    await Share.shareFiles([pdfFile.path], text: 'Mes tickets TICKNGO');
  }

  pw.Widget _buildPDFInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pricePerTicket = amount / quantity;
    return Scaffold(
      backgroundColor: AppTheme.primaryLightColor,
      appBar: AppBar(
        title: const Text('Confirmation d\'achat'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  eventTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  centreName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quantity,
              itemBuilder: (context, index) {
                final ticketId = _generateTicketId();
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLightColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ticket #${index + 1}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                Text(
                                  'ID: $ticketId',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    spreadRadius: 0,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: '$userName-$ticketId',
                                version: QrVersions.auto,
                                size: 80.0,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow('Type', eventType),
                            _buildInfoRow('Catégorie', ticketType),
                            _buildInfoRow('Prix', '${pricePerTicket.toStringAsFixed(0)} FCFA'),
                            _buildInfoRow('Date', '$eventDate à $eventTime'),
                            const Divider(height: 20),
                            _buildInfoRow('Date d\'achat',
                              '${purchaseDateTime.day}/${purchaseDateTime.month}/${purchaseDateTime.year} '
                              '${purchaseDateTime.hour}:${purchaseDateTime.minute}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${amount.toStringAsFixed(0)} FCFA',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generateAndSavePDF,
                    icon: const Icon(Icons.download),
                    label: const Text('Télécharger tous les tickets'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 