import 'package:TicknGo/Screens/interfaces/ticket_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../themes/app_theme.dart';
import 'package:kkiapay_flutter_sdk/kkiapay_flutter_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

//  les états de paiement
const String PAYMENT_CANCELLED = "PAYMENT_CANCELLED";
const String PENDING_PAYMENT = "PENDING_PAYMENT";
const String PAYMENT_INIT = "PAYMENT_INIT";
const String PAYMENT_SUCCESS = "PAYMENT_SUCCESS";
const String PAYMENT_FAILED = "PAYMENT_FAILED";

enum ReservationType {
  film,
  jeu,
  evenement
}

class Reservation {
  final String eventTitle;
  final String eventDate;
  final String eventTime;
  final String eventLocation;
  final Map<String, double> ticketPrices;
  final Map<String, double> categoryPrices;
  final ReservationType type;
  final String? duration;
  final int? minimumAge;
  final String? classification;
  final String centreName;
  final String? fixedCategory;

  Reservation({
    required this.eventTitle,
    required this.eventDate,
    required this.eventTime,
    required this.eventLocation,
    required this.ticketPrices,
    required this.categoryPrices,
    required this.type,
    this.duration,
    this.minimumAge,
    this.classification,
    required this.centreName,
    this.fixedCategory,
  });
}

class ReservationScreen extends StatefulWidget {
  final Reservation reservation;
  const ReservationScreen({super.key, required this.reservation});

  @override
  _ReservationScreenState createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  String? selectedTicketType;
  String? selectedCategory;
  int quantity = 1;
  double totalPrice = 0;
  bool isLoading = false;
  String? _userName;
  String? _userPhone;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _initializeSelection();
    _calculateTotal();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name');
    });
  }

  void _initializeSelection() {
    if (widget.reservation.type == ReservationType.evenement) {
      if (widget.reservation.categoryPrices.isNotEmpty) {
        selectedCategory = widget.reservation.categoryPrices.keys.first;
      }
    } else {
      selectedTicketType = null;
    }
  }

  void _calculateTotal() {
    double total = 0;

    if (widget.reservation.type == ReservationType.evenement) {
      total = widget.reservation.categoryPrices[selectedCategory] ?? 0;
    } else {
      if (selectedTicketType != null) {
        total = widget.reservation.ticketPrices[selectedTicketType] ?? 0;
      }
    }

    setState(() => totalPrice = total * quantity);
  }

  Future<void> successCallback(response, context) async {
    if (response is Map<String, dynamic>) {
      switch (response['status']) {
        case PAYMENT_CANCELLED:
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Paiement annulé")),
            );
            Navigator.pop(context);
          } catch (e) {
            debugPrint(e.toString());
          }
          break;

        case PENDING_PAYMENT:
          debugPrint(PENDING_PAYMENT);
          break;

        case PAYMENT_INIT:
          debugPrint(PAYMENT_INIT);
          break;

        case PAYMENT_SUCCESS:
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Paiement réussi")),
            );
            
            // Naviguer vers la page de détails du ticket
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TicketDetailsScreen(
                  ticket: {
                    'id': response['transactionId'] ?? 'N/A',
                    'type': _getReservationType(),
                    'titre': widget.reservation.eventTitle,
                    'date': widget.reservation.eventDate,
                    'heure': widget.reservation.eventTime,
                    'lieu': widget.reservation.eventLocation,
                    'prix': totalPrice,
                    'categorie': widget.reservation.type == ReservationType.evenement
                        ? selectedCategory ?? 'Standard'
                        : selectedTicketType ?? 'Standard',
                    'qrData': '${response['transactionId']}-${widget.reservation.eventTitle}',
                    'status': 'valide',
                    'description': widget.reservation.duration != null
                        ? 'Durée: ${widget.reservation.duration}'
                        : null,
                  },
                ),
              ),
            );
          } catch (e) {
            debugPrint(e.toString());
          }
          break;

        case PAYMENT_FAILED:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Échec du paiement")),
          );
          break;

        default:
          break;
      }
    } else {
      debugPrint('Response is not a Map: $response');
    }
  }

  String _getReservationType() {
    switch (widget.reservation.type) {
      case ReservationType.film:
        return "Film";
      case ReservationType.jeu:
        return "Jeu";
      case ReservationType.evenement:
        return "Événement";
    }
  }

  void _initiateKkiapayPayment() {
    String reference = "TICKNGO${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10)}";
    String reservationType = _getReservationType();
    
    final kkiapay = KKiaPay(
      amount: totalPrice.toInt(),
      countries: ["BJ"],
      phone: "22961000000",
      name: _userName,
      email:_userEmail ,
      reason: "Réservation $reservationType - ${widget.reservation.eventTitle}",
      data: 'Reservation data',
      sandbox: true,
      apikey: 'de3b91d004ab11f08e9fcf9f74583c43',
      callback: successCallback,
      theme: '#7F56D9FF',
      partnerId: reference,
      paymentMethods: ["momo", "card"],
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => kkiapay,
        ),
      );
    }
  }

  Widget _buildTicketTypeSelector() {
    if (widget.reservation.type == ReservationType.evenement) {
      return _buildEventCategorySelector();
    }

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
        ...widget.reservation.ticketPrices.entries.map((entry) {
          bool isDisabled = (widget.reservation.type == ReservationType.film &&
                          entry.key == "Enfant" &&
                          widget.reservation.classification == "Moins 18") ||
                          (widget.reservation.type == ReservationType.jeu &&
                          entry.key == "Enfant" &&
                          (widget.reservation.minimumAge ?? 0) >= 18);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: RadioListTile<String>(
              title: Text(
                entry.key,
                style: GoogleFonts.poppins(
                  color: isDisabled ? Colors.grey : Colors.black,
                ),
              ),
              subtitle: Text(
                "${entry.value.toStringAsFixed(0)} FCFA",
                style: GoogleFonts.poppins(
                  color: isDisabled ? Colors.grey : Colors.black87,
                ),
              ),
              value: entry.key,
              groupValue: selectedTicketType,
              onChanged: isDisabled ? null : (String? value) {
                setState(() {
                  selectedTicketType = value;
                  _calculateTotal();
                });
              },
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEventCategorySelector() {
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
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedCategory,
              items: widget.reservation.categoryPrices.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text("${entry.value.toStringAsFixed(0)} FCFA"),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedCategory = newValue;
                  _calculateTotal();
                });
              },
            ),
          ),
        ),
      ],
    );
  }

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

  Widget _buildOrderSummary() {
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
              Text(widget.reservation.type == ReservationType.evenement
                  ? "Catégorie"
                  : "Type de ticket"),
              Text(
                widget.reservation.type == ReservationType.evenement
                    ? selectedCategory ?? "Non sélectionné"
                    : selectedTicketType ?? "Non sélectionné"
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Prix unitaire"),
              Text(
                widget.reservation.type == ReservationType.evenement
                    ? "${widget.reservation.categoryPrices[selectedCategory]?.toStringAsFixed(0) ?? '0'} FCFA"
                    : "${widget.reservation.ticketPrices[selectedTicketType]?.toStringAsFixed(0) ?? '0'} FCFA"
              ),
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

  Widget _buildEventDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.reservation.eventTitle,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        if (widget.reservation.duration != null)
          Text(
            "Durée: ${widget.reservation.duration}",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        if (widget.reservation.eventDate.isNotEmpty)
          Text(
            "${widget.reservation.eventDate} à ${widget.reservation.eventTime}",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        Text(
          "${widget.reservation.eventLocation} (${widget.reservation.centreName})",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        if (widget.reservation.classification != null)
          Text(
            "Classification: ${widget.reservation.classification}",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        if (widget.reservation.minimumAge != null)
          Text(
            "Âge minimum: ${widget.reservation.minimumAge} ans",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Réservation"),
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
                  _buildEventDetails(),
                  const SizedBox(height: 20),
                  _buildTicketTypeSelector(),
                  const SizedBox(height: 20),
                  _buildQuantitySelector(),
                  const SizedBox(height: 20),
                  _buildOrderSummary(),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _initiateKkiapayPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
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
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}