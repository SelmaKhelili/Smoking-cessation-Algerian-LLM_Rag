import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:my_app/core/network/url_data.dart';
import '../../domain/models/podcast_episode.dart';

class PodcastPage extends StatefulWidget {
  final Function(int)? onNavigate;
  const PodcastPage({super.key, this.onNavigate});

  @override
  State<PodcastPage> createState() => _PodcastPageState();
}

class _PodcastPageState extends State<PodcastPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<PodcastEpisode> _episodes = [];
  int? _expandedIndex;

  bool _isLoading = true;

  final String _backendUrl = '$BASE_URL/api/content?category=podcasts';

  @override
  void initState() {
    super.initState();
    _loadPodcasts();

    // Listen to play/pause state
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadPodcasts() async {
    try {
      final response = await http.get(Uri.parse(_backendUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List contentList = data['content'] ?? [];
        final podcasts = contentList.map((json) => PodcastEpisode.fromJson(json)).toList();

        if (mounted) {
          setState(() {
            _episodes = podcasts;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to fetch podcasts');
      }
    } catch (e) {
      debugPrint('Error loading podcasts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleEpisode(int index) async {
    if (_expandedIndex == index) {
      // Collapse current
      await _audioPlayer.stop();
      setState(() => _expandedIndex = null);
    } else {
      // Expand new one
      final episode = _episodes[index];
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(episode.contentUrl);
      setState(() => _expandedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFBF6),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Today's Podcasts",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B6EB9),
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_episodes.isEmpty)
                const Center(child: Text('No podcasts available'))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _episodes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final episode = _episodes[index];
                    final isExpanded = _expandedIndex == index;
                    return _PodcastCard(
                      episode: episode,
                      isExpanded: isExpanded,
                      audioPlayer: _audioPlayer,
                      onToggle: () => _toggleEpisode(index),
                      onPlayPause: () => setState(() {}),
                    );
                  },
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),

    );
  }
}

class _PodcastCard extends StatelessWidget {
  final PodcastEpisode episode;
  final bool isExpanded;
  final AudioPlayer audioPlayer;
  final VoidCallback onToggle;
  final VoidCallback onPlayPause;

  const _PodcastCard({
    required this.episode,
    required this.isExpanded,
    required this.audioPlayer,
    required this.onToggle,
    required this.onPlayPause,
  });

  List<TextSpan> _parseMarkdown(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      // Add normal text before bold
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      // Add bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isExpanded ? Border.all(color: const Color(0xFF1B6EB9), width: 1.5) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Expanded(
                  child: Text(
                    episode.title.isNotEmpty ? episode.title : "Untitled Podcast",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isExpanded ? const Color(0xFF1B6EB9) : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: isExpanded ? const Color(0xFF1B6EB9) : Colors.grey,
                ),
              ],
            ),
            
            if (isExpanded) ...[
              const SizedBox(height: 20),
              
              // Audio Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_30),
                    onPressed: () async {
                      final pos = audioPlayer.position;
                      await audioPlayer.seek(pos - const Duration(seconds: 30));
                    },
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (audioPlayer.playing) {
                        await audioPlayer.pause();
                      } else {
                        await audioPlayer.play();
                      }
                      onPlayPause();
                    },
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF1B6EB9),
                      child: Icon(
                        audioPlayer.playing ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_30),
                    onPressed: () async {
                      final pos = audioPlayer.position;
                      await audioPlayer.seek(pos + const Duration(seconds: 30));
                    },
                  ),
                ],
              ),
              
              // Progress Bar
              StreamBuilder<Duration>(
                stream: audioPlayer.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final total = audioPlayer.duration ?? const Duration(seconds: 1);
                  final value = (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
                  return Column(
                    children: [
                      Slider(
                        value: value,
                        activeColor: const Color(0xFF1B6EB9),
                        onChanged: (v) async {
                          final duration = audioPlayer.duration;
                          if (duration != null) {
                            await audioPlayer.seek(Duration(milliseconds: (v * duration.inMilliseconds).toInt()));
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              _formatDuration(total),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              
              // Content Text with markdown formatting (RTL for Arabic)
              Directionality(
                textDirection: TextDirection.rtl,
                child: RichText(
                  textAlign: TextAlign.right,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                    children: _parseMarkdown(episode.contentText),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
