import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/ui_sections/drawer.dart';

class AnimatedSidebarScaffold extends StatefulWidget {
  final Widget child;

  const AnimatedSidebarScaffold({Key? key, required this.child}) : super(key: key);

  static _AnimatedSidebarScaffoldState? of(BuildContext context) {
    return context.findAncestorStateOfType<_AnimatedSidebarScaffoldState>();
  }

  @override
  _AnimatedSidebarScaffoldState createState() => _AnimatedSidebarScaffoldState();
}

class _AnimatedSidebarScaffoldState extends State<AnimatedSidebarScaffold>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 0.75).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void toggleMenu() {
    if (_isMenuOpen) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void closeMenu() {
    if (_isMenuOpen) {
      _animationController.reverse();
      setState(() {
        _isMenuOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF161000), // Earth black
              Color(0xFF2A3D0F), // Muted forest green
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Background Sidebar Menu
          const MainDrawer(),

          // Foreground Animated Content
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..translate(_slideAnimation.value * screenWidth)
                  ..scale(_scaleAnimation.value),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(_isMenuOpen ? 24.0 : 0.0),
                  child: GestureDetector(
                    onTap: _isMenuOpen ? toggleMenu : null,
                    behavior: HitTestBehavior.opaque,
                    child: IgnorePointer(
                      ignoring: _isMenuOpen,
                      child: widget.child,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}
}
