import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../data/models.dart';

String resolveApiRoot(String apiBaseUrl) {
  final uri = Uri.parse(apiBaseUrl);
  return "${uri.scheme}://${uri.authority}";
}

String resolveMediaUrl(String apiBaseUrl, String mediaUrl) {
  if (mediaUrl.startsWith("http://") || mediaUrl.startsWith("https://")) {
    return mediaUrl;
  }

  final root = resolveApiRoot(apiBaseUrl);
  return mediaUrl.startsWith("/") ? "$root$mediaUrl" : "$root/$mediaUrl";
}

class PostMediaView extends StatelessWidget {
  const PostMediaView({
    super.key,
    required this.apiBaseUrl,
    required this.mediaUrl,
    required this.mediaKind,
    this.maxHeight = 260,
  });

  final String apiBaseUrl;
  final String mediaUrl;
  final PostMediaKind mediaKind;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = resolveMediaUrl(apiBaseUrl, mediaUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        color: Colors.black.withAlpha(18),
        child: mediaKind == PostMediaKind.image
            ? Image.network(
                resolvedUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _MediaError(
                  icon: Icons.broken_image_outlined,
                  label: "Image unavailable",
                ),
              )
            : _VideoMediaPlayer(url: resolvedUrl),
      ),
    );
  }
}

class _VideoMediaPlayer extends StatefulWidget {
  const _VideoMediaPlayer({required this.url});

  final String url;

  @override
  State<_VideoMediaPlayer> createState() => _VideoMediaPlayerState();
}

class _VideoMediaPlayerState extends State<_VideoMediaPlayer> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(false);
      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (!_initialized) return;

    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const _MediaError(
        icon: Icons.videocam_off_rounded,
        label: "Video unavailable",
      );
    }

    if (!_initialized) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: _togglePlayback,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio == 0
                ? 16 / 9
                : _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          IgnorePointer(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(130),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _controller.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaError extends StatelessWidget {
  const _MediaError({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: Colors.white70),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
