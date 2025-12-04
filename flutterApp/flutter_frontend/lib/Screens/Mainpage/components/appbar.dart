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
      iconTheme: IconThemeData(color: detailsColor),
      automaticallyImplyLeading: false,
      actions: [
        ...(actions ?? []),
        if (goBack ?? false)
          IconButton(
            icon: Icon(Icons.arrow_forward, color: detailsColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
