import 'dart:convert';
import 'package:http/http.dart' as http;

class Ticket {
  final int idTicket;
  final DateTime dateTicket;
  final double montantTicket;
  final int idStatut;
  final int? id;
  final int? idFilm;
  final int? idEvent;
  final int? idJeux;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? statut;

  Ticket({
    required this.idTicket,
    required this.dateTicket,
    required this.montantTicket,
    required this.idStatut,
    this.id,
    this.idFilm,
    this.idEvent,
    this.idJeux,
    this.createdAt,
    this.updatedAt,
    this.statut,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      idTicket: json['id_ticket'],
      dateTicket: DateTime.parse(json['date_ticket']),
      montantTicket: (json['montant_ticket'] as num).toDouble(),
      idStatut: json['id_statut'],
      id: json['id'],
      idFilm: json['id_film'],
      idEvent: json['id_event'],
      idJeux: json['id_jeux'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      statut: json['statut'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_ticket': idTicket,
      'date_ticket': dateTicket.toIso8601String(),
      'montant_ticket': montantTicket,
      'id_statut': idStatut,
      'id_film': idFilm,
      'id_event': idEvent,
      'id_jeux': idJeux,
    };
  }
}

class TicketService {
  static const String _baseUrl = 'https://votre-api.com/tickets';
  static const String _apiKey = 'votre-cle-api';

  Future<void> createTicket({
    required Ticket ticket,
    required String authToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'X-API-Key': _apiKey,
        },
        body: json.encode({'data': ticket.toJson()}),
      );

      _handleResponse(response);
    } catch (e) {
      throw Exception('Erreur de création du ticket: ${e.toString()}');
    }
  }

  void _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 201:
        return;
      case 400:
        throw const FormatException('Requête invalide');
      case 401:
        throw const FormatException('Non autorisé');
      case 404:
        throw const FormatException('Ressource non trouvée');
      default:
        throw Exception('Erreur serveur: ${response.statusCode}');
    }
  }
}