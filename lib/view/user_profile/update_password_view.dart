import 'package:flutter/material.dart';

import '../../controller/user_profile/user_profile_facade_interface.dart';
import '../../theme/app_colors.dart';

class UpdatePasswordView extends StatefulWidget {
  const UpdatePasswordView({required this.facade, super.key});

  final IAuthenticationFacade facade;

  @override
  State<UpdatePasswordView> createState() => _UpdatePasswordViewState();
}

class _UpdatePasswordViewState extends State<UpdatePasswordView> {
  late final IAuthenticationFacade facade = widget.facade;
  final password = TextEditingController();
  final confirmation = TextEditingController();

  @override
  void dispose() {
    facade.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose a new password')),
    body: AnimatedBuilder(
      animation: facade,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Secure your next adventure.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'New password',
              errorText: facade.passwordError,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: confirmation,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirm password',
              errorText: facade.confirmationPasswordError,
            ),
          ),
          if (facade.error != null) ...[
            const SizedBox(height: 12),
            Text(
              facade.error!,
              style: const TextStyle(color: AppColors.hibiscus),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton(
            onPressed: facade.isLoading
                ? null
                : () async {
                    final updated = await facade.updatePassword(
                      password.text,
                      confirmation.text,
                    );
                    if (!updated || !context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (_) => false,
                    );
                  },
            child: const Text('Update password'),
          ),
        ],
      ),
    ),
  );
}
