import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;
  const MyButton({
    super.key,
    required this.text,
    this.icon,
    required this.color, required Null Function() onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: () {
        Navigator.pushReplacementNamed(context, '/home');
      },
      color: color,
      textColor: Colors.white,
      minWidth: 380,
      height: 50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          SizedBox(width: 8),

          Icon(icon, color: Colors.white),
        ],
      ),
    );
  }
}
