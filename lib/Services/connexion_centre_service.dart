import 'dart:convert';
import 'package:TicknGo/API/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Stockage en mémoire
  Map<String, dynamic>? _currentCentre;
  String? _token;
  int? _centreId;

  // Getters publics
  Map<String, dynamic>? get currentCentre => _currentCentre;
  String? get token => _token;
  int? get centreId => _centreId;

  // Vérifie si l'utilisateur est déjà connecté

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('auth_token');
    final loginTs = prefs.getString('login_timestamp');

    if (storedToken != null && loginTs != null) {
      final loginTime = DateTime.parse(loginTs);
      final hoursElapsed = DateTime.now().difference(loginTime).inHours;

      if (hoursElapsed >= 24) {
        // Session expirée
        await logout();
        return false;
      }

      // Session encore valide
      _token = storedToken;
      _currentCentre = jsonDecode(prefs.getString('user_data')!);
      _centreId = prefs.getInt('user_id');
      return true;
    }

    return false;
  }

  //Appel de connexion
  Future<Map<String, dynamic>> login(String phoneNumber, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl + ApiConfig.loginCentrePath}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'num_centre': phoneNumber,
          'password': password,
        }),
      );
      final responseData = jsonDecode(response.body);
      if (kDebugMode) {
        print("Response Data ===== $responseData");
      }

      if (response.statusCode == 202) {
        // Réussite
        _token = responseData['data']['token'];
        _currentCentre = responseData['data']['centre'];
        _centreId = _currentCentre?['id_centre'];

        if(kDebugMode) print("ID DU CENTRE ::: $_centreId");

        // Persist localement
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', jsonEncode(_currentCentre));
        await prefs.setInt('user_id', _centreId!);

        // ← NOUVEAU : horodatage de connexion
        await prefs.setString(
          'login_timestamp',
          DateTime.now().toIso8601String(),
        );

        return {
          'success': true,
          'message': 'Connexion réussie',
          'user': _currentCentre,
        };
      } else {
        // Échec
        return {
          'success': false,
          'message': responseData['message'] ?? 'Échec de la connexion',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau: $e',
      };
    }
  }

  // Déconnexion : supprime tout du stockage local
  Future<void> logout() async {
    _token = null;
    _currentCentre = null;
    _centreId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await prefs.remove('user_id');
    await prefs.remove('login_timestamp'); // ← on supprime aussi le timestamp
  }

  // Vérifie la validité du token côté serveur
  Future<bool> validateToken() async {
    if (_token == null) return false;
    try {
      final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl + ApiConfig.validatePath }'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Récupère l'ID
  Future<int> getUserId() async {
    // Si déjà en cache, on renvoie directement la valeur non nulle
    if (_centreId != null) return _centreId!;

    // Sinon, on va la chercher dans SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getInt('user_id');

    if (storedId != null) {
      // On met en cache pour les appels suivants
      _centreId = storedId;
      return storedId;
    } else {
      // Gère le cas où il n'y a pas d'ID en mémoire
      throw Exception('Aucun user_id trouvé dans SharedPreferences');
    }
  }
}
