import 'package:flutter/material.dart';
import '../widgets/circle_trust_illustration.dart';
import '../widgets/kaspot_logo.dart';
import 'register_screen.dart';
import 'sign_in_screen.dart';

/// Visually engaging initial screen introducing KaSpot prior to authentication.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isSmallScreen ? 16 : 28,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Official Brand Logo & Tagline
                  const KaSpotLogo(
                    fontSize: 38,
                    showTagline: true,
                    tagline: 'Stay connected. Wherever life takes you.',
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 32),

                  // 2. Custom Trust & Circle Vector Illustration
                  CircleTrustIllustration(
                    height: isSmallScreen ? 160 : 190,
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 32),

                  // 3. Welcoming Headline & Value Proposition
                  const Text(
                    'Keep your circle close, on your terms.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Share your live coordinates with loved ones only when you choose. Built with mutual consent and battery-smart movement updates.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),


                  SizedBox(height: isSmallScreen ? 24 : 36),

                  // 5. Primary Action: "Get Started" (leads to Register)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1E60AA),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 6. Secondary Action: "I Already Have an Account" (leads to Sign In)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignInScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E60AA),
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'I Already Have an Account',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
