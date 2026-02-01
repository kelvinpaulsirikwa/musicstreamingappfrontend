import '../config/api_config.dart';

class Album {
  final int id;
  final String title;
  final String? coverImage;
  final String coverImageUrl;
  final String releaseDate;
  final Artist artist;

  Album({
    required this.id,
    required this.title,
    this.coverImage,
    required this.coverImageUrl,
    required this.releaseDate,
    required this.artist,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    print('=== PARSING ALBUM ===');
    print('Album JSON: $json');
    
    final album = Album(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      coverImage: json['cover_image'],
      coverImageUrl: json['cover_image_url'] ?? '',
      releaseDate: json['release_date'] ?? '',
      artist: Artist.fromJson(json['artist'] ?? {}),
    );
    
    print('Parsed Album: ${album.title}');
    print('Cover Image URL: ${album.coverImageUrl}');
    print('Full Image URL: ${album.fullImageUrl}');
    print('====================');
    
    return album;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cover_image': coverImage,
      'cover_image_url': coverImageUrl,
      'release_date': releaseDate,
      'artist': artist.toJson(),
    };
  }

  String get fullImageUrl => coverImageUrl.isNotEmpty ? coverImageUrl : ApiConfig.getImageUrl(coverImage);
}

class Artist {
  final int id;
  final int userId;
  final String stageName;
  final String bio;
  final String? image;
  final String imageUrl;

  Artist({
    required this.id,
    required this.userId,
    required this.stageName,
    required this.bio,
    this.image,
    required this.imageUrl,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    // Handle null or empty json
    if (json == null || json.isEmpty) {
      return Artist(
        id: 0,
        userId: 0,
        stageName: 'Unknown Artist',
        bio: '',
        image: null,
        imageUrl: '',
      );
    }

    return Artist(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      stageName: json['stage_name'] ?? 'Unknown Artist',
      bio: json['bio'] ?? '',
      image: json['image'],
      imageUrl: json['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'stage_name': stageName,
      'bio': bio,
      'image': image,
      'image_url': imageUrl,
    };
  }

  String get fullImageUrl => imageUrl.isNotEmpty ? imageUrl : ApiConfig.getImageUrl(image);
}

class Song {
  final int id;
  final String title;
  final String audioFile;
  final String audioFileUrl;
  final int duration;
  final Artist artist;
  final Album? album;
  final List<Category> categories;

  Song({
    required this.id,
    required this.title,
    required this.audioFile,
    required this.audioFileUrl,
    required this.duration,
    required this.artist,
    this.album,
    required this.categories,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    print('=== PARSING SONG ===');
    print('Song JSON: $json');
    
    final categoriesList = (json['categories'] as List?)
        ?.map((item) => Category.fromJson(item))
        .toList() ?? [];

    // Safe artist parsing
    Artist artist;
    try {
      artist = Artist.fromJson(json['artist'] ?? {});
    } catch (e) {
      print('Error parsing artist: $e');
      artist = Artist(
        id: 0,
        userId: 0,
        stageName: 'Unknown Artist',
        bio: '',
        image: null,
        imageUrl: '',
      );
    }

    // Safe album parsing
    Album? album;
    try {
      if (json['album'] != null) {
        album = Album.fromJson(json['album']);
      }
    } catch (e) {
      print('Error parsing album: $e');
      album = null;
    }

    final song = Song(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      audioFile: json['audio_file'] ?? '',
      audioFileUrl: json['audio_file_url'] ?? '',
      duration: json['duration'] ?? 0,
      artist: artist,
      album: album,
      categories: categoriesList,
    );
    
    print('Parsed Song: ${song.title} by ${song.artistName}');
    print('===================');
    
    return song;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'audio_file': audioFile,
      'audio_file_url': audioFileUrl,
      'duration': duration,
      'artist': artist.toJson(),
      'album': album?.toJson(),
      'categories': categories.map((cat) => cat.toJson()).toList(),
    };
  }

  String get durationFormatted {
    final minutes = (duration ~/ 60);
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get artistName => artist.stageName;
  String? get albumName => album?.title;
  String get fullAudioUrl => audioFileUrl.isNotEmpty ? ApiConfig.getAudioUrl(audioFileUrl) : ApiConfig.getAudioUrl(audioFile);
}

class Category {
  final int id;
  final String name;
  final String description;

  Category({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

class PaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final dataList = (json['data'] as List)
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();

    return PaginatedResponse<T>(
      data: dataList,
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 10,
      total: json['total'] ?? dataList.length,
    );
  }

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > 1;
}
