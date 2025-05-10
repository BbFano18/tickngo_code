import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

import '../../../API/api_config.dart';

class MovieService {
  Future<List<Map<String, dynamic>>> _fetchData(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}$endpoint'));
      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode} - ${response.body}');
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final rawData = decoded['data'] as List? ?? [];
      return rawData.map<Map<String, dynamic>>((item) {
        return (item as Map).map((key, value) {
          final k = key.toString();
          final v = value ?? (k.startsWith('id_') ? 0 : '');
          return MapEntry(k, v);
        });
      }).toList();
    } catch (e) {
      print('Erreur _fetchData ($endpoint): ${e.toString()}');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchFormat() => _fetchData('format');
  Future<List<Map<String, dynamic>>> fetchGenre() => _fetchData('genre');
  Future<List<Map<String, dynamic>>> fetchLanguage() => _fetchData('langue');
  Future<List<Map<String, dynamic>>> fetchClassification() => _fetchData('classification');
  Future<List<Map<String, dynamic>>> fetchCategoriefilm() => _fetchData('categoriefilm');
  Future<List<Map<String, dynamic>>> fetchJour() => _fetchData('jour');

  Future<List<Map<String, dynamic>>> fetchMovies(int centreId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}centre/$centreId/films'));
      if (response.statusCode != 201) {
        throw Exception('Erreur ${response.statusCode} - ${response.body}');
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return (decoded['data'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Erreur fetchMovies: ${e.toString()}');
      return [];
    }
  }

  Future<int> addMovie(Map<String, dynamic> data) async {
    try {
      final requiredFields = {
        'nom_film': 'Titre',
        'duree_film': 'Durée',
        'id_centre': 'Centre',
        'id_format': 'Format',
        'id_genre': 'Genre',
        'id_langue': 'Langue',
        'id_classif': 'Classification',
        'id_cat_fil': 'Catégorie'
      };

      for (final entry in requiredFields.entries) {
        final value = data[entry.key];
        if (value == null ||
            (value is List && value.isEmpty) ||
            (value is String && value.isEmpty)) {
          throw Exception('${entry.value} est requis');
        }
      }
      final duration = int.tryParse(data['duree_film'].toString()) ?? 0;
      if (duration <= 0) throw Exception('Durée invalide');

      final uri = Uri.parse('${ApiConfig.baseUrl}films');
      final request = http.MultipartRequest('POST', uri);

      request.fields['nom_film'] = data['nom_film'].toString();
      request.fields['duree_film'] = data['duree_film'].toString();
      request.fields['id_centre'] = data['id_centre'].toString();
      request.fields['id_format'] = data['id_format'].toString();
      request.fields['id_genre'] = data['id_genre'].toString();
      request.fields['id_langue'] = data['id_langue'].toString();
      request.fields['id_classif'] = data['id_classif'].toString();
      request.fields['id_cat_fil'] = data['id_cat_fil'].toString();

      // Gestion de l'image
      if (data.containsKey('image_url') && data['image_url'] != null && data['image_url'].toString().isNotEmpty) {
        // Vérifier si c'est un chemin de fichier local ou une URL distante
        if (data['image_url'].toString().startsWith('http')) {
          // C'est une URL
          request.fields['image'] = data['image_url'].toString();
        } else {
          // C'est un fichier local
          final file = File(data['image_url']);
          if (await file.exists()) {
            request.files.add(await http.MultipartFile.fromPath('image', data['image_url']));
          }
        }
      }

      if (data.containsKey('programmes') && (data['programmes'] as List).isNotEmpty) {
        final programmes = (data['programmes'] as List);
        request.fields['programmes'] = jsonEncode(
          programmes.map((p) => {
            'id_jour': p['id_jour'],
            'heure': (p['heure'] as String).replaceAll('h', ':'),
          }).toList(),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final filmId = body['data']['id_film'] as int;
        return filmId;
      } else {
        throw Exception(
            'Erreur API lors de l\'ajout du film: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de l\'ajout du film: $e');
      rethrow;
    }
  }

  Future<bool> deleteMovie(int id) async {
    try {
      final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}film/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur deleteMovie: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchMovieDetails(dynamic id_film) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}film/$id_film'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des détails du film: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> fetchMovieProgrammes(dynamic id_film) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}film/$id_film/programmes'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return (decoded['data'] as List?)?.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des programmes: $e');
      return null;
    }
  }

  Future<bool> updateMovieProgrammes(
      dynamic id_film, List<Map<String, dynamic>> programmes) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}films/$id_film/programmes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'programmes': programmes}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la mise à jour des programmes: $e');
      return false;
    }
  }

  Future<bool> updateMovie(int id_film, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}film/$id_film');
      final request = http.MultipartRequest('POST', uri);

      // Ajouter la méthode PUT pour le serveur (comme on utilise MultipartRequest)
      request.fields['_method'] = 'PUT';

      // Ajouter les champs du film
      if (data.containsKey('nom_film')) request.fields['nom_film'] = data['nom_film'].toString();
      if (data.containsKey('duree_film')) request.fields['duree_film'] = data['duree_film'].toString();
      if (data.containsKey('id_format')) request.fields['id_format'] = data['id_format'].toString();
      if (data.containsKey('id_genre')) request.fields['id_genre'] = data['id_genre'].toString();
      if (data.containsKey('id_langue')) request.fields['id_langue'] = data['id_langue'].toString();
      if (data.containsKey('id_classif')) request.fields['id_classif'] = data['id_classif'].toString();
      if (data.containsKey('id_cat_fil')) request.fields['id_cat_fil'] = data['id_cat_fil'].toString();

      // Gestion de l'image
      if (data.containsKey('image_url') && data['image_url'] != null && data['image_url'].toString().isNotEmpty) {
        // Vérifier si c'est un nouveau fichier local ou une URL existante
        if (data['image_url'].toString().startsWith('http')) {
          // C'est une URL existante, pas besoin de la changer
        } else {
          // C'est un nouveau fichier local, on l'envoie
          final file = File(data['image_url']);
          if (await file.exists()) {
            request.files.add(await http.MultipartFile.fromPath('image', data['image_url']));
          }
        }
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la mise à jour du film: $e');
      return false;
    }
  }
}