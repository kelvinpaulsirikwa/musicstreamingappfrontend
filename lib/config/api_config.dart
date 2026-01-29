class ApiConfig {
  // Base URL for your API
  static const String baseUrl = 'http://10.0.2.2:8001';
  
  // Base URL for images (assuming they're stored in storage/public/images)
  static const String imageUrl = '$baseUrl/uploads/artists/';
  
  // Authentication Endpoints
  static const String login = '/api/login';
  static const String logout = '/api/logout';
  static const String profile = '/api/profile';
  
  // Music Content Endpoints
  static const String categories = '/api/categories';
  static const String albums = '/api/albums';
  static const String recentSongs = '/api/songs/recent';
  
  // Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Get full URL for endpoint
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  // Get URL with parameters
  static String getUrlWithParams(String endpoint, String param) {
    return '$baseUrl$endpoint/$param';
  }
  
  // Get full image URL
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    // If it's already a full URL, return as is
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    
    // Otherwise, prepend the image base URL
    return '$imageUrl$imagePath';
  }
  
  // Get headers with authorization token
  static Map<String, String> getAuthHeaders(String token) {
    return {
      ...headers,
      'Authorization': 'Bearer $token',
    };
  }
}
