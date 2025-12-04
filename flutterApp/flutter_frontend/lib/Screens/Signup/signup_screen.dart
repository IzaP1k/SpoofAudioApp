import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/responsive.dart';
import 'package:flutter_frontend/components/background.dart';
import 'package:flutter_frontend/Screens/Signup/components/sign_up_top_image.dart';
import 'package:flutter_frontend/Screens/Signup/components/signup_form.dart';
import 'package:flutter_frontend/Screens/Signup/auth/auth_service.dart';
import 'package:flutter_frontend/Screens/Login/login_screen.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

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
    bool mounted = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: LoadingAnimationWidget.staggeredDotsWave(
            color: const Color(0xFF0C6E2A),
            size: 70,
          ),
        );
      },
    );

    try {
      final token = await authService.register(
        usernameController.text.trim(),
        emailController.text.trim(),
        passwordController.text,
        confirmPasswordController.text,
      );

      if (mounted && Navigator.canPop(context)) Navigator.pop(context);

      if (token != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Zarejestrowano!"),
            backgroundColor: kConfirmationColor,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);

      String errorMessage = "Wystąpił błąd podczas rejestracji.";

      if (e is Map) {
        List<String> msgs = [];

        e.forEach((key, value) {
          if (value is List) {
            msgs.addAll(value.map((v) => v.toString()));
          } else if (value is String) {
            msgs.add(value);
          }
        });

        if (msgs.isNotEmpty) {
          errorMessage = msgs.join("\n");
        }
      } else if (e is String) {
        errorMessage = e;
      } else if (e is Exception) {
        final msg = e.toString().replaceFirst("Exception: ", "");
        if (msg.isNotEmpty) errorMessage = msg;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: kRejectionColor),
      );
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
