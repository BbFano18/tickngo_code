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
  Future<List<Map<String, dynamic>>> fetchCategoriefilm() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}categoriefilm'));
      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode} - ${response.body}');
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final rawData = decoded['data'] as List? ?? [];
      return rawData.map<Map<String, dynamic>>((item) {
        return {
          'id_cat_fil': item['id_cat_fil'] ?? 0,
          'lib_cat_fil': item['lib_cat_fil'] ?? '',
          'prix': item['prix'] ?? 0,
        };
      }).toList();
    } catch (e) {
      print('Erreur fetchCategoriefilm: ${e.toString()}');
      return [];
    }
  }
  Future<List<Map<String, dynamic>>> fetchJour() => _fetchData('jour');

  Future<List<Map<String, dynamic>>> fetchMovies(int centreId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}centre/$centreId/films'));
      if (response.statusCode != 201) {
        throw Exception('Erreur ${response.statusCode} - ${response.body}');
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final List<Map<String, dynamic>> movies = (decoded['data'] as List).cast<Map<String, dynamic>>();
      
      // Récupérer toutes les classifications en une seule fois
      final classificationsResponse = await http.get(Uri.parse('${ApiConfig.baseUrl}classification'));
      Map<int, String> classificationsMap = {};
      if (classificationsResponse.statusCode == 200) {
        final classificationsData = jsonDecode(classificationsResponse.body);
        if (classificationsData['data'] != null) {
          final List<dynamic> classifications = classificationsData['data'];
          for (var classification in classifications) {
            classificationsMap[classification['id_classif']] = classification['lib_classif'];
          }
        }
      }
      
      // Pour chaque film, récupérer les informations complémentaires
      for (var movie in movies) {
        try {
          // Récupérer le format
          if (movie['id_format'] != null) {
            final formatResponse = await http.get(
              Uri.parse('${ApiConfig.baseUrl}format/${movie['id_format']}')
            );
            if (formatResponse.statusCode == 200) {
              final formatData = jsonDecode(formatResponse.body);
              if (formatData['data'] != null) {
                movie['lib_format'] = formatData['data']['lib_format'];
              }
            }
          }

          // Récupérer le genre
          if (movie['id_genre'] != null) {
            final genreResponse = await http.get(
              Uri.parse('${ApiConfig.baseUrl}genre/${movie['id_genre']}')
            );
            if (genreResponse.statusCode == 200) {
              final genreData = jsonDecode(genreResponse.body);
              if (genreData['data'] != null) {
                movie['lib_genre'] = genreData['data']['lib_genre'];
              }
            }
          }

          // Récupérer la langue
          if (movie['id_langue'] != null) {
            final langueResponse = await http.get(
              Uri.parse('${ApiConfig.baseUrl}langue/${movie['id_langue']}')
            );
            if (langueResponse.statusCode == 200) {
              final langueData = jsonDecode(langueResponse.body);
              if (langueData['data'] != null) {
                movie['lib_langue'] = langueData['data']['lib_langue'];
              }
            }
          }

          // Récupérer la classification depuis la map
          if (movie['id_classif'] != null) {
            movie['lib_classif'] = classificationsMap[movie['id_classif']] ?? '';
            print('Classification pour ${movie['nom_film']}: ${movie['lib_classif']}');
          }

          // Récupérer la catégorie
          if (movie['id_cat_fil'] != null) {
            final catResponse = await http.get(
              Uri.parse('${ApiConfig.baseUrl}categoriefilm/${movie['id_cat_fil']}')
            );
            if (catResponse.statusCode == 200) {
              final catData = jsonDecode(catResponse.body);
              if (catData['data'] != null) {
                movie['lib_cat_fil'] = catData['data']['lib_cat_fil'];
              }
            }
          }

          // Formater les tarifs
          movie['tarif_enf_film'] = int.tryParse(movie['tarif_enf_film']?.toString() ?? '0') ?? 0;
          movie['tarif_adu_film'] = int.tryParse(movie['tarif_adu_film']?.toString() ?? '0') ?? 0;
          movie['tarif_premiere'] = int.tryParse(movie['tarif_premiere']?.toString() ?? '0') ?? 0;
          movie['prix'] = int.tryParse(movie['prix']?.toString() ?? '0') ?? 0;

          print('Film traité: ${movie['nom_film']}');
          print('Format: ${movie['lib_format']}');
          print('Genre: ${movie['lib_genre']}');
          print('Langue: ${movie['lib_langue']}');
          print('Classification: ${movie['lib_classif']}');
          print('Catégorie: ${movie['lib_cat_fil']}');
          print('Tarifs: ${movie['tarif_enf_film']}, ${movie['tarif_adu_film']}, ${movie['tarif_premiere']}, ${movie['prix']}');

        } catch (e) {
          print('Erreur lors du traitement du film ${movie['nom_film']}: $e');
        }
      }

      return movies;
    } catch (e) {
      print('Erreur fetchMovies: ${e.toString()}');
      return [];
    }
  }

  Future<bool> validateMovieData(Map<String, dynamic> data) {
    print('Début de la validation des données du film');
    final requiredFields = [
      'nom_film',
      'duree_film',
      'id_centre',
      'id_format',
      'id_genre',
      'id_langue',
      'id_classif',
      'id_cat_fil',
      'tarif_adu_film',
      'tarif_premiere',
      'prix'
    ];

    for (var field in requiredFields) {
      print('Vérification du champ $field : ${data[field]}');
      if (data[field] == null || data[field].toString().trim().isEmpty) {
        print('Erreur : Le champ $field est manquant ou vide');
        throw Exception('Le champ $field est requis');
      }
    }

    // Validation des tarifs
    print('Validation des tarifs...');
    if (data['tarif_adu_film'] != null && double.tryParse(data['tarif_adu_film'].toString()) == null) {
      print('Erreur : Le tarif adulte n\'est pas un nombre valide');
      throw Exception('Le tarif adulte doit être un nombre valide');
    }
    if (data['tarif_enf_film'] != null && double.tryParse(data['tarif_enf_film'].toString()) == null) {
      print('Erreur : Le tarif enfant n\'est pas un nombre valide');
      throw Exception('Le tarif enfant doit être un nombre valide');
    }
    if (data['tarif_premiere'] != null && double.tryParse(data['tarif_premiere'].toString()) == null) {
      print('Erreur : Le tarif première n\'est pas un nombre valide');
      throw Exception('Le tarif première doit être un nombre valide');
    }
    if (data['prix'] != null && double.tryParse(data['prix'].toString()) == null) {
      print('Erreur : Le prix de la catégorie n\'est pas un nombre valide');
      throw Exception('Le prix de la catégorie doit être un nombre valide');
    }

    print('Validation des données réussie');
    return Future.value(true);
  }

  Future<int> addMovie(Map<String, dynamic> data) async {
    try {
      print('Début de l\'ajout du film avec les données : ${data.toString()}');
      
      // Validation des données
      await validateMovieData(data);
      print('Validation des données réussie');

      final uri = Uri.parse('${ApiConfig.baseUrl}films');
      final request = http.MultipartRequest('POST', uri);

      // Ajout des champs texte
      request.fields['nom_film'] = data['nom_film'].toString();
      request.fields['duree_film'] = data['duree_film'].toString();
      request.fields['id_centre'] = data['id_centre'].toString();
      request.fields['id_format'] = data['id_format'].toString();
      request.fields['id_genre'] = data['id_genre'].toString();
      request.fields['id_langue'] = data['id_langue'].toString();
      request.fields['id_classif'] = data['id_classif'].toString();
      request.fields['id_cat_fil'] = data['id_cat_fil'].toString();
      request.fields['tarif_enf_film'] = (data['tarif_enf_film'] ?? 0).toString();
      request.fields['tarif_adu_film'] = (data['tarif_adu_film'] ?? 0).toString();
      request.fields['tarif_premiere'] = (data['tarif_premiere'] ?? 0).toString();
      request.fields['prix'] = (data['prix'] ?? 0).toString();

      // Ajout de l'image
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

      print('Envoi de la requête à l\'API...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('Réponse reçue - Status: ${response.statusCode}');
      print('Corps de la réponse: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['data'] != null && responseData['data']['film'] != null) {
          final movieId = responseData['data']['film']['id_film'];
          print('Film ajouté avec succès. ID: $movieId');
          return movieId;
        }
      }
      
      print('Erreur lors de l\'ajout du film. Status: ${response.statusCode}');
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('Exception dans addMovie: $e');
      throw e;
    }
  }

  Future<bool> deleteMovie(int movieId) async {
    try {
      print('Tentative de suppression du film avec l\'ID: $movieId');
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}films/$movieId'),
      );

      print('Réponse reçue - Status: ${response.statusCode}');
      print('Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        if (decodedResponse['success'] == true || 
            decodedResponse['status'] == 'success' ||
            decodedResponse['message']?.toString().toLowerCase().contains('succ') == true) {
          print('Film supprimé avec succès');
          return true;
        }
        throw Exception(decodedResponse['message'] ?? 'La suppression a échoué');
      }

      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('Exception dans deleteMovie: $e');
      throw Exception('Impossible de supprimer le film: $e');
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
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}programme/$id_film/films'));
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
        Uri.parse('${ApiConfig.baseUrl}programme/$id_film'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'programmes': programmes}),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Erreur lors de la mise à jour des programmes: $e');
      return false;
    }
  }

  Future<bool> updateMovie(int movieId, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}films/$movieId');
      final request = http.MultipartRequest('POST', uri);
      request.fields['_method'] = 'PUT';

      // Vérification des modifications
      final currentMovie = await fetchMovieDetails(movieId);
      if (currentMovie == null) {
        throw Exception('Film non trouvé');
      }

      bool hasChanges = false;

      // Fonction utilitaire pour comparer et ajouter les champs modifiés
      void addFieldIfChanged(String key, dynamic newValue) {
        if (newValue != null && newValue.toString().isNotEmpty && 
            newValue.toString() != currentMovie[key].toString()) {
          request.fields[key] = newValue.toString();
          hasChanges = true;
        }
      }

      // Vérification des champs modifiés
      addFieldIfChanged('nom_film', data['nom_film']);
      addFieldIfChanged('duree_film', data['duree_film']);
      addFieldIfChanged('id_format', data['id_format']);
      addFieldIfChanged('id_genre', data['id_genre']);
      addFieldIfChanged('id_langue', data['id_langue']);
      addFieldIfChanged('id_classif', data['id_classif']);
      addFieldIfChanged('id_cat_fil', data['id_cat_fil']);
      addFieldIfChanged('tarif_enf_film', data['tarif_enf_film']);
      addFieldIfChanged('tarif_adu_film', data['tarif_adu_film']);
      addFieldIfChanged('tarif_premiere', data['tarif_premiere']);

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
        hasChanges = true;
      }

      if (!hasChanges) {
        return true; // Aucune modification nécessaire
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        return decodedResponse['success'] == true || decodedResponse['status'] == 'success';
      }

      throw Exception('Erreur lors de la mise à jour: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Erreur updateMovie: $e');
      throw e;
    }
  }

  /// Ajouter une programmation pour un film
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

  /// Récupérer les programmes d'un film spécifique
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

  /// Supprimer un programme
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

  /// Mettre à jour les programmes d'un film
  Future<bool> updateFilmSchedules(int filmId, List<Map<String, dynamic>> schedules) async {
    try {
      if (filmId <= 0) {
        throw Exception('ID du film invalide');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}programme/$filmId');
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'programme': schedules}),
      );

      if (response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return decoded['success'] == true || decoded['status'] == 'success';
      }

      print('Erreur API ${response.statusCode}: ${response.body}');
      return false;
    } catch (e) {
      print('Erreur updateFilmSchedules: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchClassificationById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}classifications/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la classification: $e');
      return null;
    }
  }
}