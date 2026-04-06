import 'package:flutter/material.dart';

class PriceTag extends StatelessWidget {
  final double price;
  final TextStyle? style;

  const PriceTag({
    super.key,
    required this.price,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      price.toStringAsFixed(2),
      style: style ??
          TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
      semanticsLabel: 'Price: ${price.toStringAsFixed(2)}',
    );
  }
}
