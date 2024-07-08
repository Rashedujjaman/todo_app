import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String categoryName;

  CategoryChip({required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(categoryName),
      // You can customize the chip's appearance
    );
  }
}
