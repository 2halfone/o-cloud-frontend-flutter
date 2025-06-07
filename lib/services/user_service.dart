import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/token_manager.dart';

class UserService {
  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  Future<List<User>> fetchUsers() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$USER_BASE_URL/users'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch users: ${response.body}');
    }
  }

  Future<User> fetchUser(String id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$USER_BASE_URL/users/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch user: ${response.body}');
    }
  }

  Future<void> createUser(User user) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$USER_BASE_URL/users'),
      headers: headers,
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create user: ${response.body}');
    }
  }

  Future<void> updateUser(User user) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$USER_BASE_URL/users/${user.id}'),
      headers: headers,
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  Future<void> deleteUser(String id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$USER_BASE_URL/users/$id'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user: ${response.body}');
    }
  }
}
