import 'package:flutter/material.dart';

import 'package:pollutionmonitor/auth/login_view.dart';
import 'package:pollutionmonitor/auth/signup_screen.dart';
import 'package:pollutionmonitor/common/color_extension.dart';
import 'package:pollutionmonitor/common_widget/round_button.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: media.height, // Ensure the container takes full screen height
        width: media.width, // Ensure the container takes full screen width
        color: const Color.fromARGB(
            255, 36, 36, 36), // Set a dark background color
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: media.width * 0.5), // Adjust spacing

              SizedBox(
                height: media.width * 0.5,
                child: Image.asset(
                  "assets/img/Pollution.png", // Replace with your logo image path
                  fit: BoxFit.contain, // Adjust the fit as needed
                ),
              ),
              SizedBox(height: media.width * 0.05), // Adjust spacing
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: RoundButton(
                  title: "Login",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginView(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: media.width * 0.1), // Adjust spacing
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: RoundButton(
                  title: "Sign up",
                  type: RoundButtonType.textPrimary,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
