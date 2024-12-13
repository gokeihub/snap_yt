import 'package:flutter/material.dart';

class SettingFieldWidget extends StatelessWidget {
  final TextEditingController? textEditingController;
  final String hintText;
  const SettingFieldWidget({
    super.key,
    this.textEditingController,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: TextField(
            controller: textEditingController,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Colors.grey,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
