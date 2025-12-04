import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/responsive.dart';

import 'package:flutter_frontend/components/background.dart';
import 'package:flutter_frontend/Screens/Welcome/components/login_signup_btn.dart';
import 'package:flutter_frontend/Screens/Welcome/components/welcome_image.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Background(
      appBar: null,
      child: SingleChildScrollView(
        child: Responsive(
          mobile: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              WelcomeImage(),
              Row(
                children: [
                  Spacer(),
                  Expanded(flex: 8, child: LoginAndSignupBtn()),
                  Spacer(),
                ],
              ),
            ],
          ),
          desktop: Row(
            children: [
              Expanded(flex: 5, child: WelcomeImage()),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: defaultPadding,
                    right: defaultPadding * 4,
                    top: defaultPadding,
                    bottom: defaultPadding,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: defaultPadding * 2),
                      LoginAndSignupBtn(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
