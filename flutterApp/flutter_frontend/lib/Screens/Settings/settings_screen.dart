import 'package:flutter/material.dart';
import 'package:flutter_frontend/Screens/Mainpage/components/appbar.dart';
import 'package:flutter_frontend/Screens/Welcome/welcome_screen.dart';
import 'package:flutter_frontend/components/background.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/responsive.dart';
import 'package:flutter_frontend/Screens/Login/auth/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final t = await _authService.getToken();
    setState(() {
      _token = t;
    });
  }

  Future<void> handleChangePassword() async {
    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Zaloguj się ponownie"),
          backgroundColor: kRejectionColor,
        ),
      );
      return;
    }

    final current = currentPasswordController.text;
    final newPass = newPasswordController.text;
    final confirm = confirmPasswordController.text;

    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Podane hasła nie są takie same"),
          backgroundColor: kRejectionColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final errorMessage = await _authService.changePassword(
      token: _token!,
      oldPassword: current,
      newPassword: newPass,
      confirmPassword: confirm,
    );

    setState(() {
      _isLoading = false;
    });

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Hasło zostało zmienione!"),
          backgroundColor: kConfirmationColor,
        ),
      );
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: kRejectionColor),
      );
    }
  }

  Future<void> handleLogout() async {
    await _authService.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Pomyślnie wylogowano się"),
        backgroundColor: kConfirmationColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_token == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    return Background(
      appBar: CustomAppBar(
        title: 'Ustawienia',
        backgroundColor: kPrimaryLightColor,
        detailsColor: kPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: kPrimaryColor),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Responsive(
          mobile: Padding(
            padding: const EdgeInsets.all(defaultPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Zmiana hasła",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: defaultPadding),
                _buildPasswordField(
                  currentPasswordController,
                  "Aktualne hasło",
                ),
                const SizedBox(height: defaultPadding),
                _buildPasswordField(newPasswordController, "Nowe hasło"),
                const SizedBox(height: defaultPadding),
                _buildPasswordField(
                  confirmPasswordController,
                  "Potwierdź hasło",
                ),
                const SizedBox(height: defaultPadding),
                _isLoading
                    ? const CircularProgressIndicator(color: kPrimaryColor)
                    : ElevatedButton(
                        onPressed: handleChangePassword,
                        child: const Text(
                          "Zmień hasło",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                const SizedBox(height: defaultPadding),
                ElevatedButton(
                  onPressed: handleLogout,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    "Wyloguj się",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          desktop: Row(
            children: [
              const Spacer(),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding * 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Zmiana hasła",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: kPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: defaultPadding * 2),
                      _buildPasswordField(
                        currentPasswordController,
                        "Aktualne hasło",
                      ),
                      const SizedBox(height: defaultPadding),
                      _buildPasswordField(newPasswordController, "Nowe hasło"),
                      const SizedBox(height: defaultPadding),
                      _buildPasswordField(
                        confirmPasswordController,
                        "Potwierdź hasło",
                      ),
                      const SizedBox(height: defaultPadding),
                      _isLoading
                          ? const CircularProgressIndicator(
                              color: kPrimaryColor,
                            )
                          : ElevatedButton(
                              onPressed: handleChangePassword,
                              child: const Text(
                                "Zmień hasło",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                      const SizedBox(height: defaultPadding),
                      ElevatedButton(
                        onPressed: handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text(
                          "Wyloguj się",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildPasswordField(TextEditingController controller, String hint) {
  return TextFormField(
    controller: controller,
    obscureText: true,
    cursorColor: kPrimaryColor,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Padding(
        padding: EdgeInsets.all(defaultPadding),
        child: Icon(Icons.lock),
      ),
      filled: true,
      fillColor: kPrimaryLightColor,
      contentPadding: const EdgeInsets.symmetric(
        vertical: defaultPadding * 1.5,
        horizontal: defaultPadding,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: kPrimaryColor, width: 2),
      ),
    ),
  );
}
