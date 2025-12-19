import 'dart:math';

import 'package:flutter/material.dart';

class SwipeableCard extends StatefulWidget {
  final Widget child;
  final Function(bool isLike) onSwipe;
  final VoidCallback? onTap;
  final Object identity;

  const SwipeableCard({
    super.key,
    required this.child,
    required this.onSwipe,
    required this.identity,
    this.onTap,
  });

  @override
  State<SwipeableCard> createState() => SwipeableCardState();
}

class SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _dragOffset = Offset.zero;
  double _angle = 0;
  bool _isSwiping = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(covariant SwipeableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Когда меняется "сущность" карточки (другой пользователь/ивент),
    // сбрасываем смещение и угол, чтобы новая карточка начинала из центра.
    if (widget.identity != oldWidget.identity) {
      _controller.stop();
      setState(() {
        _dragOffset = Offset.zero;
        _angle = 0;
        _isSwiping = false;
      });
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isSwiping) return;
    setState(() {
      _dragOffset = Offset.zero;
      _angle = 0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isSwiping || _controller.isAnimating) return;

    setState(() {
      _dragOffset += details.delta;
      // Rotation logic matching RN's interpolation
      _angle = (_dragOffset.dx / 1000) * (pi / 4); // Max ~45 degrees

      // Vertical movement is limited but allowed for a more natural feel
      _dragOffset = Offset(
        _dragOffset.dx,
        _dragOffset.dy.clamp(-100, 100),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isSwiping || _controller.isAnimating) return;

    final threshold = MediaQuery.of(context).size.width * 0.35;
    final velocity = details.velocity.pixelsPerSecond.dx;

    bool shouldSwipe = _dragOffset.dx.abs() > threshold;
    bool isLike = _dragOffset.dx > 0;

    // Fast swipe detection
    if (velocity.abs() > 800) {
      shouldSwipe = true;
      isLike = velocity > 0;
    }

    if (shouldSwipe) {
      _swipeOffScreen(isLike);
    } else {
      _resetPosition();
    }
  }

  void _swipeOffScreen(bool isLike) {
    if (_isSwiping) return;
    _isSwiping = true;

    final screenWidth = MediaQuery.of(context).size.width;
    final direction = isLike ? 1 : -1;
    final endX = direction * (screenWidth * 1.5);

    final animation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(endX, _dragOffset.dy * 0.5),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    final angleAnimation = Tween<double>(
      begin: _angle,
      end: direction * 0.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    animation.addListener(() {
      if (mounted) {
        setState(() {
          _dragOffset = animation.value;
        });
      }
    });

    angleAnimation.addListener(() {
      if (mounted) {
        setState(() {
          _angle = angleAnimation.value;
        });
      }
    });

    _controller.forward().then((_) {
      widget.onSwipe(isLike);
      if (mounted) {
        _isSwiping = false;
        _controller.reset();
      }
    });
  }

  void _resetPosition() {
    final animation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    final angleAnimation = Tween<double>(
      begin: _angle,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    animation.addListener(() {
      if (mounted) {
        setState(() {
          _dragOffset = animation.value;
        });
      }
    });

    angleAnimation.addListener(() {
      if (mounted) {
        setState(() {
          _angle = angleAnimation.value;
        });
      }
    });

    _controller.forward().then((_) {
      if (mounted) {
        _controller.reset();
      }
    });
  }

  void swipe(bool isLike) {
    if (_isSwiping || _controller.isAnimating) return;
    _swipeOffScreen(isLike);
  }

  void reset() {
    if (_controller.isAnimating) {
      _controller.stop();
    }
    setState(() {
      _dragOffset = Offset.zero;
      _angle = 0;
      _isSwiping = false;
    });
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Opacity slightly fades as we swipe
    final opacity = 1.0 - (_dragOffset.dx.abs() / screenWidth) * 0.5;

    return Transform.translate(
      offset: _dragOffset,
      child: Transform.rotate(
        angle: _angle,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: GestureDetector(
            behavior: HitTestBehavior
                .opaque, // Ensure it catches swipes on empty areas of the card
            onTap: widget.onTap,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Stack(
              children: [
                widget.child,
                _buildOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    const threshold = 80.0;
    final dx = _dragOffset.dx;
    final opacity = (dx.abs() / threshold).clamp(0.0, 1.0);

    if (dx > 0) {
      return Positioned(
        top: 40,
        left: 20,
        child: Opacity(
          opacity: opacity,
          child: Transform.rotate(
            angle: -pi / 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'LIKE',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    } else if (dx < 0) {
      return Positioned(
        top: 40,
        right: 20,
        child: Opacity(
          opacity: opacity,
          child: Transform.rotate(
            angle: pi / 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'NOPE',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
