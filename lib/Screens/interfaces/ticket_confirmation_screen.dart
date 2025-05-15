import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr_flutter;
import 'dart:math' as math;
import '../../Services/kkiapay_service.dart';
import 'package:share_plus/share_plus.dart';

class TicketConfirmationScreen extends StatelessWidget {
  final List<Ticket> tickets;
  final PaymentTransaction transaction;

  const TicketConfirmationScreen({
    Key? key,
    required this.tickets,
    required this.transaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildSuccessMessage(),
                        const SizedBox(height: 30),
                        _buildTransactionDetails(),
                        const SizedBox(height: 30),
                        _buildTicketList(),
                        const SizedBox(height: 30),
                        _buildShareButton(),
                        const SizedBox(height: 20),
                        _buildDownloadButton(context),
                        const SizedBox(height: 20),
                        _buildBackButton(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // App bar with title and close button
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          Text(
            "Confirmation",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 40), // to balance spacing
        ],
      ),
    );
  }

  // Success message UI
  Widget _buildSuccessMessage() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 50),
        ),
        const SizedBox(height: 20),
        Text(
          "Paiement réussi !",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Vos tickets ont été générés avec succès",
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Transaction summary
  Widget _buildTransactionDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          _buildTransactionRow("ID Transaction", "${transaction.id.substring(0, 10)}..."),
          const Divider(color: Colors.white24, height: 30),
          _buildTransactionRow("Montant", "${transaction.amount.toStringAsFixed(2)} CFA"),
          const Divider(color: Colors.white24, height: 30),
          _buildTransactionRow("Date", _formatDate(transaction.timestamp)),
          const Divider(color: Colors.white24, height: 30),
          _buildTransactionRow("Méthode", transaction.paymentMethod ?? "Mobile Money"),
        ],
      ),
    );
  }

  // Generic transaction row
  Widget _buildTransactionRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }

  // Ticket list
  Widget _buildTicketList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Vos tickets (${tickets.length})",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 15),
        ...tickets.map((ticket) => _buildTicketItem(ticket)).toList(),
      ],
    );
  }

  // Ticket card UI
  Widget _buildTicketItem(Ticket ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.confirmation_number, color: Colors.deepPurple, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.eventTitle,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 5),
                Text(
                  "Type: ${ticket.ticketType} • Catégorie: ${ticket.category}",
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                ),
                Text(
                  "ID: ${ticket.id.substring(0, 8)}...",
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
          _buildQRPreview(),
        ],
      ),
    );
  }

  // Simulated QR code preview
  Widget _buildQRPreview() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomPaint(painter: QRPreviewPainter()),
    );
  }
  Future<void> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();

    for (var ticket in tickets) {
      final qrCode = await qr_flutter.QrPainter(
        data: ticket.id,
        version: qr_flutter.QrVersions.auto,
        gapless: true,
      ).toImageData(100); // Taille du QR code

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Ticket pour : ${ticket.eventTitle}", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text("Type : ${ticket.ticketType}"),
                pw.Text("Catégorie : ${ticket.category}"),
                pw.Text("Prix : ${ticket.price.toStringAsFixed(2)} CFA"),
                pw.Text("ID Ticket : ${ticket.id}"),
                pw.SizedBox(height: 20),
                pw.Text("QR Code :", style: pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 10),
                if (qrCode != null)
                  pw.Image(pw.MemoryImage(qrCode.buffer.asUint8List()), width: 100, height: 100),
              ],
            ),
          ),
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Download ticket button
  Widget _buildDownloadButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async {
          await _generatePdf(context);
        },
        child: Text(
          "Télécharger les tickets",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Return to home button
  Widget _buildBackButton(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
      child: Text(
        "Retour à l'accueil",
        style: GoogleFonts.poppins(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  // Date formatter
  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildShareButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.share, color: Colors.white),
      label: Text(
        "Partager les tickets",
        style: GoogleFonts.poppins(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () async {
        // Générer le PDF
        final pdf = await _generateTicketsPDF();
        final bytes = await pdf.save();
        
        // Partager le PDF
        await Share.shareXFiles(
          [
            XFile.fromData(
              bytes,
              name: 'tickets.pdf',
              mimeType: 'application/pdf',
            ),
          ],
          subject: 'Mes tickets TicknGo',
          text: 'Voici mes tickets pour l\'événement !',
        );
      },
    );
  }

  // Méthode pour générer le PDF des tickets
  Future<pw.Document> _generateTicketsPDF() async {
    final pdf = pw.Document();

    for (var ticket in tickets) {
      final qrCode = await qr_flutter.QrPainter(
        data: ticket.id,
        version: qr_flutter.QrVersions.auto,
        gapless: true,
      ).toImageData(200);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    "TicknGo - Ticket Électronique",
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  "Ticket pour : ${ticket.eventTitle}",
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text("Type : ${ticket.ticketType}"),
                pw.Text("Catégorie : ${ticket.category}"),
                pw.Text("Prix : ${ticket.price.toStringAsFixed(2)} CFA"),
                pw.Text("ID Ticket : ${ticket.id}"),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "Date d'achat :",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(_formatDate(DateTime.now())),
                      ],
                    ),
                    if (qrCode != null)
                      pw.Image(
                        pw.MemoryImage(qrCode.buffer.asUint8List()),
                        width: 100,
                        height: 100,
                      ),
                  ],
                ),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  "Ce ticket est valide uniquement avec une pièce d'identité.",
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return pdf;
  }
}

// QR code placeholder painter
class QRPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;

    final random = math.Random(42); // Seed for consistency
    final cellSize = size.width / 6;

    for (var i = 0; i < 6; i++) {
      for (var j = 0; j < 6; j++) {
        if (random.nextBool() ||
            (i < 2 && j < 2) ||
            (i < 2 && j > 3) ||
            (i > 3 && j < 2)) {
          canvas.drawRect(
            Rect.fromLTWH(i * cellSize, j * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
// Widget réutilisable pour le fond
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6A3093), // Violet plus foncé
            Color(0xFFA044FF), // Violet plus clair
          ],
        ),
      ),
      child: Stack(
        children: [
          // Éléments décoratifs en arrière-plan
          ...buildBackgroundElements(context),

          // Contenu principal
          child,
        ],
      ),
    );
  }

  List<Widget> buildBackgroundElements(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final random = math.Random(42); // Seed fixe pour générer toujours les mêmes positions

    return [
      // Cercles décoratifs
      Positioned(
        top: -50,
        left: -30,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        bottom: -80,
        right: -40,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
      ),

      // Éléments supplémentaires pour un design plus dynamique
      Positioned(
        top: 120,
        right: 40,
        child: CustomPaint(
          size: Size(60, 60),
          painter: TrianglePainter(Colors.white.withOpacity(0.15)),
        ),
      ),
      Positioned(
        bottom: 150,
        left: 30,
        child: CustomPaint(
          size: Size(40, 40),
          painter: StarPainter(Colors.amber.withOpacity(0.2)),
        ),
      ),

      // Petites étoiles décoratives
      ...List.generate(8, (index) {
        return Positioned(
          top: random.nextDouble() * screenSize.height,
          left: random.nextDouble() * screenSize.width,
          child: Container(
            width: 4 + random.nextDouble() * 6,
            height: 4 + random.nextDouble() * 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3 + random.nextDouble() * 0.4),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    ];
  }
}

// Peintre personnalisé pour le triangle
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width/2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Peintre personnalisé pour l'étoile
class StarPainter extends CustomPainter {
  final Color color;

  StarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;
    final innerRadius = radius * 0.4;

    // Dessiner une étoile à 5 branches
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 2 * math.pi / 5) - math.pi / 2;
      final innerAngle = outerAngle + math.pi / 5;

      if (i == 0) {
        path.moveTo(
            centerX + radius * math.cos(outerAngle),
            centerY + radius * math.sin(outerAngle)
        );
      } else {
        path.lineTo(
            centerX + radius * math.cos(outerAngle),
            centerY + radius * math.sin(outerAngle)
        );
      }

      path.lineTo(
          centerX + innerRadius * math.cos(innerAngle),
          centerY + innerRadius * math.sin(innerAngle)
      );
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

