class User {
  final int id;
  final String email;
  final String username;
  final String image;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.image,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'image': image,
    };
  }
}

class LoginResponse {
  final String status;
  final String message;
  final User user;
  final String token;
  final String tokenType;

  LoginResponse({
    required this.status,
    required this.message,
    required this.user,
    required this.token,
    required this.tokenType,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status'],
      message: json['message'],
      user: User.fromJson(json['data']['user']),
      token: json['data']['token'],
      tokenType: json['data']['token_type'],
    );
  }
}

class ProfileResponse {
  final String status;
  final User user;

  ProfileResponse({
    required this.status,
    required this.user,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      status: json['status'],
      user: User.fromJson(json['data']['user']),
    );
  }
}

class ApiResponse {
  final String status;
  final String message;

  ApiResponse({
    required this.status,
    required this.message,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      status: json['status'],
      message: json['message'],
    );
  }
}
