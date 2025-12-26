import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_config.dart';
import 'core/app_theme.dart';
import 'auth/auth_controller.dart';
import 'auth/login_page.dart';
import 'navigation/bottom_nav.dart';
import 'vip/vip_bottom_nav.dart';
import 'admin/admin_root.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SupabaseConfig.initialize();

  runApp(const ProviderScope(child: TeaVerseApp()));
}

class TeaVerseApp extends StatelessWidget {
  const TeaVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeaVerse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}



// ... (Preceding code remains similar, ensure imports are correct)

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userProfile = ref.watch(userProfileProvider);

    return authState.when(
      data: (state) {
        if (state.session != null) {
          // Session exists, wait for profile loading
          return userProfile.when(
            data: (profile) {
              if (profile == null) {
                // Profile not found (deleted? or glitch), maybe logout?
                // For now, show loading or fallback
                return const Scaffold(body: Center(child: Text("Profile not found. Contact Admin.")));
              }
              
              final role = profile['role'];
              if (role == 'admin') {
                return const AdminDashboardRoot();
              } else {
                return const VipBottomNav();
              }
            },
            loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (e, s) => Scaffold(body: Center(child: Text('Error loading profile: $e'))),
          );
        } else {
          return const LoginPage();
        }
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
