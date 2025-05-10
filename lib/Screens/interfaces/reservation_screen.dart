import 'package:TicknGo/Screens/interfaces/ticket_confirmation_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Services/kkiapay_service.dart';
import '../../themes/app_theme.dart';
import '../../widgets/kkiapay_widget.dart';


class Reservation {
  final String eventTitle;
  final String eventDate;
  final String eventTime;
  final String eventLocation;
  final Map<String, double> ticketPrices;
  final Map<String, double> categoryPrices;

  Reservation({
    required this.eventTitle,
    required this.eventDate,
    required this.eventTime,
    required this.eventLocation,
    required this.ticketPrices,
    required this.categoryPrices,
  });
}

class ReservationScreen extends StatefulWidget {
  final Reservation reservation;
  const ReservationScreen({super.key, required this.reservation});

  @override
  _ReservationScreenState createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  String selectedTicket = "Adulte";
  String selectedCategory = "Standard";
  int quantity = 1;
  double totalPrice = 0;
  bool isLoading = false;

  final String kkiapayPublicKey = "424553af8d6a69b2e50839a0a6a3eb5e2fc112ec";
  final String kkiapayPrivateKey = "pk_36b81a3083924f93861a4cd5791dd8be4a8e21d4b33eccf4a7adacb2e8393ffe";

  late KKiapayService kkiapayService;

  @override
  void initState() {
    super.initState();
    _calculateTotal();
    kkiapayService = KKiapayService(
      apiKey: kkiapayPublicKey,
      privateKey: kkiapayPrivateKey,
      isSandbox: true,

    );
  }

  void _calculateTotal() {
    final ticketPrice = widget.reservation.ticketPrices[selectedTicket] ?? 0;
    final categoryPrice = widget.reservation.categoryPrices[selectedCategory] ??
        0;
    setState(() => totalPrice = (ticketPrice + categoryPrice) * quantity);
  }

  void _initiatePayment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return Container(
          height: MediaQuery
              .of(context)
              .size
              .height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: KKiapayWidget(
            apiKey: kkiapayPublicKey,
            amount: totalPrice,
            reason:
            "Achat de $quantity ticket(s) $selectedTicket - $selectedCategory pour ${widget
                .reservation.eventTitle}",
            phone: "",
            name: "",
            isSandbox: true,
            onPaymentSuccess: (dynamic response) async {
              final transactionId = response['transactionId'];
              if (!mounted) return;
              Navigator.pop(context);
              setState(() => isLoading = true);
              await Future.delayed(Duration(seconds: 2));
              try {
                final paymentData =
                await kkiapayService.verifyPayment(transactionId);
                final Map<String, dynamic> responseData =
                Map<String, dynamic>.from(paymentData);

                // Assure que "metadata" existe
                responseData['metadata'] ??= {};

                final eventMetadata = {
                  'eventTitle': widget.reservation.eventTitle,
                  'ticketType': selectedTicket,
                  'category': selectedCategory,
                  'quantity': quantity,
                  'eventDate': widget.reservation.eventDate,
                  'eventTime': widget.reservation.eventTime,
                  'eventLocation': widget.reservation.eventLocation,
                };

                responseData['metadata'].addAll(eventMetadata);

                final transaction = PaymentTransaction.fromKkiapayResponse(
                    responseData);
                transaction.metadata.addAll(eventMetadata);

                final tickets = await kkiapayService.createTickets(
                  transactionId: transactionId,
                  eventTitle: widget.reservation.eventTitle,
                  ticketType: selectedTicket,
                  category: selectedCategory,
                  quantity: quantity,
                  totalPrice: totalPrice,
                );

                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TicketConfirmationScreen(
                          transaction: transaction,
                          tickets: tickets,
                        ),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        "Erreur lors de la vérification du paiement : $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (mounted) setState(() => isLoading = false);
              }
            },
            onPaymentError: (String reason) {
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Paiement échoué : $reason"),
                  backgroundColor: Colors.red,
                ),
              );
            },
            onPaymentClosed: () {
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Paiement annulé"),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
        );
      },
    );
  }


  // Interface utilisateur pour sélectionner le type de ticket
  Widget _buildTicketTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Type de ticket",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedTicket,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              items: widget.reservation.ticketPrices.keys.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedTicket = newValue;
                    _calculateTotal();
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // Interface utilisateur pour sélectionner la catégorie
  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Catégorie",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCategory,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              items: widget.reservation.categoryPrices.keys.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedCategory = newValue;
                    _calculateTotal();
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // Interface utilisateur pour sélectionner la quantité
  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quantité",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            IconButton(
              onPressed: () {
                if (quantity > 1) {
                  setState(() {
                    quantity--;
                    _calculateTotal();
                  });
                }
              },
              icon: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.remove, color: AppTheme.primaryColor),
              ),
            ),
            Text(
              quantity.toString(),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  quantity++;
                  _calculateTotal();
                });
              },
              icon: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.add, color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Résumé de la commande
  Widget _buildOrderSummary() {
    final ticketPrice = widget.reservation.ticketPrices[selectedTicket] ?? 0;
    final categoryPrice = widget.reservation.categoryPrices[selectedCategory] ??
        0;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey.shade100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Résumé de la commande",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Ticket $selectedTicket"),
              Text("${ticketPrice.toStringAsFixed(0)} FCFA"),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Catégorie $selectedCategory"),
              Text("${categoryPrice.toStringAsFixed(0)} FCFA"),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Quantité"),
              Text("$quantity"),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${totalPrice.toStringAsFixed(0)} FCFA",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Réservation"),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: true,
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations sur l'événement
                    Text(
                      widget.reservation.eventTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "${widget.reservation.eventDate} à ${widget.reservation
                          .eventTime}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      widget.reservation.eventLocation,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Formulaire
                    _buildTicketTypeSelector(),
                    const SizedBox(height: 20),
                    _buildCategorySelector(),
                    const SizedBox(height: 20),
                    _buildQuantitySelector(),
                    const SizedBox(height: 20),
                    _buildOrderSummary(),

                    const SizedBox(height: 30),

                    // Bouton de paiement
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _initiatePayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                          "Payer maintenant",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Indicateur de chargement centré
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}