import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../API/api_config.dart';

class EventModel {
  final int? id;
  final int idCentre;
  final String nomEvent;
  final String dateEvent;
  final String? imageUrl;
  final String lieuEvent;
  final int tarifStandard;
  final int tarifVIP;
  final int? tarifVVIP;

  EventModel({
    this.id,
    required this.idCentre,
    required this.nomEvent,
    required this.dateEvent,
    this.imageUrl,
    required this.lieuEvent,
    required this.tarifStandard,
    required this.tarifVIP,
    this.tarifVVIP,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id_event'],
      idCentre: json['id_centre'],
      nomEvent: json['nom_event'],
      dateEvent: json['date_event'],
      imageUrl: json['image'],
      lieuEvent: json['lieu_event'],
      tarifStandard: json['tarif_standard'],
      tarifVIP: json['tarif_VIP'],
      tarifVVIP: json['tarif_VVIP'],
    );
  }

  Map<String, String> toJson() {
    final map = {
      'id_centre': idCentre.toString(),
      'nom_event': nomEvent,
      'date_event': dateEvent,
      'lieu_event': lieuEvent,
      'tarif_standard': tarifStandard.toString(),
      'tarif_VIP': tarifVIP.toString(),
    };

    if (tarifVVIP != null) {
      map['tarif_VVIP'] = tarifVVIP.toString();
    }

    if (id != null) {
      map['id_event'] = id.toString();
    }

    return map;
  }
}

class EventService {
  // Récupérer les événements
  Future<List<Map<String, dynamic>>> fetchEvents(int centreId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}centre/$centreId/evenement'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 201) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Échec du chargement des événements: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des événements: $e');
      throw e;
    }
  }

  // Ajouter un événement
  Future<int> addEvent(Map<String, dynamic> eventData) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}evenement');
      final request = http.MultipartRequest('POST', uri);

      request.fields['id_centre'] = eventData['id_centre'].toString();
      request.fields['nom_event'] = eventData['nom_event'];
      request.fields['date_event'] = eventData['date_event'];
      request.fields['lieu_event'] = eventData['lieu_event'];
      request.fields['tarif_standard'] = eventData['tarif_standard'].toString();
      request.fields['tarif_VIP'] = eventData['tarif_VIP'].toString();

      if (eventData['tarif_VVIP'] != null) {
        request.fields['tarif_VVIP'] = eventData['tarif_VVIP'].toString();
      }

      final file = File(eventData['image']);
      final fileExtension = file.path.split('.').last.toLowerCase();

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          file.path,
          contentType: MediaType('image', fileExtension),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Réponse brute: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData['id_event'] ?? 0;
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de l\'ajout de l\'événement: $e');
      throw e;
    }
  }

  // Supprimer un événement
  Future<bool> deleteEvent(int eventId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}evenement/$eventId'),
        headers: {'Accept': 'application/json'},
      );

      print('Delete status: ${response.statusCode}, body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la suppression de l\'événement: $e');
      throw e;
    }
  }

  // Mettre à jour un événement
  Future<bool> updateEvent(int eventId, Map<String, dynamic> eventData, {String? newImagePath}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}evenement/$eventId');
      final request = http.MultipartRequest('PUT', uri);

      request.fields['nom_event'] = eventData['nom_event'];
      request.fields['date_event'] = eventData['date_event'];
      request.fields['lieu_event'] = eventData['lieu_event'];
      request.fields['tarif_standard'] = eventData['tarif_standard'].toString();
      request.fields['tarif_VIP'] = eventData['tarif_VIP'].toString();

      if (eventData['tarif_VVIP'] != null) {
        request.fields['tarif_VVIP'] = eventData['tarif_VVIP'].toString();
      }

      if (newImagePath != null) {
        final file = File(newImagePath);
        final fileExtension = file.path.split('.').last.toLowerCase();

        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            file.path,
            contentType: MediaType('image', fileExtension),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('Update status: ${response.statusCode}, body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'événement: $e');
      throw e;
    }
  }
}
