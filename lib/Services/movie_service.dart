import 'dart:convert';

import '../API/api_config.dart';
import '../Screens/Cinema/models/category.dart';
import '../Screens/Cinema/models/classification.dart';
import '../Screens/Cinema/models/format.dart';
import '../Screens/Cinema/models/genre.dart';
import '../Screens/Cinema/models/langue.dart';
import '../Screens/Cinema/models/movie.dart';
import 'package:http/http.dart' as http;

class MovieService {

  Future<List<Movie>> fetchMovies(int centreId) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}centre/$centreId/films'));
    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> list = data['data'];
      return list.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Erreur ${response.statusCode}');
    }
  }

  Future<Category?> fetchCategory(int? id) async {
    if (id == null) return null;
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}categoriefilm/$id'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Category.fromJson(data['data']);
    } else {
      print('Erreur lors de la récupération de la catégorie $id: ${response.statusCode}');
      return null;
    }
  }

  Future<Genre?> fetchGenre(int? id) async {
    if (id == null) return null;
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}genre/$id'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Genre.fromJson(data['data']);
    } else {
      print('Erreur lors de la récupération du genre $id: ${response.statusCode}');
      return null;
    }
  }

  Future<Format?> fetchFormat(int? id) async {
    if (id == null) return null;
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}format/$id'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Format.fromJson(data['data']);
    } else {
      print('Erreur lors de la récupération du format $id: ${response.statusCode}');
      return null;
    }
  }

  Future<Language?> fetchLanguage(int? id) async {
    if (id == null) return null;
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}langue/$id'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Language.fromJson(data['data']);
    } else {
      print('Erreur lors de la récupération de la langue $id: ${response.statusCode}');
      return null;
    }
  }

  Future<Classification?> fetchClassification(int? id) async {
    if (id == null) return null;
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}classification/$id'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Classification.fromJson(data['data']);
    } else {
      print('Erreur lors de la récupération de la classification $id: ${response.statusCode}');
      return null;
    }
  }
}