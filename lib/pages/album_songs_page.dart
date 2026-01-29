import 'package:flutter/material.dart';
import '../services/music_service.dart';
import '../models/music.dart';
import 'music_player_page.dart';

class AlbumSongsPage extends StatefulWidget {
  final Album album;

  const AlbumSongsPage({super.key, required this.album});

  @override
  State<AlbumSongsPage> createState() => _AlbumSongsPageState();
}

class _AlbumSongsPageState extends State<AlbumSongsPage> {
  List<Song> _songs = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMoreSongs = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs({bool refresh = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      if (refresh) {
        _songs.clear();
        _currentPage = 1;
        _hasMoreSongs = true;
      }
    });

    try {
      final response = await MusicService.getSongsByAlbum(
        albumId: widget.album.id,
        page: _currentPage,
      );
      setState(() {
        if (refresh) {
          _songs = response.data;
        } else {
          _songs.addAll(response.data);
        }
        _hasMoreSongs = response.hasNextPage;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load songs: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadSongs(refresh: true),
        child: Column(
          children: [
            // Album Header
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Hero(
                    tag: 'album_${widget.album.id}',
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[300],
                      ),
                      child: widget.album.fullImageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.album.fullImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.album, size: 40);
                                },
                              ),
                            )
                          : const Icon(Icons.album, size: 40),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.album.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.album.artist.stageName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        if (widget.album.releaseDate.isNotEmpty)
                          Text(
                            widget.album.releaseDate,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            
            // Songs List
            Expanded(
              child: _buildSongsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsList() {
    if (_songs.isEmpty && !_isLoading) {
      return const Center(
        child: Text('No songs found in this album'),
      );
    }

    return ListView.builder(
      itemCount: _songs.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _songs.length && _isLoading) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final song = _songs[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: song.artist.fullImageUrl.isNotEmpty
                ? NetworkImage(song.artist.fullImageUrl)
                : null,
            child: song.artist.fullImageUrl.isEmpty
                ? const Icon(Icons.music_note)
                : null,
          ),
          title: Text(song.title),
          subtitle: Text(song.artistName),
          trailing: Text(song.durationFormatted),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MusicPlayerPage(
                  song: song,
                  playlist: _songs,
                  initialIndex: index,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
