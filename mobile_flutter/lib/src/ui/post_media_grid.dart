import 'package:flutter/material.dart';

import 'post_media.dart';

class PostMediaGridView extends StatelessWidget {
  const PostMediaGridView({
    super.key,
    required this.apiBaseUrl,
    required this.mediaUrls,
    this.maxHeight = 300,
  });

  final String apiBaseUrl;
  final List<String> mediaUrls;
  final double maxHeight;

  int _getColumnCount() {
    if (mediaUrls.length <= 1) return 1;
    if (mediaUrls.length <= 3) return mediaUrls.length;
    return 3; // 2 rows for 4-6 images
  }

  @override
  Widget build(BuildContext context) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();

    // Single image - use full width
    if (mediaUrls.length == 1) {
      final imageUrl = resolveMediaUrl(apiBaseUrl, mediaUrls[0]);
      return GestureDetector(
        onTap: () => _openGallery(context, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            imageUrl,
            height: maxHeight,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                height: maxHeight,
                width: double.infinity,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: maxHeight,
                width: double.infinity,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
              );
            },
          ),
        ),
      );
    }

    // Multiple images - use grid
    final columnCount = _getColumnCount();
    final rowCount = (mediaUrls.length / columnCount).ceil();
    final gridHeight = (maxHeight / rowCount).clamp(100.0, 200.0) * rowCount;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: gridHeight,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.0,
          ),
          itemCount: mediaUrls.length,
          itemBuilder: (context, index) {
            final imageUrl = resolveMediaUrl(apiBaseUrl, mediaUrls[index]);
            return GestureDetector(
              onTap: () => _openGallery(context, index),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _openGallery(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullscreenGallery(
          apiBaseUrl: apiBaseUrl,
          mediaUrls: mediaUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  const _FullscreenGallery({
    required this.apiBaseUrl,
    required this.mediaUrls,
    required this.initialIndex,
  });

  final String apiBaseUrl;
  final List<String> mediaUrls;
  final int initialIndex;

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.mediaUrls.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.mediaUrls.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          final imageUrl =
              resolveMediaUrl(widget.apiBaseUrl, widget.mediaUrls[index]);
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image, size: 64, color: Colors.white54),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
