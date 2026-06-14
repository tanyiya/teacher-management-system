import 'package:flutter/material.dart';
import '../../app_theme.dart';

class IosCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const IosCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.only(bottom: 16.0),
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.subtleGrayBoundary, width: 1),
        boxShadow: AppTheme.iosBoxShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return Padding(
        padding: margin,
        child: GestureDetector(
          onTap: onTap,
          child: cardContent,
        ),
      );
    }

    return Padding(
      padding: margin,
      child: cardContent,
    );
  }
}
