import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/responsive.dart';
import 'package:flutter_frontend/components/background.dart';
import 'components/login_form.dart';
import 'components/login_screen_top_image.dart';
import 'auth/auth_service.dart';
import 'package:flutter_frontend/Screens/Mainpage/main_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final authService = AuthService();
  bool _isCheckingToken = true;

  @override
  void initState() {
    super.initState();
    _checkExistingToken();
  }

  Future<void> _checkExistingToken() async {
    final token = await authService.getToken();
    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      setState(() {
        _isCheckingToken = false;
      });
    }
  }

  Future<void> handleLogin() async {
    final token = await authService.login(
      usernameController.text,
      passwordController.text,
    );
    if (token != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Zalogowano!"),
          backgroundColor: kConfirmationColor,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nieprawidłowa nazwa użytkownika lub hasło."),
          backgroundColor: kRejectionColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingToken) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    return Background(
      appBar: null,
      child: SingleChildScrollView(
        child: Responsive(
          mobile: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const LoginScreenTopImage(),
              Row(
                children: [
                  const Spacer(),
                  Expanded(
                    flex: 8,
                    child: LoginForm(
                      usernameController: usernameController,
                      passwordController: passwordController,
                      onLogin: handleLogin,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ),
          desktop: Row(
            children: [
              const Expanded(flex: 5, child: LoginScreenTopImage()),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: defaultPadding,
                    right: defaultPadding * 4,
                    top: defaultPadding,
                    bottom: defaultPadding,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: defaultPadding * 2),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Twoje dane",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: defaultPadding),
                      LoginForm(
                        usernameController: usernameController,
                        passwordController: passwordController,
                        onLogin: handleLogin,
                      ),
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
