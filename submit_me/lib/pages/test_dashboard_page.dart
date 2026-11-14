import 'package:flutter/material.dart';
import 'package:submit_me/services/supabase_service.dart';

/// A simple temporary dashboard used in Phase 2 to verify:
/// 1. Successful Authentication (Sign Up & Sign In).
/// 2. User data retrieval (UUID, Email, Full Name).
/// 3. Session Persistence (refreshing browser tab keeps session).
/// 4. Logout functionality.
///
/// NOTE: In Phase 4, this will be replaced with the full persistent
/// Bottom Navigation Bar (Home, My Assets, Public Assets, Profile Drawer).
class TestDashboardPage extends StatelessWidget {
  const TestDashboardPage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await SupabaseService.signOut();
    if (context.mounted) {
      // Return to the initial landing screen
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = SupabaseService.currentUserName;
    final userEmail = SupabaseService.currentUserEmail ?? 'No email';
    final userId = SupabaseService.currentUserId ?? 'No UUID';

    return Scaffold(
      appBar: AppBar(
        title: const Text('SubmitME — Phase 2 Auth Test'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              color: Colors.white,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: Color(0xFF565B61),
                      child: Icon(Icons.person, size: 42, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome, $userName!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userEmail,
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Supabase Auth Status:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '✓ Authenticated Session Active',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            'User UUID:\n$userId',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Phase 2 Authentication is working!\nTry refreshing your Chrome tab to verify session persistence, or tap below to test logout.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Log out'),
                        onPressed: () => _handleLogout(context),
                      ),
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
