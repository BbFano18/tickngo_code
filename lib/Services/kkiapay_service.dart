import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

import '../API/api_config.dart';


class PaymentTransaction {
  final String id;
  final double amount;
  final String status;
  final String? paymentMethod;
  final DateTime timestamp;
  final String? receiptUrl;
  final Map<String, dynamic> metadata;

  PaymentTransaction({
    required this.id,
    required this.amount,
    required this.status,
    this.paymentMethod,
    required this.timestamp,
    this.receiptUrl,
    required this.metadata,
  });

  factory PaymentTransaction.fromKkiapayResponse(Map<String, dynamic> data) {
    return PaymentTransaction(
      id: data['transactionId'] ?? '',
      amount: _parseAmount(data['amount']),
      status: data['status'] ?? 'PENDING',
      paymentMethod: data['paymentMethod'],
      timestamp: _parseDate(data['createdAt']),
      receiptUrl: data['receiptUrl'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  static double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    try {
      return double.parse(value.toString());
    } catch (_) {
      return 0.0;
    }
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'status': status,
      'paymentMethod': paymentMethod,
      'timestamp': timestamp.toIso8601String(),
      'receiptUrl': receiptUrl,
      'metadata': metadata,
    };
  }
}
class Ticket {
  final String id;
  final String eventTitle;
  final String ticketType;
  final String category;
  final int quantity;
  final double price;
  final String transactionId;
  final DateTime purchaseDate;
  final String qrCode;

  Ticket({
    required this.id,
    required this.eventTitle,
    required this.ticketType,
    required this.category,
    required this.quantity,
    required this.price,
    required this.transactionId,
    required this.purchaseDate,
    required this.qrCode,
  });

  // Convertion ticket en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventTitle': eventTitle,
      'ticketType': ticketType,
      'category': category,
      'quantity': quantity,
      'price': price,
      'transactionId': transactionId,
      'purchaseDate': purchaseDate.toIso8601String(),
      'qrCode': qrCode,
    };
  }

  //Crée un ticket JSON
  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      eventTitle: json['eventTitle'],
      ticketType: json['ticketType'],
      category: json['category'],
      quantity: json['quantity'],
      price: (json['price'] as num).toDouble(),
      transactionId: json['transactionId'],
      purchaseDate: DateTime.parse(json['purchaseDate']),
      qrCode: json['qrCode'],
    );
  }

  // date
  String get formattedDate {
    final date = purchaseDate;
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} à "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }
}

class KKiapayService {
  final String _apiKey;
  final String _privateKey;
  final bool _isSandbox;

  KKiapayService({
    required String apiKey,
    required String privateKey,
    bool isSandbox = true,
  })  : _apiKey = apiKey,
        _privateKey = "pk_36b81a3083924f93861a4cd5791dd8be4a8e21d4b33eccf4a7adacb2e8393ffe",
        _isSandbox = isSandbox;
  // Vérifie un paiement avec l'ID de transaction
  Future<Map<String, dynamic>> verifyPayment(String transactionId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl} + paiement/verifier'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': _privateKey,
        },
        body: jsonEncode({
          'transactionId': transactionId,
        }),
      );

      if (response.statusCode == 202) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception(
            'Échec de la vérification du paiement: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la vérification du paiement: $e');
    }
  }

  // Génère un code QR simulé pour un ticket
  String generateTicketQrCode(String ticketId, String eventId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'TNG-$eventId-$ticketId-$timestamp-$random';
  }

  //Crée une liste de tickets après paiement réussi
  Future<List<Ticket>> createTickets({
    required String transactionId,
    required String eventTitle,
    required String ticketType,
    required String category,
    required int quantity,
    required double totalPrice,
  }) async {
    List<Ticket> tickets = [];

    final unitPrice = (quantity > 0) ? totalPrice / quantity : totalPrice;

    for (int i = 0; i < quantity; i++) {
      final ticketId = 'TKT-${DateTime.now().millisecondsSinceEpoch}-$i';
      final qrCode = generateTicketQrCode(
        ticketId,
        eventTitle.hashCode.toString(),
      );

      tickets.add(Ticket(
        id: ticketId,
        eventTitle: eventTitle,
        ticketType: ticketType,
        category: category,
        quantity: 1,
        price: unitPrice,
        transactionId: transactionId,
        purchaseDate: DateTime.now(),
        qrCode: qrCode,
      ));
    }

    // Simuler un appel réseau
    await Future.delayed(const Duration(seconds: 1));

    return tickets;
  }
}
