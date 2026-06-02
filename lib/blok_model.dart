
import 'package:flutter/material.dart';

class BlokModeli {
  final int number;
  final Color color;
  bool isSelected;

  BlokModeli({
    required this.number,
    required this.color,
    this.isSelected = false,
  });
}