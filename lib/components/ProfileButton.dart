// ProfileButton.dart
import 'package:flutter/material.dart';

class ProfileButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap; // Add this

  const ProfileButton({super.key, required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(50),
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.white),
          title: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'KhmerFont',
              fontSize: 16,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white,
            size: 16,
          ),
          onTap: onTap, // Use the callback
        ),
      ),
    );
  }
}