import 'package:flutter/material.dart';

class EmptyWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;

  const EmptyWidget({
    super.key, 
    required this.icon, 
    required this.message, 
    required this.sub
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(message, 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 8),
            Text(sub, textAlign: TextAlign.center, 
              style: const TextStyle(color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}