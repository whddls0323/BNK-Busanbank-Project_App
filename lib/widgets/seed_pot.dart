import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SeedPotWidget extends StatelessWidget {
  final String status;

  const SeedPotWidget({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      status == 'SUCCESS'
          ? Icons.emoji_events   // 황금 열매
          : Icons.local_florist, // 일반 열매
      size: 120,
      color: status == 'SUCCESS'
          ? Colors.amber
          : Colors.green,
    );
  }
}