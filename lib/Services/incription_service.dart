import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/api_config.dart';

class ApiService2 {
  final Dio _dio;

  ApiService2() : _dio = Dio() {
    // Ajout d'un intercepteur pour les requêtes
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Récupération du token depuis le stockage local
          final token = await _getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Gestion des erreurs 401 (Non autorisé)
          if (error.response?.statusCode == 401) {
            // Ici vous pourriez rafraîchir le token si nécessaire
            debugPrint('Token expiré ou invalide');
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> register({
    required String name,
    required String numero,
    required String password,
    required String password_confirmation,
  }) async {
    try {
      final trimmedPassword = password.trim();
      final trimmedConfirmPassword = password_confirmation.trim();

      if (trimmedPassword.isEmpty || trimmedConfirmPassword.isEmpty) {
        throw Exception("Les champs mot de passe ne peuvent pas être vides.");
      }

      if (trimmedPassword != trimmedConfirmPassword) {
        throw Exception("Les mots de passe ne correspondent pas.");
      }

      final url = '${ApiConfig.baseUrl + ApiConfig.registerPath}';
      final formData = FormData.fromMap({
        'name': name,
        'numero': numero,
        'password': password,
        'password_confirmation': password_confirmation,
      });

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'Accept': 'application/json'},
          validateStatus: (status) => status! < 500,
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 201) {
        debugPrint('Inscription réussie : ${response.data}');

        // Extraction et sauvegarde du token
        final token = response.data['token'] ?? response.data['access_token'];
        if (token != null) {
          await _saveToken(token);
        }

        // Sauvegarde des informations de l'utilisateur
        await _saveUserInfo(name, numero);
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

  // Sauvegarder les informations utilisateur
  Future<void> _saveUserInfo(String name, String numero) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_numero', numero);
    debugPrint('Informations utilisateur sauvegardées avec succès');
  }

  // Récupérer les informations utilisateur
  Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? "";
    final numero = prefs.getString('user_numero') ?? "";
    return {
      'name': name,
      'numero': numero,
    };
  }

  //sauvegarder le token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    debugPrint('Token sauvegardé avec succès');
  }

  // récupérer le token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  //  (déconnexion)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_numero');
    debugPrint('Token et informations utilisateur supprimés');
  }
}