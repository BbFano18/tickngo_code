import 'package:flutter/material.dart';
import '../../Services/kkiapay_service.dart';
import '../../Config/kkiapay_config.dart';
import '../interfaces/ticket_confirmation_screen.dart';

class KkiapayPaymentScreen extends StatefulWidget {
  final double amount;
  final String eventTitle;
  final String ticketType;
  final String category;
  final int quantity;

  const KkiapayPaymentScreen({
    Key? key,
    required this.amount,
    required this.eventTitle,
    required this.ticketType,
    required this.category,
    required this.quantity,
  }) : super(key: key);

  @override
  _KkiapayPaymentScreenState createState() => _KkiapayPaymentScreenState();
}

class _KkiapayPaymentScreenState extends State<KkiapayPaymentScreen> {
  final KkiapayService _kkiapayService = KkiapayService();
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _kkiapayService.buildPaymentWidget(
                  amount: widget.amount,
                  name: "Achat de tickets - ${widget.eventTitle}",
                  reason: "Tickets ${widget.ticketType} - ${widget.category}",
                  onSuccess: _handlePaymentSuccess,
                  onError: _handlePaymentError,
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Une erreur est survenue',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => _error = null),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePaymentSuccess(PaymentTransaction transaction) async {
    setState(() => _isLoading = true);
    
    try {
      final tickets = await _kkiapayService.createTickets(
        transactionId: transaction.id,
        eventTitle: widget.eventTitle,
        ticketType: widget.ticketType,
        category: widget.category,
        quantity: widget.quantity,
        totalPrice: widget.amount,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TicketConfirmationScreen(
            tickets: tickets,
            transaction: transaction,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Erreur lors de la création des tickets: $e';
      });
    }
  }

  void _handlePaymentError(String error) {
    setState(() {
      _isLoading = false;
      _error = error;
    });
  }
} 