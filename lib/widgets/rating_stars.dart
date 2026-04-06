import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 18.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Rating: $rating stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          if (index < rating.floor()) {
            return Icon(Icons.star, size: size, color: color ?? Colors.amber);
          } else if (index < rating.ceil() && rating - index >= 0.3) {
            return Icon(Icons.star_half, size: size, color: color ?? Colors.amber);
          } else {
            return Icon(Icons.star_border, size: size, color: color ?? Colors.amber);
          }
        }),
      ),
    );
  }
}
