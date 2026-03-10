import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ReflexGame(),
  ));
}

class ReflexGame extends StatefulWidget {
  const ReflexGame({super.key});

  @override
  State<ReflexGame> createState() => _ReflexGameState();
}

class _ReflexGameState extends State<ReflexGame>
    with SingleTickerProviderStateMixin {
  int approachRateMs = 1000;
  double circleRadius = 40.0;
  final GlobalKey _playfieldKey = GlobalKey();
  Size _playfieldSize = Size.zero;
  final double edgeMargin = 8.0;

  int score = 0;
  int misses = 0;

  final Random _random = Random();
  Offset targetPos = const Offset(200, 300);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: approachRateMs),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => misses++);
        _spawnNewTarget();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _spawnNewTarget());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spawnNewTarget() {
    if(_playfieldSize == Size.zero) return;

    final double minX = circleRadius + edgeMargin;
    final double maxX = _playfieldSize.width - circleRadius - edgeMargin;

    final double minY = circleRadius + edgeMargin;
    final double maxY = _playfieldSize.height - circleRadius - edgeMargin;

    if (maxX <= minX || maxY <= minY) {
      // Not enough space to spawn a target
      return;
    }

    final double nextX = minX + _random.nextDouble() * (maxX - minX);
    final double nextY = minY + _random.nextDouble() * (maxY - minY);

    setState(() => targetPos = Offset(nextX, nextY));

    _controller
      ..stop()
      ..reset()
      ..forward();
  }

  void _handleTap(TapDownDetails details) {
    final touch = details.localPosition;
    final dist = (touch - targetPos).distance;

    if (dist <= circleRadius) {
      setState(() => score++);
      _spawnNewTarget();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Score: $score   Misses: $misses'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _playfieldSize = Size(constraints.maxWidth, constraints.maxHeight);

            return GestureDetector(
            key: _playfieldKey,
            behavior: HitTestBehavior.opaque,
            onTapDown: _handleTap,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: TargetPainter(
                    position: targetPos,
                    radius: circleRadius,
                    opacity: 1.0 - (2.0 * _controller.value - 0.5).abs()));
              }
              ),
            );
          },
        ),
      ),
    );
  }
}

class TargetPainter extends CustomPainter {
  final Offset position;
  final double radius;
  final double opacity;

  const TargetPainter({
    required this.position,
    required this.radius,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final circlePaint = Paint()
      ..color = Colors.blueAccent.withOpacity(opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, radius, circlePaint);
  }

  @override
  bool shouldRepaint(covariant TargetPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.radius != radius ||
        oldDelegate.opacity != opacity;
  }
}
