import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Color backgroundColor;
  final Color detailsColor;
  final bool? goBack;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.goBack,
    required this.backgroundColor,
    required this.detailsColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(color: detailsColor, fontWeight: FontWeight.bold),
      ),
      backgroundColor: backgroundColor,
      actions: actions,
      iconTheme: IconThemeData(color: detailsColor),
      automaticallyImplyLeading: goBack ?? false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
