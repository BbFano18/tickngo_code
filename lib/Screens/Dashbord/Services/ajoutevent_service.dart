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
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['data'] as List).cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur fetchEvents: $e');
      return [];
    }
  }

  Future<int> addEvent(Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}evenement');
      final request = http.MultipartRequest('POST', uri);

      // Ajout des champs texte
      request.fields['nom_event'] = data['nom_event'];
      request.fields['date_event'] = data['date_event'];
      request.fields['lieu_event'] = data['lieu_event'];
      request.fields['id_centre'] = data['id_centre'].toString();
      request.fields['tarif_standard'] = data['tarif_standard'].toString();
      request.fields['tarif_VIP'] = data['tarif_VIP'].toString();
      if (data['tarif_VVIP'] != null) {
        request.fields['tarif_VVIP'] = data['tarif_VVIP'].toString();
      }

      // Gestion de l'image
      if (data['image_url'] != null && data['image_url'] is File) {
        final file = data['image_url'] as File;
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();
        
        final multipartFile = http.MultipartFile(
          'image',
          stream,
          length,
          filename: file.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData['data']['id_event'] ?? -1;
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Erreur addEvent: $e');
      throw e;
    }
  }

  Future<bool> updateEvent(int eventId, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}evenement/$eventId');
      final request = http.MultipartRequest('POST', uri);
      request.fields['_method'] = 'PUT';

      // ✅ Ajout du champ id_centre
      if (data['id_centre'] != null) {
        request.fields['id_centre'] = data['id_centre'].toString();
      }

      if (data['nom_event'] != null) request.fields['nom_event'] = data['nom_event'].toString();
      if (data['date_event'] != null) request.fields['date_event'] = data['date_event'].toString();
      if (data['lieu_event'] != null) request.fields['lieu_event'] = data['lieu_event'].toString();
      if (data['tarif_standard'] != null) request.fields['tarif_standard'] = data['tarif_standard'].toString();
      if (data['tarif_VIP'] != null) request.fields['tarif_VIP'] = data['tarif_VIP'].toString();
      if (data['tarif_VVIP'] != null) request.fields['tarif_VVIP'] = data['tarif_VVIP'].toString();

      if (data['image_url'] != null && data['image_url'] is File) {
        final file = data['image_url'] as File;
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();

        final multipartFile = http.MultipartFile(
          'image',
          stream,
          length,
          filename: file.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        return decodedResponse['success'] == true || decodedResponse['status'] == 'success';
      }

      print('Erreur lors de la mise à jour de l\'événement: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('Erreur updateEvent: $e');
      throw Exception('Impossible de mettre à jour l\'événement: $e');
    }
  }


  Future<bool> deleteEvent(int eventId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}evenement/$eventId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur deleteEvent: $e');
      return false;
    }
  }

  /// Récupérer les détails d'un événement
  Future<Map<String, dynamic>?> fetchEventDetails(int eventId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}evenements/$eventId'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des détails de l\'événement: $e');
      return null;
    }
  }
}
