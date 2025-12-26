import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';
import '../../core/app_theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authControllerProvider.notifier).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Error handling is done via listening to the state in the build method or a listener
      if (mounted) {
         final state = ref.read(authControllerProvider);
         if (state.hasError) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(state.error.toString())),
           );
         }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes to show errors/loading if needed
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Failed: ${next.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(Icons.emoji_food_beverage, size: 80, color: AppTheme.primaryGreen),
                const SizedBox(height: 24),
                Text(
                  "Welcome Back",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sign in to continue your tea journey",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) => value!.isEmpty ? "Please enter email" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) => value!.isEmpty ? "Please enter password" : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isLoading ? null : _handleLogin,
                  child: isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text("LOGIN"),
                ),
                const SizedBox(height: 24),
                
                // Forgot Password link can go here
                
                const Spacer(),
                const Center(
                  child: Text(
                    "Contact Admin for Access",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
