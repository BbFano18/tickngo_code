import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:TicknGo/Screens/interfaces/ticket_confirmation_screen.dart';
import '../../Services/kkiapay_service.dart';
import '../../themes/app_theme.dart';
import '../payment/kkiapay_payment_screen.dart';

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
  Map<String, bool> selectedTickets = {};
  String? selectedCategory;
  int quantity = 1;
  double totalPrice = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeTickets();
    _calculateTotal();
  }

  void _initializeTickets() {
    if (widget.reservation.type == ReservationType.evenement) {
      selectedCategory = widget.reservation.categoryPrices.keys.first;
    } else {
      widget.reservation.ticketPrices.forEach((key, value) {
        selectedTickets[key] = false;
      });
      if (widget.reservation.type == ReservationType.film && widget.reservation.fixedCategory != null) {
        selectedCategory = widget.reservation.fixedCategory;
      }
    }
  }

  void _calculateTotal() {
    double total = 0;

    if (widget.reservation.type == ReservationType.evenement) {
      total = widget.reservation.categoryPrices[selectedCategory] ?? 0;
    } else {
      selectedTickets.forEach((type, isSelected) {
        if (isSelected) {
          total += widget.reservation.ticketPrices[type] ?? 0;
        }
      });

      if (widget.reservation.type == ReservationType.film && widget.reservation.fixedCategory != null) {
        total += widget.reservation.categoryPrices[widget.reservation.fixedCategory] ?? 0;
      }
    }

    setState(() => totalPrice = total * quantity);
  }

  void _initiatePayment() {
    if (widget.reservation.type != ReservationType.evenement && !selectedTickets.values.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner au moins un type de ticket"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (totalPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Le montant total doit être supérieur à 0"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Récupérer le type de ticket sélectionné
    final selectedTicketTypes = selectedTickets.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .join(", ");

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            width: MediaQuery.of(context).size.width * 0.9,
            child: KkiapayPaymentScreen(
              amount: totalPrice,
              eventTitle: widget.reservation.eventTitle,
              ticketType: selectedTicketTypes,
              category: selectedCategory ?? "Standard",
              quantity: quantity,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTicketTypeSelector() {
    if (widget.reservation.type == ReservationType.evenement) {
      return const SizedBox.shrink();
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
            child: CheckboxListTile(
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
              value: selectedTickets[entry.key] ?? false,
              onChanged: isDisabled ? null : (bool? value) {
                setState(() {
                  selectedTickets[entry.key] = value ?? false;
                  _calculateTotal();
                });
              },
              enabled: !isDisabled,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCategorySelector() {
    if (widget.reservation.type == ReservationType.jeu) {
      return const SizedBox.shrink();
    }

    if (widget.reservation.type == ReservationType.film && widget.reservation.fixedCategory != null) {
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.reservation.fixedCategory!),
                Text("${widget.reservation.categoryPrices[widget.reservation.fixedCategory]?.toStringAsFixed(0) ?? '0'} FCFA"),
              ],
            ),
          ),
        ],
      );
    }

    if (widget.reservation.type == ReservationType.evenement) {
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
                items: widget.reservation.categoryPrices.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text("${entry.key} (${entry.value.toStringAsFixed(0)} FCFA)"),
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

    return const SizedBox.shrink();
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
          ...selectedTickets.entries
              .where((entry) => entry.value)
              .map((entry) {
            final price = widget.reservation.ticketPrices[entry.key] ?? 0;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Ticket ${entry.key}"),
                Text("${price.toStringAsFixed(0)} FCFA"),
              ],
            );
          }),
          if (selectedCategory != null) ...[
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Catégorie $selectedCategory"),
                Text("${(widget.reservation.categoryPrices[selectedCategory] ?? 0).toStringAsFixed(0)} FCFA"),
              ],
            ),
          ],
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
    return AppBackground(
      child: Scaffold(
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
                    _buildCategorySelector(),
                    const SizedBox(height: 20),
                    _buildQuantitySelector(),
                    const SizedBox(height: 20),
                    _buildOrderSummary(),
                    const SizedBox(height: 30),
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
      ),
    );
  }
}