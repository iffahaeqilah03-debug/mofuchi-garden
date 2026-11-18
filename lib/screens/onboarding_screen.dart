import '../widgets/mofuchi_gradient_surface.dart';
import 'package:flutter/material.dart';
import '../widgets/mofuchi_background.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MofuchiBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D2430).withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/mofuchi_onboarding.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Text('🪴', style: TextStyle(fontSize: 60)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to Mofuchi Garden',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF2D2430),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Your personal space to track emotions, reflect on your day, and grow. Let's start seeds of calm!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF645A66),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _featureTile(
                icon: Icons.wb_sunny_outlined,
                title: 'Track Your Mood Daily',
                subtitle: 'Select daily weather that represents your soul.',
              ),
              const SizedBox(height: 12),
              _featureTile(
                icon: Icons.edit_note_rounded,
                title: 'Reflect & Journal',
                subtitle: 'Scribble down key moments with tags & pictures.',
              ),
              const SizedBox(height: 12),
              _featureTile(
                icon: Icons.nature_people_outlined,
                title: 'Watch Your Garden Grow',
                subtitle: 'Watch your Mofuchi mascot thrive with emotional insights.',
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C84F4), Color(0xFF6D3AC3)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9C84F4).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: MofuchiGradientSurface(child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: (ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  )).copyWith(backgroundColor: const WidgetStatePropertyAll<Color>(Colors.transparent), shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent), surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent)),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureTile({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EBFF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFF8B5CF6), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF2D2430),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF645A66),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}