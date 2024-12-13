import 'package:flutter/material.dart';

class SettingFieldButtonWidget extends StatelessWidget {
  final Color color;
  final String buttonText;
  final Function()? onTap;
  const SettingFieldButtonWidget({
    super.key,
    this.color = Colors.green,
    required this.buttonText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color,
        ),
        child: Center(
          child: Text(
            buttonText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ),
      ),
    );
  }
}
