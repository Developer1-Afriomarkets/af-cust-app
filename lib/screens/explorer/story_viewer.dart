import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';

class StoryViewer extends StatefulWidget {
  final Map<String, dynamic> spotlight;

  const StoryViewer({Key? key, required this.spotlight}) : super(key: key);

  @override
  _StoryViewerState createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentIndex = 0;
  List<dynamic> _stories = [];

  @override
  void initState() {
    super.initState();
    _stories = widget.spotlight['stories'] ?? [];
    _pageController = PageController();
    _animationController = AnimationController(vsync: this);

    _loadStory(0, animateToPage: false);
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.stop();
        _animationController.reset();
        setState(() {
          if (_currentIndex + 1 < _stories.length) {
            _currentIndex += 1;
            _loadStory(_currentIndex);
          } else {
            // Out of bounds, exit story
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadStory(int index, {bool animateToPage = true}) {
    if (index >= _stories.length || index < 0) return;
    
    final storyDuration = _stories[index]['duration'] ?? 5;
    _animationController.duration = Duration(seconds: storyDuration);
    _animationController.forward();

    if (animateToPage) {
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onTapDown(TapDownDetails details) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dx = details.globalPosition.dx;
    if (dx < screenWidth / 3) {
      // Go back
      setState(() {
        if (_currentIndex - 1 >= 0) {
          _currentIndex -= 1;
          _loadStory(_currentIndex);
        } else {
          // Reset current
          _loadStory(0);
        }
      });
    } else {
      // Go forward
      setState(() {
        if (_currentIndex + 1 < _stories.length) {
          _currentIndex += 1;
          _loadStory(_currentIndex);
        } else {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _onLongPress() {
    _animationController.stop();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty) {
      return const Scaffold(body: Center(child: Text("No stories available")));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onTapDown,
        onLongPress: _onLongPress,
        onLongPressEnd: _onLongPressEnd,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stories.length,
              itemBuilder: (context, i) {
                final story = _stories[i];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: story['mediaUrl'] ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                      errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                    ),
                    // Gradient overlay for text readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      left: 20,
                      right: 20,
                      child: Text(
                        story['caption'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
            // Progress Bars
            Positioned(
              top: 40.0,
              left: 10.0,
              right: 10.0,
              child: Row(
                children: _stories.asMap().entries.map((entry) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: AnimatedProgressBar(
                        animController: _animationController,
                        position: entry.key,
                        currentIndex: _currentIndex,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Header (Close button & Title)
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.spotlight['title'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedProgressBar extends StatelessWidget {
  final AnimationController animController;
  final int position;
  final int currentIndex;

  const AnimatedProgressBar({
    Key? key,
    required this.animController,
    required this.position,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          position == currentIndex
              ? AnimatedBuilder(
                  animation: animController,
                  builder: (context, child) {
                    return Container(
                      height: 3,
                      width: constraints.maxWidth * animController.value,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                )
              : Container(
                  height: 3,
                  width: position < currentIndex ? constraints.maxWidth : 0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
        ],
      );
    });
  }
}
