import 'package:flutter/material.dart';

import '../../controller/user_profile/user_profile_facade_interface.dart';
import '../../model/user_profile/registration_result.dart';
import '../app_colors.dart';
import '../app_spacing.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({required this.facade, super.key});

  final IAuthenticationFacade facade;

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final IAuthenticationFacade facade = widget.facade;
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmationPassword = TextEditingController();
  String gender = '';
  DateTime? dateOfBirth;

  @override
  void dispose() {
    facade.dispose();
    username.dispose();
    email.dispose();
    password.dispose();
    confirmationPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: facade,
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
                        'Your first state mission badge is waiting.',
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
                onChanged: facade.validateUsername,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  errorText: facade.usernameError,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: facade.validateEmail,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                  errorText: facade.emailError,
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: gender.isEmpty ? null : gender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  errorText: facade.genderError,
                ),
                items: const [
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(
                    value: 'non_binary',
                    child: Text('Non-binary'),
                  ),
                  DropdownMenuItem(
                    value: 'prefer_not_to_say',
                    child: Text('Prefer not to say'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => gender = value ?? '');
                  facade.validateGender(gender);
                },
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                onTap: _pickDateOfBirth,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date of birth',
                    prefixIcon: const Icon(Icons.cake_outlined),
                    errorText: facade.dateOfBirthError,
                  ),
                  child: Text(
                    dateOfBirth == null
                        ? 'Select date'
                        : '${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: password,
                obscureText: facade.obscurePassword,
                onChanged: (value) {
                  facade.validateRegistrationPassword(value);
                  facade.validatePasswordConfirmation(
                    value,
                    confirmationPassword.text,
                  );
                },
                onSubmitted: (_) => _register(),
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
              const SizedBox(height: 14),
              TextField(
                controller: confirmationPassword,
                obscureText: facade.obscurePassword,
                onChanged: (value) =>
                    facade.validatePasswordConfirmation(password.text, value),
                onSubmitted: (_) => _register(),
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  errorText: facade.confirmationPasswordError,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use 8+ characters with uppercase, lowercase, number and symbol.',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
              ),
              if (facade.error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.paleHibiscus,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    facade.error!,
                    style: const TextStyle(
                      color: AppColors.hibiscus,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: facade.isLoading || !facade.canRegister
                    ? null
                    : _register,
                child: facade.isLoading
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
    if (facade.isLoading) return;
    final result = await facade.register(
      username: username.text,
      email: email.text,
      password: password.text,
      confirmationPassword: confirmationPassword.text,
      gender: gender,
      dateOfBirth: dateOfBirth,
    );
    if (!mounted || result == null) return;

    if (result == RegistrationResult.signedIn) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.mark_email_read_rounded,
          color: AppColors.teal,
          size: 42,
        ),
        title: const Text('Registration successful'),
        content: const Text(
          'Click the verification link sent to your email, then return to sign in.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Go to sign in'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/auth/sign-in');
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 120),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      initialDate: dateOfBirth ?? DateTime(now.year - 18),
    );
    if (selected != null) setState(() => dateOfBirth = selected);
    facade.validateDateOfBirth(dateOfBirth);
  }
}
