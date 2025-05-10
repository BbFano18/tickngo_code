import 'dart:convert';
import 'package:http/http.dart' as http;

import '../API/api_config.dart';

class CinemaService {
  static Future<List<Map<String, dynamic>>> getCinemas() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl + ApiConfig.cinemaPath}'),
      headers: {'Accept': 'application/json'},
    );
    if (response.statusCode == 202) {
      final data = json.decode(response.body)['data'] as List;
      return data.map((c) => {
        'id_centre': c['id_centre'],
        'name': c['nom_centre'] ,
        'logo': c['logo'] ,
      }).toList();
    }
    throw Exception('Erreur de chargement');
  }
}