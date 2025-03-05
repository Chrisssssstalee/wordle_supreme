import 'package:flutter/material.dart';

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShakeWidget({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
  }) : super(key: key);

  @override
  ShakeWidgetState createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
  with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    late Animation<double> _offsetAnimation;

    @override
    void initState() {
      super.initState();

      _controller = AnimationController(
        duration: widget.duration,
        vsync: this,
      );

      _offsetAnimation = TweenSequence(
        <TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: Tween(begin: 0.0, end: 10.0).chain(CurveTween(curve: Curves.elasticIn)),
            weight: 1,
          ),
          TweenSequenceItem<double>(
            tween: Tween(begin: 10.0, end: 0.0).chain(CurveTween(curve: Curves.elasticInOut)),
            weight: 1,
          ),
        ],
      ).animate(_controller);
    }
    void shake() {
      _controller.forward(from: 0.0);
    }
    
    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return AnimatedBuilder(
        animation: _offsetAnimation, 
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_offsetAnimation.value, 0),
            child: child,
          );
        },
        child: widget.child,
      );
    }
  }