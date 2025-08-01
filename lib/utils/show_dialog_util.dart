import 'package:flutter/material.dart';

Future<void> showResultDialog(BuildContext context, {required String title, required String message, Color? color}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: TextStyle(color: color ?? Colors.black, fontWeight: FontWeight.bold)),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('យល់ព្រម', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}