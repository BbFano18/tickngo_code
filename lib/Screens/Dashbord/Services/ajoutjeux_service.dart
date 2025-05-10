import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../API/api_config.dart';

class GameService {
  // Helper interne pour récupérer des données depuis n'importe quel endpoint retournant un tableau 'data'.
  Future<List<Map<String, dynamic>>> fetchData(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Erreur API ${response.statusCode}: ${response.body}');
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = decoded['data'] as List? ?? [];
      return raw.map<Map<String, dynamic>>((item) {
        return (item as Map<String, dynamic>).map((k, v) {
          // Assurer qu'il n'y a pas de valeurs nulles
          final val = v ?? (k.startsWith('id') ? 0 : '');
          return MapEntry(k, val);
        });
      }).toList();
    } catch (e) {
      print('Erreur _fetchData($endpoint): $e');
      return [];
    }
  }

  // Récupérer la liste des jeux
  Future<List<Map<String, dynamic>>> fetchGames(int centreId) async {
    try {
      final response =
      await http.get(Uri.parse('${ApiConfig.baseUrl}centre/$centreId/jeux'));
      if (response.statusCode != 201) {
        throw Exception('Erreur ${response.statusCode} - ${response.body}');
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return (decoded['data'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Erreur fetchGames: ${e.toString()}');
      return [];
    }
  }

  // Récupérer les programmations pour un jeu donné
  Future<List<Map<String, dynamic>>> fetchGameSchedules(int gameId) async {
    try {
      final response =
      await http.get(Uri.parse('${ApiConfig.baseUrl}jeux/$gameId/programmes'));
      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode} - ${response.body}');
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return (decoded['data'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Erreur fetchGameSchedules: ${e.toString()}');
      return [];
    }
  }

  // Récupérer la liste des jours disponibles
  Future<List<Map<String, dynamic>>> fetchAvailableDays() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}jour'));
      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode} - ${response.body}');
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return (decoded['data'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Erreur fetchAvailableDays: ${e.toString()}');
      return [];
    }
  }

  // Ajouter un nouveau jeu, éventuellement avec des programmations
  Future addGame(Map<String, dynamic> data) async {
    // Valider les champs obligatoires pour l'ajout du jeu
    final requiredForGame = {
      'nom_jeux': 'Nom du jeu',
      'duree_jeux': 'Durée',
      'tarif_enf_jeux': 'Tarif enfant',
      'tarif_adu_jeux': 'Tarif adulte',
      'age_mini': 'Âge minimum',
    };

    for (var entry in requiredForGame.entries) {
      final val = data[entry.key];
      if (val == null || (val is String && val.isEmpty)) {
        throw Exception('${entry.value} est requis');
      }
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}jeux');
    final request = http.MultipartRequest('POST', uri);

    // Ajouter les champs sauf l'image et les programmes
    data.forEach((key, value) {
      if (value != null && key != 'logo_jeux' && key != 'programmes') {
        request.fields[key] = value.toString();
      }
    });

    // Joindre le fichier image si fourni
    if (data['logo_jeux'] != null && data['logo_jeux'] is File) { // Ici on vérifie si c'est un File
      final file = data['logo_jeux'] as File;
      request.files.add(http.MultipartFile(
        'logo_jeux',
        file.openRead(),
        file.lengthSync(),
        filename: file.path.split('/').last,
      ));
    }

    // Joindre les programmes JSON si fournis
    if (data['programmes'] != null && data['programmes'] is List) {
      final programmes = (data['programmes'] as List).map((p) {
        return {
          'id_jour': p['id_jour'],
          'heure': (p['heure'] as String).replaceAll('h', ':'),
        };
      }).toList();
      request.fields['programmes'] = jsonEncode(programmes);
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final id = (body['data'] as Map<String, dynamic>)['id_jeux'] as int;
      return id;
    }

    throw Exception(
        'Échec d\'ajout du jeu: ${response.statusCode} - ${response.body}');
  }

  /// Supprimer un jeu par son ID
  Future deleteGame(int id) async {
    try {
      final res = await http.delete(Uri.parse('${ApiConfig.baseUrl}jeux/$id'));
      return res.statusCode == 200;
    } catch (e) {
      print('Erreur deleteGame $id: $e');
      return false;
    }
  }

  /// Mettre à jour les programmations pour un jeu donné (remplacer tout)
  Future updateGameSchedules(
      int gameId, List<Map<String, dynamic>> schedules) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}jeux/$gameId/programmes');
      final body = schedules.map((p) {
        return {
          'id_jour': p['id_jour'],
          'heure': (p['heure'] as String).replaceAll('h', ':'),
        };
      }).toList();

      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'programmes': body}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Erreur updateGameSchedules: $e');
      return false;
    }
  }

  /// Ajouter des programmations pour un jeu
  Future addSchedule(List<Map<String, dynamic>> scheduleEntries) async {
    if (scheduleEntries.isEmpty) {
      return false;
    }
    // On suppose que tous les éléments ont le même game_id
    final gameId = scheduleEntries.first['game_id'];

    // Convertir le format de date ISO 8601 au format attendu par l'API
    final formattedSchedules = scheduleEntries.map((entry) {
      final datetime = DateTime.parse(entry['datetime']);
      // Obtenir le jour de la semaine (1 = Lundi, 7 = Dimanche)
      final dayOfWeek = datetime.weekday;
      // Formater l'heure au format "HH:MM"
      final hour = datetime.hour.toString().padLeft(2, '0');
      final minute = datetime.minute.toString().padLeft(2, '0');

      return {
        'id_jour': dayOfWeek,
        'heure': '$hour:$minute',
      };
    }).toList();

    return updateGameSchedules(int.parse(gameId.toString()), formattedSchedules);
  }
}

