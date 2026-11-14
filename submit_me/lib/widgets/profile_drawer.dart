import 'package:flutter/material.dart';
import 'package:submit_me/services/supabase_service.dart';

/// A right-side Drawer displaying the authenticated student's profile details
/// and the option to log out.
class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    // 1. Close the drawer first
    Navigator.of(context).pop();

    // 2. Sign out from Supabase
    await SupabaseService.signOut();

    // 3. Navigate back to the landing screen and clear the navigation stack
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = SupabaseService.currentUserName;
    final userEmail = SupabaseService.currentUserEmail ?? 'No email';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header with avatar and basic student info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 70, 136, 216),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 37,
                      backgroundColor: const Color(0xFF565B61),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Student Member',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Profile info section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.badge_outlined, color: Color(0xFF565B61)),
                    title: const Text('Full Name', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    subtitle: Text(
                      userName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.email_outlined, color: Color(0xFF565B61)),
                    title: const Text('Email Address', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    subtitle: Text(
                      userEmail,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),

            const Spacer(),

            // Logout Button at the bottom
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _handleLogout(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
