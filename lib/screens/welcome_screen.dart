import 'package:flutter/material.dart';
import '../widgets/circle_trust_illustration.dart';
import '../widgets/kaspot_logo.dart';
import 'register_screen.dart';
import 'sign_in_screen.dart';

/// Visually engaging, professional Welcome Screen matching the KaSpot mobile design.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F4FE), // Soft morning sky glow
              Color(0xFFFFFFFF), // Radiant white center
              Color(0xFFF1F9FE), // Soft ambient bottom wave
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: isSmallScreen ? 12 : 20,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Hero 3D Perspective Globe & KaSpot Location Beacon Illustration
                    CircleTrustIllustration(
                      height: isSmallScreen ? 180 : 230,
                    ),

                    SizedBox(height: isSmallScreen ? 10 : 16),

                    // 2. Official Brand Logo & Tagline
                    KaSpotLogo(
                      fontSize: isSmallScreen ? 34 : 40,
                      showTagline: true,
                      tagline: 'Stay connected. Wherever life takes you.',
                      crossAxisAlignment: CrossAxisAlignment.center,
                    ),

                    SizedBox(height: isSmallScreen ? 16 : 24),

                    // 3. Welcoming Headline & Value Proposition
                    Text(
                      'Keep your circle close,\non your terms.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 22 : 25,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                        height: 1.22,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 4. Truthful Value Description
                    const Text(
                      'Share your live coordinates with loved ones only when you choose. No public feeds, no tracking without mutual consent.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 22 : 30),

                    // 5. Primary Action: "Get Started →" (Gradient Pill Button)
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF005ED6),
                            Color(0xFF0288F5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0062E0).withValues(alpha: 0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 6. Secondary Action: "I Already Have an Account" (Outlined Pill Button)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignInScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0066EE),
                          side: const BorderSide(color: Color(0xFF0066EE), width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'I Already Have an Account',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 16 : 22),

                    // 7. Privacy Reassurance Footer
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_rounded,
                          size: 15,
                          color: Color(0xFF0066EE),
                        ),
                        SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            'Your location. Your choice. Share only with people you trust.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
