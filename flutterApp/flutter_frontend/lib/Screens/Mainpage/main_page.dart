import 'package:flutter/material.dart';
import 'package:flutter_frontend/Screens/Mainpage/components/mainfunction.dart';
import 'package:flutter_frontend/Screens/Mainpage/components/mainpage_image.dart';
import 'package:flutter_frontend/Screens/Settings/settings_screen.dart';
import 'package:flutter_frontend/components/background.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/responsive.dart';
import 'components/appbar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Background(
      appBar: CustomAppBar(
        title: 'Detektor oszustw audio',
        backgroundColor: kPrimaryLightColor,
        detailsColor: kPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          // IconButton(icon: const Icon(Icons.account_circle), onPressed: () {}),
        ],
      ),
      child: const SingleChildScrollView(
        child: Responsive(
          mobile: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              MainpageImage(),
              Row(
                children: [
                  Spacer(),
                  Expanded(flex: 8, child: MainFunction()),
                  Spacer(),
                ],
              ),
            ],
          ),
          desktop: Row(
            children: [
              Expanded(flex: 5, child: MainpageImage()),
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Sprawdź nagranie",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      SizedBox(height: defaultPadding),
                      MainFunction(),
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
