import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  const Background({
    super.key,
    required this.child,
    this.appBar,
    this.topImage = "assets/images/images.png",
    this.bottomImage = "assets/images/background-right.svg",
  });

  final String topImage, bottomImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: appBar,
      body: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned(
              top: 0,
              left: 0,
              child: Image.asset(topImage, width: 120),
            ),
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }
}
