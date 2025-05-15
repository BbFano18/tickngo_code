import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../Config/kkiapay_config.dart';

import '../API/api_config.dart';

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

  String get formattedDate {
    final date = purchaseDate;
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} à "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }
}

class PaymentTransaction {
  final String id;
  final String status;
  final double amount;
  final DateTime timestamp;
  final String? paymentMethod;
  final Map<String, dynamic> metadata;

  PaymentTransaction({
    required this.id,
    required this.status,
    required this.amount,
    required this.timestamp,
    this.paymentMethod,
    required this.metadata,
  });

  factory PaymentTransaction.fromKkiapayResponse(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['transactionId'] ?? '',
      status: json['status'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      timestamp: DateTime.now(),
      paymentMethod: json['paymentMethod'],
      metadata: json['metadata'] ?? {},
    );
  }
}

class KkiapayService {
  final bool isSandbox;
  final String apiKey;
  final String? privateKey;

  KkiapayService({
    this.isSandbox = KkiapayConfig.IS_SANDBOX,
    this.apiKey = KkiapayConfig.SANDBOX_PUBLIC_KEY,
    this.privateKey = KkiapayConfig.SANDBOX_PRIVATE_KEY,
  });

  String get baseUrl => isSandbox ? KkiapayConfig.SANDBOX_URL : KkiapayConfig.PRODUCTION_URL;
  String get widgetUrl => isSandbox ? KkiapayConfig.SANDBOX_WIDGET_URL : KkiapayConfig.PRODUCTION_WIDGET_URL;

  Widget buildPaymentWidget({
    required double amount,
    required String name,
    required String reason,
    required Function(PaymentTransaction) onSuccess,
    required Function(String) onError,
  }) {
    final String paymentUrl = _buildPaymentUrl(
      amount: amount,
      name: name,
      reason: reason,
    );

    late final WebViewController controller;

    return WebViewWidget(
      controller: controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              if (request.url.startsWith(KkiapayConfig.SUCCESS_CALLBACK)) {
                _handlePaymentSuccess(request.url, amount, name, reason, onSuccess);
                return NavigationDecision.prevent;
              } else if (request.url.startsWith(KkiapayConfig.CANCEL_CALLBACK)) {
                onError('Paiement annulé');
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
            onWebResourceError: (WebResourceError error) {
              onError('Erreur de chargement: ${error.description}');
            },
          ),
        )
        ..loadRequest(Uri.parse(paymentUrl)),
    );
  }

  String _buildPaymentUrl({
    required double amount,
    required String name,
    required String reason,
  }) {
    final params = {
      'amount': amount.toString(),
      'name': name,
      'reason': reason,
      'key': apiKey,
      'callback': KkiapayConfig.SUCCESS_CALLBACK,
      'cancel_callback': KkiapayConfig.CANCEL_CALLBACK,
      'sandbox': isSandbox.toString(),
    };

    return Uri.parse(widgetUrl).replace(queryParameters: params).toString();
  }

  Future<void> _handlePaymentSuccess(
    String url,
    double amount,
    String name,
    String reason,
    Function(PaymentTransaction) onSuccess,
  ) async {
    try {
      final uri = Uri.parse(url);
      final transactionId = uri.queryParameters['transactionId'];
      
      if (transactionId != null) {
        final verificationResult = await verifyPayment(transactionId);
        
        if (verificationResult['status'] == 'SUCCESS') {
          final transaction = PaymentTransaction(
            id: transactionId,
            status: 'SUCCESS',
            amount: amount,
            timestamp: DateTime.now(),
            paymentMethod: verificationResult['paymentMethod'],
            metadata: {
              'name': name,
              'reason': reason,
              'verificationData': verificationResult,
            },
          );
          onSuccess(transaction);
        } else {
          throw Exception('Échec de la vérification du paiement');
        }
      } else {
        throw Exception('ID de transaction manquant');
      }
    } catch (e) {
      print('Erreur lors du traitement du paiement: $e');
      throw Exception('Échec du traitement du paiement');
    }
  }

  Future<Map<String, dynamic>> verifyPayment(String transactionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/transactions/$transactionId/verify'),
        headers: {
          'Authorization': 'Bearer ${privateKey ?? KkiapayConfig.SANDBOX_PRIVATE_KEY}',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: KkiapayConfig.REQUEST_TIMEOUT));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur de vérification: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la vérification: $e');
      throw Exception('Échec de la vérification du paiement');
    }
  }

  Future<List<Ticket>> createTickets({
    required String transactionId,
    required String eventTitle,
    required String ticketType,
    required String category,
    required int quantity,
    required double totalPrice,
  }) async {
    try {
      final List<Ticket> tickets = [];
      final unitPrice = (quantity > 0) ? totalPrice / quantity : totalPrice;

      for (int i = 0; i < quantity; i++) {
        final ticketId = 'TKT-${DateTime.now().millisecondsSinceEpoch}-$i';
        final qrCode = 'TNG-${eventTitle.hashCode}-$ticketId-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(10000)}';

        final ticket = Ticket(
          id: ticketId,
          eventTitle: eventTitle,
          ticketType: ticketType,
          category: category,
          quantity: 1,
          price: unitPrice,
          transactionId: transactionId,
          purchaseDate: DateTime.now(),
          qrCode: qrCode,
        );

        await _saveTicketToDatabase(ticket);
        tickets.add(ticket);
      }

      return tickets;
    } catch (e) {
      print('Erreur lors de la création des tickets: $e');
      throw Exception('Échec de la création des tickets');
    }
  }

  Future<void> _saveTicketToDatabase(Ticket ticket) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/tickets'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(ticket.toJson()),
      ).timeout(Duration(seconds: KkiapayConfig.REQUEST_TIMEOUT));

      if (response.statusCode != 201) {
        throw Exception('Échec de la sauvegarde du ticket: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde du ticket: $e');
      throw Exception('Échec de la sauvegarde du ticket');
    }
  }
}
