import 'package:flutter/material.dart';

class ProfileImageContainer extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;

  const ProfileImageContainer(
      {super.key,
      required this.imagePath,
      required this.width,
      required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: width, // Ensure this width doesn't exceed the available space
      height: height, // Ensure this height doesn't exceed the available space
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.withOpacity(0.50),
      ),
      child: imagePath.isNotEmpty
          ? ClipOval(
              child: Image.asset(
                imagePath,
                width: width,
                height: height,
                fit: BoxFit.cover,
              ),
            )
          : const Center(
              child: Text(
                'pfp',
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: "Karla",
                    fontSize: 16), // Decreased the font size
              ),
            ),
    );
  }
}
