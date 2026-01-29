import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Login or create user
  static Future<LoginResponse> login({
    required String email,
    required String username,
    required String image,
  }) async {
    final url = ApiConfig.getUrl(ApiConfig.login);
    
    final response = await http.post(
      Uri.parse(url),
      headers: ApiConfig.headers,
      body: jsonEncode({
        'email': email,
        'username': username,
        'image': image,
      }),
    );

    print('=== LOGIN RESPONSE ===');
    print('URL: $url');
    print('Request Body: {"email": "$email", "username": "$username", "image": "$image"}');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('=====================');

    if (response.statusCode == 200) {
      final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
      
      // Save token and user data
      await _saveToken(loginResponse.token);
      await _saveUser(loginResponse.user);
      
      return loginResponse;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Login failed');
    }
  }

  // Logout user
  static Future<ApiResponse> logout() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final url = ApiConfig.getUrl(ApiConfig.logout);
    
    final response = await http.post(
      Uri.parse(url),
      headers: ApiConfig.getAuthHeaders(token),
    );

    print('=== LOGOUT RESPONSE ===');
    print('URL: $url');
    print('Token: $token');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('======================');

    // Clear local storage regardless of API response
    await _clearAuthData();

    if (response.statusCode == 200) {
      return ApiResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Logout failed');
    }
  }

  // Get current user profile
  static Future<ProfileResponse> getProfile() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final url = ApiConfig.getUrl(ApiConfig.profile);
    
    final response = await http.get(
      Uri.parse(url),
      headers: ApiConfig.getAuthHeaders(token),
    );

    print('=== GET PROFILE RESPONSE ===');
    print('URL: $url');
    print('Token: $token');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('=============================');

    if (response.statusCode == 200) {
      return ProfileResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      // Token is invalid, clear auth data
      await _clearAuthData();
      throw Exception('Unauthenticated');
    } else {
      throw Exception('Failed to get profile');
    }
  }

  // Update user profile
  static Future<ProfileResponse> updateProfile({
    String? username,
    String? image,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final url = ApiConfig.getUrl(ApiConfig.profile);
    
    final Map<String, dynamic> requestBody = {};
    if (username != null) requestBody['username'] = username;
    if (image != null) requestBody['image'] = image;
    
    final response = await http.put(
      Uri.parse(url),
      headers: ApiConfig.getAuthHeaders(token),
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final profileResponse = ProfileResponse.fromJson(jsonDecode(response.body));
      // Update saved user data
      await _saveUser(profileResponse.user);
      return profileResponse;
    } else if (response.statusCode == 401) {
      await _clearAuthData();
      throw Exception('Unauthenticated');
    } else {
      throw Exception('Failed to update profile');
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get stored user data
  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  // Save token to local storage
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Save user data to local storage
  static Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // Clear all auth data
  static Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
