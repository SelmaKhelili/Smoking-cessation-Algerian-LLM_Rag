import 'package:equatable/equatable.dart';

class PodcastEpisode extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String duration;
  final String contentUrl; // backend URL for audio
  final String contentText; // full transcript

  const PodcastEpisode({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.contentUrl,
    required this.contentText,
  });

  factory PodcastEpisode.fromJson(Map<String, dynamic> json) {
    return PodcastEpisode(
      id: (json['id'] ?? 0).toString(),
      title: (json['title'] ?? 'Untitled').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      duration: json['reading_time'] != null ? '${json['reading_time']} min' : '0 min',
      contentUrl: (json['content_url'] ?? '').toString(),
      contentText: (json['content_text'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [id, title, subtitle, duration, contentUrl, contentText];
}
