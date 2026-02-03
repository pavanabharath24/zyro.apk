import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pepper : AppColors.saltWhite,
      body: Stack(
        children: [
          // Background Image Section
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                      "https://lh3.googleusercontent.com/aida-public/AB6AXuD9A6YpaTvIrxnpHZlh8P2zX3FI04zYks2_xraFlF-pPKdT37xHCCfq19EX39Y0_mRZLiwiyQf3tZtawBp8pCWoJflTnPkPVHpuxDcms835Ke97oSToQexlQqgXLpQ0QRWMX7gZyjn_xMI09Gvi0CkbXk_Yg3TNlt4U23X-zdo7agCX-vCEeZEzah64XIYN6Jh58Jx9jOg4NGZhpkc_urd52Y4XnqOLnjHgoNOgV_DtBy3uDYAeb51X9g7EauVgZEyYHPYn_tVE9IQ"),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      Colors.grey,
                      BlendMode
                          .saturation), // grayscale contrast-125 equivalent-ish
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isDark ? AppColors.pepper : AppColors.saltWhite)
                          .withValues(alpha: 0.0),
                      (isDark ? AppColors.pepper : AppColors.saltWhite)
                          .withValues(alpha: 0.4),
                      (isDark ? AppColors.pepper : AppColors.saltWhite),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // HabitFlow Label
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.pepper.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: AppColors.saltWhite.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.monitor_heart_outlined,
                        color: AppColors.saltWhite, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'ZYRO',
                      style: TextStyle(
                        color: AppColors.saltWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? AppColors.saltWhite : AppColors.pepper,
                          height: 1.1,
                        ),
                        children: [
                          const TextSpan(text: 'Master Your \n'),
                          TextSpan(
                            text: 'Daily Routine',
                            style: TextStyle(
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: isDark
                                      ? [
                                          AppColors.saltWhite,
                                          AppColors.spLight,
                                          AppColors.spMedium
                                        ]
                                      : [
                                          AppColors.pepper,
                                          AppColors.spMedium,
                                          AppColors.spLight
                                        ],
                                ).createShader(
                                    const Rect.fromLTWH(0, 0, 200, 70)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Track habits, build streaks, and achieve your goals with precision.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.spMedium,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Buttons
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? AppColors.saltWhite : AppColors.pepper,
                        foregroundColor:
                            isDark ? AppColors.pepper : AppColors.saltWhite,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        shadowColor: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.15),
                      ),
                      child: const Text('Create Free Account',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.go('/home'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? AppColors.saltWhite : AppColors.pepper,
                        side: const BorderSide(
                            color: AppColors.spMedium, width: 2),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Log In',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),

                    const SizedBox(height: 32),

                    // Social Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Expanded(
                            child: Divider(color: AppColors.spLight)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR CONTINUE WITH',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: AppColors.spMedium,
                            ),
                          ),
                        ),
                        const Expanded(
                            child: Divider(color: AppColors.spLight)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialButton(Icons.phone_iphone, isDark),
                        const SizedBox(width: 16),
                        _socialButton(Icons.language,
                            isDark), // Using language as proxy for Globe/Web
                        const SizedBox(width: 16),
                        _socialButton(Icons.mail, isDark),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          'By continuing, you agree to our ',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.spMedium),
                        ),
                        Text(
                          'Terms',
                          style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.saltWhite
                                  : AppColors.pepper,
                              decoration: TextDecoration.underline),
                        ),
                        Text(
                          ' & ',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.spMedium),
                        ),
                        Text(
                          'Privacy Policy',
                          style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.saltWhite
                                  : AppColors.pepper,
                              decoration: TextDecoration.underline),
                        ),
                        Text(
                          '.',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.spMedium),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialButton(IconData icon, bool isDark) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.spMedium),
      ),
      child: Icon(icon,
          color: isDark ? AppColors.saltWhite : AppColors.pepper, size: 24),
    );
  }
}
