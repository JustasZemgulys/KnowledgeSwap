import 'dart:io';
import 'package:flutter/material.dart';

class ImageContainer extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;

  const ImageContainer(
      {super.key,
      required this.imagePath,
      required this.width,
      required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: width,
      height: height,
      color: Colors.grey.withOpacity(0.50), // Set the default grey color

      child: imagePath.isNotEmpty // Check if imagePath is not empty
          ? Image.file(
              File(imagePath),
              width: width,
              height: height,
              fit: BoxFit.cover,
            )
          : const Center(
              child: Text(
                'Cover Image',
                style: TextStyle(color: Colors.black, fontFamily: "Karla"),
              ),
            ),
    );
  }
}
