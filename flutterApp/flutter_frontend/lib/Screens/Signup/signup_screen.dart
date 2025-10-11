import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/responsive.dart';
import '../../components/background.dart';
import 'components/sign_up_top_image.dart';
import 'components/signup_form.dart';
import 'auth/auth_service.dart';
import '../Login/login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  Future<void> onRegister() async {
    final authService = AuthService();
    try {
      final token = await authService.register(
        usernameController.text,
        emailController.text,
        passwordController.text,
        confirmPasswordController.text,
      );

      if (token != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Zarejestrowano!")));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      String errorMessage = "Błąd rejestrowania";
      if (e is Map<String, dynamic>) {
        final passwordErrors = e['password']?.join("\n") ?? "";
        final password2Errors = e['password2']?.join("\n") ?? "";
        errorMessage = [
          passwordErrors,
          password2Errors,
        ].where((msg) => msg.isNotEmpty).join("\n");
      } else {
        errorMessage = e.toString();
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      appBar: null,
      child: SingleChildScrollView(
        child: Responsive(
          mobile: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SignUpScreenTopImage(),
              const SizedBox(height: defaultPadding * 2),
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: defaultPadding),
                  child: Text(
                    "Twoje dane",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: defaultPadding * 2),
              Row(
                children: [
                  const Spacer(),
                  Expanded(
                    flex: 8,
                    child: SignUpForm(
                      usernameController: usernameController,
                      emailController: emailController,
                      passwordController: passwordController,
                      confirmPasswordController: confirmPasswordController,
                      onRegister: onRegister,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ),

          desktop: Row(
            children: [
              const Expanded(flex: 4, child: SignUpScreenTopImage()),
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: defaultPadding,
                    right: defaultPadding * 4,
                    top: defaultPadding,
                    bottom: defaultPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: defaultPadding * 2),
                      const Text(
                        "Twoje dane",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: defaultPadding),
                      SignUpForm(
                        usernameController: usernameController,
                        emailController: emailController,
                        passwordController: passwordController,
                        confirmPasswordController: confirmPasswordController,
                        onRegister: onRegister,
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
