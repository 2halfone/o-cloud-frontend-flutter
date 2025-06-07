import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../utils/constants.dart';

class UserService {
  // ✅ Usa ApiConstants invece di USER_BASE_URL non definito
  static const String _baseUrl = ApiConstants.USER_BASE_URL;

  Future<List<User>> getUsers() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users'), // ✅ Linea 19 - Ora usa _baseUrl
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<User> getUserById(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/$id'), // ✅ Linea 34 - Ora usa _baseUrl
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load user');
    }
  }

  // ✅ Aggiungi alias per compatibilità con UserDetailScreen
  Future<User> fetchUser(String id) async {
    return getUserById(id);
  }

  Future<User> createUser(User user) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users'), // ✅ Linea 48 - Ora usa _baseUrl
      headers: {'Content-Type': 'application/json'},
      body: json.encode(user.toJson()),
    );

    if (response.statusCode == 201) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create user');
    }
  }

  Future<User> updateUser(String id, User user) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/users/$id'), // ✅ Linea 61 - Ora usa _baseUrl
      headers: {'Content-Type': 'application/json'},
      body: json.encode(user.toJson()),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update user');
    }
  }

  Future<void> deleteUser(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/users/$id'), // ✅ Linea 74 - Ora usa _baseUrl
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }
}
