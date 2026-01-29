import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/music.dart';

class MusicService {
  // Get categories
  static Future<List<Category>> getCategories() async {
    final url = ApiConfig.getUrl(ApiConfig.categories);
    
    final response = await http.get(
      Uri.parse(url),
      headers: ApiConfig.headers,
    );

    print('=== GET CATEGORIES RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('================================');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Your API returns: {"status":"success","data":{"categories":[...]}}
      final categoriesData = responseData['data']['categories'] as List;
      return categoriesData.map((item) => Category.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  // Get albums with pagination
  static Future<PaginatedResponse<Album>> getAlbums({
    int page = 1,
    int perPage = 10,
  }) async {
    final url = '${ApiConfig.getUrl(ApiConfig.albums)}?page=$page&per_page=$perPage';
    
    final response = await http.get(
      Uri.parse(url),
      headers: ApiConfig.headers,
    );

    print('=== GET ALBUMS RESPONSE ===');
    print('URL: $url');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('============================');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Your API returns: {"status":"success","data":{"albums":{...}}}
      final albumsData = responseData['data']['albums'];
      return PaginatedResponse<Album>.fromJson(
        albumsData,
        (json) => Album.fromJson(json),
      );
    } else {
      throw Exception('Failed to load albums');
    }
  }

  // Get album by ID
  static Future<Album> getAlbumById(int id) async {
    final url = ApiConfig.getUrlWithParams(ApiConfig.albums, id.toString());
    
    final response = await http.get(
      Uri.parse(url),
      headers: ApiConfig.headers,
    );

    if (response.statusCode == 200) {
      return Album.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load album');
    }
  }

  // Get songs by category with pagination
  static Future<PaginatedResponse<Song>> getSongsByCategory({
    required int categoryId,
    int page = 1,
    int perPage = 10,
  }) async {
    final url = '${ApiConfig.getUrlWithParams('/api/songs/category', categoryId.toString())}?page=$page&per_page=$perPage';
    
    final response = await http.get(
      Uri.parse(url),
      headers: ApiConfig.headers,
    );

    if (response.statusCode == 200) {
      return PaginatedResponse<Song>.fromJson(
        jsonDecode(response.body),
        (json) => Song.fromJson(json),
      );
    } else {
      throw Exception('Failed to load songs by category');
    }
  }

  // Get songs by album with pagination
  static Future<PaginatedResponse<Song>> getSongsByAlbum({
    required int albumId,
    int page = 1,
    int perPage = 10,
  }) async {
    final url = '${ApiConfig.getUrlWithParams('/api/songs/album', albumId.toString())}?page=$page&per_page=$perPage';
    
    final response = await http.get(
      Uri.parse(url),
      headers: ApiConfig.headers,
    );

    print('=== GET SONGS BY ALBUM RESPONSE ===');
    print('URL: $url');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('====================================');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Your API returns: {"status":"success","data":{"album":{...},"songs":{...}}}
      final songsData = responseData['data']['songs'];
      return PaginatedResponse<Song>.fromJson(
        songsData,
        (json) => Song.fromJson(json),
      );
    } else {
      throw Exception('Failed to load songs by album');
    }
  }

  // Get recent songs with pagination
  static Future<PaginatedResponse<Song>> getRecentSongs({
    int page = 1,
    int perPage = 10,
  }) async {
    final url = '${ApiConfig.getUrl(ApiConfig.recentSongs)}?page=$page&per_page=$perPage';
    
    final response = await http.get(
      Uri.parse(url),
      headers: ApiConfig.headers,
    );

    print('=== GET RECENT SONGS RESPONSE ===');
    print('URL: $url');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('==================================');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Your API returns: {"status":"success","data":{"songs":{...}}}
      final songsData = responseData['data']['songs'];
      return PaginatedResponse<Song>.fromJson(
        songsData,
        (json) => Song.fromJson(json),
      );
    } else {
      throw Exception('Failed to load recent songs');
    }
  }
}
