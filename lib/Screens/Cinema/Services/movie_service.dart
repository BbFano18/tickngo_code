import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../API/api_config.dart';

Future<List<Map<String, dynamic>>> getProgrammesByFilm(int idFilm) async {
  try {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}programme/$idFilm/films')
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return (decoded['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  } catch (e) {
    print('Erreur getProgrammesByFilm: $e');
    return [];
  }
}

Future<bool> deleteProgramme(int idProg) async {
  try {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}programme/$idProg')
    );
    return response.statusCode == 200;
  } catch (e) {
    print('Erreur deleteProgramme: $e');
    return false;
  }
}

Future<bool> addSchedule(Map<String, dynamic> programData) async {
  try {
    if (programData['id_film'] == null) {
      throw Exception('ID du film requis');
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}programme');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_jour': programData['id_jour'],
        'id_film': programData['id_film'],
        'heure': programData['heure'],
        'id_event': programData['id_event'] ?? null,
        'id_jeux': programData['id_jeux'] ?? null,
      }),
    );
    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      return decoded['success'] == true || decoded['status'] == 'success';
    }
    print('Erreur API ${response.statusCode}: ${response.body}');
    return false;
  } catch (e) {
    print('Erreur addSchedule: $e');
    return false;
  }
}

Future<bool> updateMovieProgrammes(
    dynamic id_film, List<Map<String, dynamic>> programmes) async {
  try {
    // Supprimer d'abord tous les programmes existants
    final existingProgrammes = await getProgrammesByFilm(id_film);
    for (var prog in existingProgrammes) {
      await deleteProgramme(prog['id_prog']);
    }

    // Ajouter les nouveaux programmes
    bool allSuccess = true;
    for (var programme in programmes) {
      final success = await addSchedule({'id_film': id_film,
        'id_jour': programme['id_jour'],
        'heure': programme['heure'],
      });
      if (!success) {
        allSuccess = false;
        break;
      }
    }

    return allSuccess;
  } catch (e) {
    print('Erreur lors de la mise à jour des programmes: $e');
    return false;
  }
} 