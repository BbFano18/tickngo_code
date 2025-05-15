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
      return (decoded['data'] as List).cast<Map<String, dynamic>>();
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

  Future<String?> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}upload');
      final request = http.MultipartRequest('POST', uri);
      
      final stream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();
      
      final multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: imageFile.path.split('/').last,
      );
      
      request.files.add(multipartFile);
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['url'];
      }
      return null;
    } catch (e) {
      print('Erreur lors du téléchargement de l\'image: $e');
      return null;
    }
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

      print('Champs du formulaire ajoutés à la requête');

      // Gestion améliorée de l'image
      if (data['image_url'] != null && data['image_url'] is File) {
        print('Début du téléchargement de l\'image');
        final imageUrl = await uploadImage(data['image_url']);
        if (imageUrl != null) {
          request.fields['image_url'] = imageUrl;
          print('Image téléchargée avec succès : $imageUrl');
        } else {
          print('Échec du téléchargement de l\'image');
        }
      }

      print('Envoi de la requête à l\'API...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('Réponse reçue - Status: ${response.statusCode}');
      print('Corps de la réponse: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final movieId = responseData['data']['id_film'] ?? -1;
        print('Film ajouté avec succès. ID: $movieId');
        return movieId;
      } else {
        print('Erreur lors de l\'ajout du film. Status: ${response.statusCode}');
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Exception dans addMovie: $e');
      throw e;
    }
  }

  Future<bool> deleteMovie(int movieId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}films/$movieId'),
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        if (decodedResponse['success'] == true || decodedResponse['status'] == 'success') {
          return true;
        } else {
          throw Exception(decodedResponse['message'] ?? 'Échec de la suppression');
        }
      }
      throw Exception('Erreur lors de la suppression du film');
    } catch (e) {
      print('Erreur deleteMovie: $e');
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
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}film/$id_film/programme'));
      if (response.statusCode == 201) {
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
        Uri.parse('${ApiConfig.baseUrl}films/$id_film/programme'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'programmes': programmes}),
      );
      return response.statusCode == 200;
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

      // Gestion améliorée de l'image pour la mise à jour
      if (data['image_url'] != null && data['image_url'] is File) {
        final imageUrl = await uploadImage(data['image_url']);
        if (imageUrl != null) {
          request.fields['image_url'] = imageUrl;
          hasChanges = true;
        }
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
}