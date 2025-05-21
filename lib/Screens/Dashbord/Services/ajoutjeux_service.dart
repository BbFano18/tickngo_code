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
      await http.get(Uri.parse('${ApiConfig.baseUrl}programme/$gameId/jeux'));
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
    try {
      final requiredFields = {
        'nom_jeux': 'Nom du jeu',
        'duree_jeux': 'Durée',
        'id_centre': 'Centre',
        'lieu_jeux': 'Lieu',
        'tarif_enf_jeux': 'Tarif enfant',
        'tarif_adu_jeux': 'Tarif adulte',
      };

      for (final entry in requiredFields.entries) {
        final value = data[entry.key];
        if (value == null ||
            (value is List && value.isEmpty) ||
            (value is String && value.isEmpty)) {
          throw Exception('${entry.value} est requis');
        }
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}jeux');
      final request = http.MultipartRequest('POST', uri);

      // Ajouter les champs sauf l'image
      data.forEach((key, value) {
        if (value != null && key != 'logo_jeux') {
          request.fields[key] = value.toString();
        }
      });

      // Joindre le fichier image si fourni
      if (data['logo_jeux'] != null && data['logo_jeux'] is File) {
        final file = data['logo_jeux'] as File;
        final filename = file.path.split('/').last;
        request.files.add(await http.MultipartFile.fromPath(
          'logo_jeux', // Nom du champ attendu par l'API
          file.path,
          filename: filename,
        ));
      }

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 201) {
        final body = jsonDecode(responseData.body) as Map<String, dynamic>;
        final id = (body['data'] as Map<String, dynamic>)['id_jeux'] as int;
        return id;
      }

      throw Exception(
          'Échec d\'ajout du jeu: ${response.statusCode} - ${responseData.body}');
    } catch (e) {
      print('Erreur lors de l\'ajout du jeu: $e');
      rethrow;
    }
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
  Future<bool> updateGameSchedules(int gameId, List<Map<String, dynamic>> schedules) async {
    try {
      if (gameId <= 0) {
        throw Exception('ID du jeu invalide');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}programme/$gameId');
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'programme': schedules}),
      );

      if (response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true || decoded['status'] == 'success') {
          return true;
        }
      }

      print('Erreur API ${response.statusCode}: ${response.body}');
      return false;
    } catch (e) {
      print('Erreur updateGameSchedules: $e');
      return false;
    }
  }

  /// Ajouter des programmations pour un jeu
  Future<bool> addSchedule(Map<String, dynamic> programData) async {
    try {
      if (programData['id_jeux'] == null) {
        throw Exception('ID du jeu requis');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}programme/jeux');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_jour': programData['id_jour'],
          'id_jeux': programData['id_jeux'],
          'heure': programData['heure'],
          'id_event': programData['id_event'] ?? null,
          'id_film': programData['id_film'] ?? null,
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

  /// Récupérer les programmes d'un jeu spécifique
  Future<List<Map<String, dynamic>>> getProgrammesByJeu(int idJeux) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}programme/$idJeux/jeux')
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return (decoded['data'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Erreur getProgrammesByJeu: $e');
      return [];
    }
  }

  // Supprimer un programme
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

  /// Mettre à jour un jeu existant
  Future<bool> updateGame(int gameId, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}jeux/$gameId');
      final request = http.MultipartRequest('POST', uri);
      request.fields['_method'] = 'PUT';

      // Ajout des champs texte seulement s'ils sont présents dans data
      if (data['nom_jeux'] != null) request.fields['nom_jeux'] = data['nom_jeux'].toString();
      if (data['lieu_jeux'] != null) request.fields['lieu_jeux'] = data['lieu_jeux'].toString();
      if (data['duree_jeux'] != null) request.fields['duree_jeux'] = data['duree_jeux'].toString();
      if (data['tarif_enf_jeux'] != null) request.fields['tarif_enf_jeux'] = data['tarif_enf_jeux'].toString();
      if (data['tarif_adu_jeux'] != null) request.fields['tarif_adu_jeux'] = data['tarif_adu_jeux'].toString();
      if (data['age_mini'] != null) request.fields['age_mini'] = data['age_mini'].toString();

      // Gestion de l'image
      if (data['logo_jeux'] != null && data['logo_jeux'] is File) {
        final file = data['logo_jeux'] as File;
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

      print('Erreur lors de la mise à jour du jeu: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('Erreur updateGame: $e');
      throw Exception('Impossible de mettre à jour le jeu: $e');
    }
  }

  /// Récupérer les détails d'un jeu
  Future<Map<String, dynamic>?> fetchGameDetails(int gameId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}jeux/$gameId'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des détails du jeu: $e');
      return null;
    }
  }
}

