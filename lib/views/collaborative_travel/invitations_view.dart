import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/section_header.dart';
import '../widgets/status_pill.dart';

class InvitationsView extends StatelessWidget {
  const InvitationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: [
        Text(
          'Travel together',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 5),
        Text(
          'Invite people directly. No friend list needed.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 22),
        Card(
          color: AppColors.paleTeal,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            onTap: () => Navigator.pushNamed(context, '/shared/demo'),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text('🧑‍🤝‍🧑', style: TextStyle(fontSize: 46)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lanterns & Legends',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        const StatusPill(
                          label: 'Waiting for members',
                          icon: Icons.hourglass_top_rounded,
                          color: AppColors.purple,
                        ),
                        const SizedBox(height: 7),
                        const Text('3 joined • 1 invitation pending'),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const SectionHeader(title: 'Mission invitations'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.paleHibiscus,
                      child: Text('KU'),
                    ),
                    SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Kumar invited you',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text('2h ago'),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Spice Route Secrets',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                const Text('Saturday • 10:30 AM • 3 hidden stops'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/shared/demo'),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/missions/request'),
          icon: const Icon(Icons.group_add_outlined),
          label: const Text('Create a new shared mission'),
        ),
      ],
    );
  }
}
