import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../controller/user_profile/user_profile_facade_interface.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/section_header.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({required this.facade, super.key});

  final IUserProfileFacade facade;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final IUserProfileFacade facade = widget.facade;
  late final name = TextEditingController(text: facade.profile.name);
  late final username = TextEditingController(text: facade.profile.username);
  final phone = TextEditingController();
  String? gender;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    facade.dispose();
    name.dispose();
    username.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: facade,
      builder: (context, _) {
        final profile = facade.profile;
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
                  onPressed: facade.toggleEditing,
                  icon: Icon(
                    facade.editing ? Icons.close : Icons.edit_outlined,
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
                  GestureDetector(
                    onTap: facade.editing && !facade.isLoading
                        ? _pickAvatar
                        : null,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.white,
                          foregroundImage: profile.avatarUrl == null
                              ? null
                              : NetworkImage(profile.avatarUrl!),
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
                  ),
                  if (!facade.editing) ...[
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
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (facade.editing) ...[
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: username,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                enabled: false,
                initialValue: profile.email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  helperText: 'The email address cannot be edited.',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                enabled: false,
                initialValue: profile.dateOfBirth == null
                    ? 'Not set'
                    : '${profile.dateOfBirth!.day}/${profile.dateOfBirth!.month}/${profile.dateOfBirth!.year}',
                decoration: const InputDecoration(
                  labelText: 'Date of birth',
                  helperText: 'Date of birth is fixed after registration.',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: gender,
                decoration: const InputDecoration(labelText: 'Gender'),
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
                onChanged: (value) => setState(() => gender = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number (optional)',
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: facade.isLoading
                    ? null
                    : () async {
                        final saved = await facade.save(
                          name: name.text,
                          username: username.text,
                          gender: gender,
                          phoneNumber: phone.text,
                        );
                        if (!saved || !context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile updated.')),
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
                    : const Text('Save profile'),
              ),
              const SizedBox(height: 24),
            ],
            if (facade.error != null) ...[
              Text(
                facade.error!,
                style: const TextStyle(color: AppColors.hibiscus),
              ),
              const SizedBox(height: 12),
            ],
            if (!facade.editing) ...[
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
                      icon: Icons.cake_outlined,
                      label: 'Date of birth',
                      value: profile.dateOfBirth == null
                          ? 'Not set'
                          : '${profile.dateOfBirth!.day}/${profile.dateOfBirth!.month}/${profile.dateOfBirth!.year}',
                    ),
                    const Divider(height: 1),
                    _ProfileTile(
                      icon: Icons.badge_outlined,
                      label: 'Gender',
                      value: (profile.gender ?? 'Not set').replaceAll('_', ' '),
                    ),
                    const Divider(height: 1),
                    _ProfileTile(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: profile.phoneNumber ?? 'Not set',
                    ),
                    const Divider(height: 1),
                    const _ProfileTile(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notifications',
                      value: 'Invitations and mission updates',
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () async {
                final signedOut = await facade.signOut();
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
    await facade.load();
    if (!mounted) return;
    name.text = facade.profile.name;
    username.text = facade.profile.username;
    phone.text = facade.profile.phoneNumber ?? '';
    gender = facade.profile.gender;
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (image == null) return;
    final saved = await facade.uploadAvatar(
      await image.readAsBytes(),
      extension: image.name.split('.').last,
    );
    if (!mounted || !saved) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
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
