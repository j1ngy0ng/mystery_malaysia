import 'package:flutter/material.dart';

import '../../controllers/user_profile/authentication_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final controller = AuthenticationController();
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    username.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.paleMango,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Text('🌺', style: TextStyle(fontSize: 42)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Your first stamp is waiting.',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: username,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: password,
                obscureText: controller.obscurePassword,
                onSubmitted: (_) => _register(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: controller.togglePasswordVisibility,
                    icon: Icon(
                      controller.obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use at least 8 characters.',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
              ),
              if (controller.error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.paleHibiscus,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    controller.error!,
                    style: const TextStyle(
                      color: AppColors.hibiscus,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: controller.isLoading ? null : _register,
                child: controller.isLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create my account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (controller.isLoading) return;
    final result = await controller.register(
      username: username.text,
      email: email.text,
      password: password.text,
    );
    if (!mounted || result == null) return;

    if (result == RegistrationResult.signedIn) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account created. Confirm your email, then sign in.'),
      ),
    );
    Navigator.pushReplacementNamed(context, '/auth/sign-in');
  }
}
