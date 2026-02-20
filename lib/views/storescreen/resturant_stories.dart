import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class RestaurantStories extends StatefulWidget {
  final List<dynamic> storiesData;

  RestaurantStories({required this.storiesData});

  @override
  _RestaurantStoriesState createState() => _RestaurantStoriesState();
}

class _RestaurantStoriesState extends State<RestaurantStories>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  late AnimationController _animController;
  Timer? _imageTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this);
    _loadStory();
  }

  void _loadStory() async {
    _animController.stop();
    _animController.reset();
    _imageTimer?.cancel();
    _videoController?.removeListener(_checkVideoEnd);
    _videoController?.dispose();

    final currentStory = widget.storiesData[_currentIndex];

    if (currentStory['media_type'] == 'video') {
      _isVideo = true;
      _videoController =
          VideoPlayerController.network(currentStory['media_url'])
            ..initialize().then((_) {
              setState(() {});
              _videoController!.play();
              _videoController!.addListener(_checkVideoEnd);
              final duration = _videoController!.value.duration;
              _animController.duration = duration;
              _animController.forward();
            });
    } else {
      _isVideo = false;
      _animController.duration = Duration(seconds: 5);
      _animController.forward();
      _imageTimer = Timer(Duration(seconds: 5), _nextStory);
    }
  }

  void _checkVideoEnd() {
    if (_videoController != null &&
        _videoController!.value.position >= _videoController!.value.duration) {
      _videoController!.removeListener(_checkVideoEnd);
      _nextStory();
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.storiesData.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _loadStory();
    } else {
      Navigator.pop(context); // End of stories
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _loadStory();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _animController.dispose();
    _imageTimer?.cancel();
    super.dispose();
  }

  Widget _buildProgressBar(int index) {
    if (index < _currentIndex) {
      return Expanded(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 2),
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    } else if (index == _currentIndex) {
      return Expanded(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 2),
          height: 4,
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerRight,
                widthFactor: _animController.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            },
          ),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    } else {
      return Expanded(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 2),
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStory = widget.storiesData[_currentIndex];
    final caption = currentStory['caption'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _isVideo
                ? (_videoController != null &&
                        _videoController!.value.isInitialized)
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : CircularProgressIndicator()
                : Image.network(
                    currentStory['media_url'],
                    fit: BoxFit.contain,
                  ),
          ),
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              children: List.generate(
                widget.storiesData.length,
                (index) => _buildProgressBar(index),
              ),
            ),
          ),
          if (caption.isNotEmpty)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Text(
                caption,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _previousStory,
                  onVerticalDragEnd: (_) => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _nextStory,
                  onVerticalDragEnd: (_) => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
