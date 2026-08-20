import 'package:flutter/material.dart';

import '../../controller/user_profile/user_profile_facade_interface.dart';
import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_logo.dart';

class SignInView extends StatefulWidget {
  const SignInView({required this.facade, super.key});

  final IAuthenticationFacade facade;

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  late final IAuthenticationFacade facade = widget.facade;
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    facade.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: AnimatedBuilder(
            animation: facade,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppLogo(compact: true),
                  const SizedBox(height: 34),
                  Text(
                    'Selamat datang!',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in and continue your Malaysian mystery trail.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: facade.validateEmail,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.mail_outline_rounded),
                      errorText: facade.emailError,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: password,
                    obscureText: facade.obscurePassword,
                    onChanged: facade.validateSignInPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: facade.togglePasswordVisibility,
                        icon: Icon(
                          facade.obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      errorText: facade.passwordError,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showResetSheet(context),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  if (facade.error != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.paleHibiscus,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Text(
                        facade.error!,
                        style: const TextStyle(
                          color: AppColors.hibiscus,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: facade.isLoading || !facade.canSignIn
                          ? null
                          : () async {
                              final signedIn = await facade.signIn(
                                email.text,
                                password.text,
                              );
                              if (signedIn && context.mounted) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/home',
                                );
                              }
                            },
                      child: facade.isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign in'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'New explorer?',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/auth/register'),
                      child: const Text('Create an account'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showResetSheet(BuildContext context) {
    final resetEmail = TextEditingController(text: email.text);
    facade.validateResetEmail(resetEmail.text);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => AnimatedBuilder(
        animation: facade,
        builder: (sheetContext, _) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reset your password',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('We will send a secure reset link to your email.'),
              const SizedBox(height: 20),
              TextField(
                controller: resetEmail,
                keyboardType: TextInputType.emailAddress,
                onChanged: facade.validateResetEmail,
                decoration: InputDecoration(
                  labelText: 'Registered email',
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                  errorText: facade.resetEmailError,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: facade.isLoading || !facade.canSendPasswordReset
                      ? null
                      : () async {
                          final sent = await facade.sendPasswordReset(
                            resetEmail.text,
                          );
                          if (!sent || !sheetContext.mounted) return;
                          Navigator.pop(sheetContext);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password reset email sent.'),
                            ),
                          );
                        },
                  child: facade.isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send reset link'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
