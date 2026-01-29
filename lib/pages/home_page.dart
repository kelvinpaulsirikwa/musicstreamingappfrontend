import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/music_service.dart';
import '../models/user.dart';
import '../models/music.dart';
import 'album_songs_page.dart';
import 'music_player_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _currentUser;
  bool _isLoading = true;
  
  // Music data
  List<Album> _albums = [];
  List<Song> _recentSongs = [];
  int _currentAlbumPage = 1;
  int _currentSongsPage = 1;
  bool _isLoadingAlbums = false;
  bool _isLoadingSongs = false;
  bool _hasMoreAlbums = true;
  bool _hasMoreSongs = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await AuthService.getUser();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
      
      // Load music data after user data is loaded
      _loadAlbums();
      _loadRecentSongs();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAlbums({bool refresh = false}) async {
    if (_isLoadingAlbums) return;
    
    setState(() {
      _isLoadingAlbums = true;
      if (refresh) {
        _albums.clear();
        _currentAlbumPage = 1;
        _hasMoreAlbums = true;
      }
    });

    try {
      final response = await MusicService.getAlbums(page: _currentAlbumPage);
      setState(() {
        if (refresh) {
          _albums = response.data;
        } else {
          _albums.addAll(response.data);
        }
        _hasMoreAlbums = response.hasNextPage;
        _currentAlbumPage++;
        _isLoadingAlbums = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAlbums = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load albums: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadRecentSongs({bool refresh = false}) async {
    if (_isLoadingSongs) return;
    
    setState(() {
      _isLoadingSongs = true;
      if (refresh) {
        _recentSongs.clear();
        _currentSongsPage = 1;
        _hasMoreSongs = true;
      }
    });

    try {
      final response = await MusicService.getRecentSongs(page: _currentSongsPage);
      print('=== SONGS RESPONSE PROCESSED ===');
      print('Songs count: ${response.data.length}');
      print('First song: ${response.data.isNotEmpty ? response.data.first.title : "None"}');
      print('===============================');
      
      setState(() {
        if (refresh) {
          _recentSongs = response.data;
        } else {
          _recentSongs.addAll(response.data);
        }
        _hasMoreSongs = response.hasNextPage;
        _currentSongsPage++;
        _isLoadingSongs = false;
      });
      
      print('UI State Updated - Songs in list: ${_recentSongs.length}');
    } catch (e) {
      setState(() {
        _isLoadingSongs = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load songs: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Stream'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser != null
              ? RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      _loadAlbums(refresh: true),
                      _loadRecentSongs(refresh: true),
                    ]);
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Profile Section
                        _buildUserProfileSection(),
                        const SizedBox(height: 24),

                        // Albums Section
                        _buildSectionTitle('Albums'),
                        const SizedBox(height: 12),
                        _buildAlbumsGrid(),
                        if (_hasMoreAlbums)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: _buildLoadMoreButton(
                              isLoading: _isLoadingAlbums,
                              onPressed: () => _loadAlbums(),
                              text: 'Load More Albums',
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Recent Songs Section
                        _buildSectionTitle('Recent Songs'),
                        const SizedBox(height: 12),
                        _buildSongsList(),
                        if (_hasMoreSongs)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: _buildLoadMoreButton(
                              isLoading: _isLoadingSongs,
                              onPressed: () => _loadRecentSongs(),
                              text: 'Load More Songs',
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : const Center(
                  child: Text('Error loading user data'),
                ),
    );
  }

  Widget _buildUserProfileSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(_currentUser!.image),
              onBackgroundImageError: (exception, stackTrace) {},
              child: _currentUser!.image.isEmpty ||
                      _currentUser!.image == 'https://via.placeholder.com/150'
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUser!.username,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currentUser!.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAlbumsGrid() {
    if (_albums.isEmpty && !_isLoadingAlbums) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text('No albums found'),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _albums.length + (_isLoadingAlbums ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _albums.length && _isLoadingAlbums) {
          return const Card(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final album = _albums[index];
        print('=== DISPLAYING ALBUM ===');
        print('Album Title: ${album.title}');
        print('Cover Image URL: ${album.coverImageUrl}');
        print('Full Image URL: ${album.fullImageUrl}');
        print('IsNotEmpty: ${album.fullImageUrl.isNotEmpty}');
        print('========================');
        
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AlbumSongsPage(album: album),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                    ),
                    child: album.fullImageUrl.isNotEmpty
                        ? Image.network(
                            album.fullImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.album, size: 48);
                            },
                          )
                        : const Icon(Icons.album, size: 48),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          album.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          album.artist.stageName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (album.releaseDate.isNotEmpty)
                          Text(
                            album.releaseDate,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSongsList() {
    if (_recentSongs.isEmpty && !_isLoadingSongs) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text('No songs found'),
          ),
        ),
      );
    }

    return Column(
      children: [
        ..._recentSongs.asMap().entries.map((entry) {
          final index = entry.key;
          final song = entry.value;
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: song.artist.fullImageUrl.isNotEmpty
                    ? NetworkImage(song.artist.fullImageUrl)
                    : null,
                child: song.artist.fullImageUrl.isEmpty
                    ? const Icon(Icons.music_note)
                    : null,
              ),
              title: Text(song.title),
              subtitle: Text('${song.artistName}${song.albumName != null ? ' • ${song.albumName}' : ''}'),
              trailing: Text(song.durationFormatted),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MusicPlayerPage(
                      song: song,
                      playlist: _recentSongs,
                      initialIndex: index,
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
        if (_isLoadingSongs)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadMoreButton({
    required bool isLoading,
    required VoidCallback onPressed,
    required String text,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      child: isLoading
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading...'),
              ],
            )
          : Text(text),
    );
  }
}
