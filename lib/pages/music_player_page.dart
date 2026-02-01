import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/music.dart';

class MusicPlayerPage extends StatefulWidget {
  final Song song;
  final List<Song> playlist;
  final int initialIndex;

  const MusicPlayerPage({
    super.key,
    required this.song,
    required this.playlist,
    this.initialIndex = 0,
  });

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  late AudioPlayer _audioPlayer;
  late Song _currentSong;
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  
  // Stream subscriptions to prevent memory leaks
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _currentSong = widget.song;
    _currentIndex = widget.initialIndex;
    
    // Setup stream subscriptions with proper cleanup
    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Auto-play the current song
    _playSong(_currentSong);
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    
    // Dispose audio player
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSong(Song song) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await _audioPlayer.stop();
      
      // Check if audio URL is valid
      if (song.fullAudioUrl.isEmpty) {
        throw Exception('Audio URL is empty');
      }
      
      print('=== ATTEMPTING TO PLAY AUDIO ===');
      print('Audio URL: ${song.fullAudioUrl}');
      print('Song Title: ${song.title}');
      print('===============================');
      
      // Try to play with better error handling
      try {
        await _audioPlayer.play(UrlSource(song.fullAudioUrl));
        
        if (mounted) {
          setState(() {
            _currentSong = song;
            _isLoading = false;
          });
        }
      } catch (playError) {
        print('Audio play error: $playError');
        
        // Try alternative approach for Android
        try {
          await _audioPlayer.setSource(UrlSource(song.fullAudioUrl));
          await _audioPlayer.resume();
          
          if (mounted) {
            setState(() {
              _currentSong = song;
              _isLoading = false;
            });
          }
        } catch (altError) {
          throw Exception('Failed to play audio: $playError. Alternative approach failed: $altError');
        }
      }
    } catch (e) {
      print('Complete audio error: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio playback failed: ${e.toString()}'),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _playSong(song),
            ),
          ),
        );
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> _playNext() async {
    if (_currentIndex < widget.playlist.length - 1) {
      final nextIndex = _currentIndex + 1;
      final nextSong = widget.playlist[nextIndex];
      setState(() {
        _currentIndex = nextIndex;
      });
      await _playSong(nextSong);
    }
  }

  Future<void> _playPrevious() async {
    if (_currentIndex > 0) {
      final prevIndex = _currentIndex - 1;
      final prevSong = widget.playlist[prevIndex];
      setState(() {
        _currentIndex = prevIndex;
      });
      await _playSong(prevSong);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Show more options
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Album Art
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.purple.shade400,
                            Colors.pink.shade400,
                          ],
                        ),
                      ),
                      child: _currentSong.album?.fullImageUrl.isNotEmpty == true
                          ? Image.network(
                              _currentSong.album!.fullImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAlbumArt();
                              },
                            )
                          : _buildDefaultAlbumArt(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Song Info
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentSong.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentSong.artistName,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_currentSong.albumName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _currentSong.albumName!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Progress Bar
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.purple.shade400,
                      inactiveTrackColor: Colors.white.withOpacity(0.2),
                      thumbColor: Colors.purple.shade400,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayColor: Colors.purple.shade400.withOpacity(0.2),
                    ),
                    child: Slider(
                      min: 0.0,
                      max: _duration.inSeconds.toDouble(),
                      value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
                      onChanged: (value) async {
                        final position = Duration(seconds: value.toInt());
                        await _audioPlayer.seek(position);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: Colors.white.withOpacity(0.7),
                      size: 24,
                    ),
                    onPressed: () {
                      // Shuffle functionality
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.skip_previous,
                      color: Colors.white,
                      size: 40,
                    ),
                    onPressed: _playPrevious,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.purple.shade400,
                    ),
                    child: IconButton(
                      icon: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 40,
                            ),
                      onPressed: _isLoading ? null : _togglePlayPause,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.skip_next,
                      color: Colors.white,
                      size: 40,
                    ),
                    onPressed: _playNext,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.repeat,
                      color: Colors.white.withOpacity(0.7),
                      size: 24,
                    ),
                    onPressed: () {
                      // Repeat functionality
                    },
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Additional Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.favorite_border,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    onPressed: () {
                      // Like functionality
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.playlist_play,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    onPressed: () {
                      _showPlaylist();
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.share,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    onPressed: () {
                      // Share functionality
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAlbumArt() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade400,
            Colors.pink.shade400,
          ],
        ),
      ),
      child: const Icon(
        Icons.music_note,
        size: 80,
        color: Colors.white,
      ),
    );
  }

  void _showPlaylist() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Color(0xFF2E2E3E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Playlist',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.playlist.length,
                itemBuilder: (context, index) {
                  final song = widget.playlist[index];
                  final isCurrentSong = index == _currentIndex;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: song.artist.fullImageUrl.isNotEmpty
                          ? NetworkImage(song.artist.fullImageUrl)
                          : null,
                      child: song.artist.fullImageUrl.isEmpty
                          ? const Icon(Icons.music_note)
                          : null,
                    ),
                    title: Text(
                      song.title,
                      style: TextStyle(
                        color: isCurrentSong ? Colors.purple.shade400 : Colors.white,
                        fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      song.artistName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    trailing: isCurrentSong
                        ? Icon(Icons.play_arrow, color: Colors.purple.shade400)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentIndex = index;
                      });
                      _playSong(song);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
