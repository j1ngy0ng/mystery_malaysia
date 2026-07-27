import 'package:flutter/material.dart';

import '../../controllers/collaborative_travel/collaborative_travel_controller.dart';
import '../../models/collaborative_travel/mission_participant.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/status_pill.dart';

class SharedMissionView extends StatefulWidget {
  const SharedMissionView({super.key});

  @override
  State<SharedMissionView> createState() => _SharedMissionViewState();
}

class _SharedMissionViewState extends State<SharedMissionView> {
  final controller = CollaborativeTravelController();
  final invite = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    invite.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shared mission lobby')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.purple, AppColors.straits],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StatusPill(
                      label: 'Waiting for members',
                      icon: Icons.hourglass_top_rounded,
                      color: AppColors.ink,
                      background: AppColors.mango,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Lanterns & Legends',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'The same hidden route, clues and progress will sync for everyone.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Text(
                    'Your travel crew',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showInviteSheet(context),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Invite'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...controller.participants.map(
                (participant) => _ParticipantTile(participant: participant),
              ),
              if (controller.lastInvite.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: StatusPill(
                    label: 'Invitation sent to ${controller.lastInvite}',
                    icon: Icons.mark_email_read_outlined,
                    color: AppColors.green,
                  ),
                ),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.paleTeal,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined, color: AppColors.teal),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Team locations are not shown. Each traveller’s GPS is checked only when they confirm arrival at the hidden destination.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => FilledButton.icon(
              onPressed: controller.toggleReady,
              style: FilledButton.styleFrom(
                backgroundColor: controller.isReady
                    ? AppColors.green
                    : AppColors.teal,
              ),
              icon: Icon(
                controller.isReady
                    ? Icons.check_circle_rounded
                    : Icons.how_to_reg_rounded,
              ),
              label: Text(
                controller.isReady ? 'You are ready!' : 'Mark me as ready',
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInviteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          24,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invite a traveller',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Use a username, email or phone number. Friendship is not required.',
            ),
            const SizedBox(height: 18),
            TextField(
              controller: invite,
              decoration: const InputDecoration(
                labelText: 'Username, email or phone',
                prefixIcon: Icon(Icons.person_search_outlined),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  controller.invite(invite.text);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text('Send invitation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant});

  final MissionParticipant participant;

  @override
  Widget build(BuildContext context) {
    final color = Color(participant.colorValue);
    final (label, icon, statusColor) = switch (participant.state) {
      ParticipantState.ready => (
        'Ready',
        Icons.check_circle_rounded,
        AppColors.green,
      ),
      ParticipantState.waiting => (
        'Waiting',
        Icons.hourglass_top_rounded,
        AppColors.sky,
      ),
      ParticipantState.invited => (
        'Invited',
        Icons.schedule_rounded,
        AppColors.purple,
      ),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .16),
          foregroundColor: color,
          child: Text(
            participant.initials,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        title: Row(
          children: [
            Text(
              participant.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (participant.isHost) ...[
              const SizedBox(width: 7),
              const StatusPill(label: 'Host', color: AppColors.hibiscus),
            ],
          ],
        ),
        trailing: StatusPill(label: label, icon: icon, color: statusColor),
      ),
    );
  }
}
