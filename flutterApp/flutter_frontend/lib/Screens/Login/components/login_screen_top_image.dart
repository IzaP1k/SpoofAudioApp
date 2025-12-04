import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter_frontend/constants.dart';

class LoginScreenTopImage extends StatelessWidget {
  const LoginScreenTopImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "LOGOWANIE",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: defaultPadding * 2),
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 8,
              child: Align(
                alignment: Alignment.center,
                child: SvgPicture.asset("assets/icons/login.svg", width: 360),
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: defaultPadding * 2),
      ],
    );
  }
}
