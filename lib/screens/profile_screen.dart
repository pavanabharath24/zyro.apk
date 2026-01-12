import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../widgets/bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : AppColors.pageBgLight;
    final textColor = isDark ? AppColors.primary : AppColors.pepper;
    final subTextColor = isDark ? AppColors.tertiary : AppColors.ash;
    final surfaceColor = isDark ? AppColors.surface : Colors.grey[100]!;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.2);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).padding.top + 16),
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('My Profile',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: textColor)),
                              Row(
                                children: [
                                  _iconButton(
                                      Icons.notifications_outlined,
                                      () {},
                                      isDark,
                                      textColor,
                                      surfaceColor,
                                      borderColor),
                                  const SizedBox(width: 8),
                                  _iconButton(
                                      Icons.settings_outlined,
                                      () => context.go('/settings'),
                                      isDark,
                                      textColor,
                                      surfaceColor,
                                      borderColor),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Profile Info
                        Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 112,
                                  height: 112,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: borderColor, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                          color: isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.1)
                                              : Colors.black
                                                  .withValues(alpha: 0.1),
                                          blurRadius: 15,
                                          spreadRadius: 0),
                                    ],
                                    image: const DecorationImage(
                                      image: NetworkImage(
                                          "https://lh3.googleusercontent.com/aida-public/AB6AXuAoYOFnvCr7f7PMYpm-_1Ip9XE2iCM_b_-7ACEqUQcDPOcgXvK6L-whC_WtooqZyOUZcLuBOPytQmQRX-KqW4d-97w9qAHSwuPnSTXYNaA8YCFYQj-pKCaYV4HgWToMlugMGjJQX13DXDAdTipCz_0CxwPB5ssAGc_esKNfiCrf8xa5WOnCho90apQN76gbzfx8OisgkXwDiYz2IY6M-JVfv44z2AYrT5yvnwYs3j0GYS_NVBshYlwt_gXjtK4AV1ixGje3r9J7Ksw"),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: textColor,
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: bgColor, width: 4),
                                  ),
                                  child: Icon(Icons.edit,
                                      size: 16, color: bgColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('Alex',
                                style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified,
                                    size: 16, color: subTextColor),
                                const SizedBox(width: 4),
                                Text('Premium Member',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: subTextColor)),
                              ],
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Sign Out
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 24),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () => context.go('/'),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: borderColor),
                                    color: surfaceColor.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.logout,
                                          color: subTextColor, size: 20),
                                      const SizedBox(width: 8),
                                      Text('Sign Out',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: subTextColor)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text('Version 2.4.0 (Build 1045)',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          subTextColor.withValues(alpha: 0.4))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 120), // Space for nav bar
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavBar(activePath: '/profile'),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onPressed, bool isDark,
      Color textColor, Color surfaceColor, Color borderColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: surfaceColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: textColor, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}
