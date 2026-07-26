import 'package:flutter/material.dart';

import '../../controllers/user_profile/user_profile_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/section_header.dart';
import '../widgets/status_pill.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final controller = UserProfileController();
  late final name = TextEditingController(text: controller.profile.name);
  late final username = TextEditingController(
    text: controller.profile.username,
  );

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    controller.dispose();
    name.dispose();
    username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final profile = controller.profile;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          children: [
            Row(
              children: [
                Text(
                  'Your profile',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: controller.toggleEditing,
                  icon: Icon(
                    controller.editing ? Icons.close : Icons.edit_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.straits, AppColors.teal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.white,
                        child: Text('🌺', style: TextStyle(fontSize: 46)),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: AppColors.mango,
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: AppColors.ink,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile.name,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  Text(
                    profile.username,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  StatusPill(
                    label: 'Level ${profile.level} • ${profile.xp} XP',
                    color: AppColors.ink,
                    background: AppColors.mango,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (controller.editing) ...[
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: username,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: controller.isLoading
                    ? null
                    : () async {
                        final saved = await controller.save(
                          name: name.text,
                          username: username.text,
                        );
                        if (!saved || !context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile updated.')),
                        );
                      },
                child: controller.isLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save profile'),
              ),
              const SizedBox(height: 24),
            ],
            if (controller.error != null) ...[
              Text(
                controller.error!,
                style: const TextStyle(color: AppColors.hibiscus),
              ),
              const SizedBox(height: 12),
            ],
            const SectionHeader(title: 'Explorer details'),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  _ProfileTile(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email',
                    value: profile.email,
                  ),
                  const Divider(height: 1),
                  _ProfileTile(
                    icon: Icons.location_on_outlined,
                    label: 'Home state',
                    value: profile.homeState,
                  ),
                  const Divider(height: 1),
                  const _ProfileTile(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    value: 'Mission reminders on',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () async {
                final signedOut = await controller.signOut();
                if (!signedOut || !context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadProfile() async {
    await controller.load();
    if (!mounted) return;
    name.text = controller.profile.name;
    username.text = controller.profile.username;
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.teal),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
