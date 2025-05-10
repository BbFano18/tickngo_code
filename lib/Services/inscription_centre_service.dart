import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../API/api_config.dart';

class ApiService {
  final Dio _dio = Dio();

  Future<void> registerCenter({
    required String name,
    required String city,
    required String phone,
    required String description,
    required String password,
    required File logo,
    required String confirm_password,
    required List<File> documents,
  }) async {
    try {
        // Trim des mots de passe avant comparaison
        final trimmedPassword = password.trim();
        final trimmedConfirmPassword = confirm_password.trim();

        if (trimmedPassword.isEmpty || trimmedConfirmPassword.isEmpty) {
          throw Exception("Les champs mot de passe ne peuvent pas être vides.");
        }

        if (trimmedPassword != trimmedConfirmPassword) {
          throw Exception("Les mots de passe ne correspondent pas.");
        }

      const url = '${ApiConfig.baseUrl + ApiConfig.registerCentrePath}';

      _dio.options = BaseOptions(
        validateStatus: (status) => status! < 500,
        contentType: 'multipart/form-data',
        headers: {'Accept': 'application/json'},
      );

      final formData = FormData.fromMap({
        'nom_centre': name,
        'ville': city,
        'num_centre': phone,
        'description': description,
        'password': password,
        'confirm_password': confirm_password,
        'logo': await MultipartFile.fromFile(
          logo.path,
          filename: 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        'documents': documents.map((file) => file.path.split('/').last).join(', '),
        'files': await Future.wait(
          documents.map((file) async => MultipartFile.fromFile(
            file.path,
            filename: 'doc_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}',
          )),
        ),
      });

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 201) {
        debugPrint('Inscription réussie : ${response.data}');
      } else {
        throw Exception('Erreur ${response.statusCode} : ${response.data}');
      }
    } on DioException catch (e) {
      debugPrint('Erreur Dio: ${e.message}');
      if (e.response != null) {
        throw Exception('Erreur serveur: ${e.response!.data}');
      }
      throw Exception('Erreur de connexion: ${e.message}');
    } catch (e) {
      debugPrint('Erreur inattendue: $e');
      throw Exception('Erreur technique: $e');
    }
  }
}