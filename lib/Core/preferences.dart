import 'package:shared_preferences/shared_preferences.dart';

import 'db_constants.dart';

class Preferences {
  final dbConstants = DatabaseConstants();

  Future<bool> setUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt(dbConstants.userId, userId);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(dbConstants.userId);
  }

  Future<bool> removeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(dbConstants.userId);
  }


}