import 'package:flutter/material.dart';

class BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selectedIndex;
  final Function(int) onTap;
  final Color activeColor;
  final Color inactiveColor;
  final double iconSize;

  const BottomNavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = index == selectedIndex;
    final Color currentColor = isActive ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: currentColor),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: currentColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}