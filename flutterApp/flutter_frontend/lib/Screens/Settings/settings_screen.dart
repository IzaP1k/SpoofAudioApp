import 'package:flutter/material.dart';
import 'package:flutter_frontend/Screens/Mainpage/components/appbar.dart';
import '../../components/background.dart';
import '../../constants.dart';
import '../../responsive.dart';

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

  void handleChangePassword() {
    final current = currentPasswordController.text;
    final newPass = newPasswordController.text;
    final confirm = confirmPasswordController.text;

    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nowe hasło i potwierdzenie nie są takie same"),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Hasło zostało zmienione!")));

    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
  }

  void handleLogout() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Wylogowano!")));
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      appBar: CustomAppBar(
        title: 'Audio spoof detector',
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
                  "Potwierdzenie nowego hasła",
                ),
                const SizedBox(height: defaultPadding),
                ElevatedButton(
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
                        "Potwierdzenie nowego hasła",
                      ),
                      const SizedBox(height: defaultPadding),
                      ElevatedButton(
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
}
