class ApiConfig {
  static const String baseUrl = 'https://fcd711218bc3.ngrok-free.app';
  
  // Base URL for images (assuming they're stored in storage/public/images)
  static const String imageUrl = '$baseUrl/uploads/artists/';
  
  // Base URL for audio files
  static const String audioUrl = '$baseUrl/storage/songs/';
  
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
  
  // Get full audio URL
  static String getAudioUrl(String? audioPath) {
    if (audioPath == null || audioPath.isEmpty) {
      return '';
    }
    
    // If it's already a full URL, just ensure it's HTTPS
    if (audioPath.startsWith('http')) {
      return audioPath.replaceFirst('http://', 'https://');
    }
    
    // Otherwise, prepend the audio base URL
    return '$audioUrl$audioPath';
  }
  
  // Get headers with authorization token
  static Map<String, String> getAuthHeaders(String token) {
    return {
      ...headers,
      'Authorization': 'Bearer $token',
    };
  }
}
