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
            // Positioned(
            //   bottom: 0,
            //   right: 0,
            //   child: SvgPicture.asset(
            //     bottomImage,
            //     width: 150,
            //     height: 150,
            //     color: const Color.fromARGB(255, 118, 118, 121),
            //   ),
            // ),
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }
}
