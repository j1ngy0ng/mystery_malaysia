import 'dart:async';

import 'package:flutter/material.dart';

import '../../controller/app_dependencies.dart';
import '../../controller/collaborative_travel/collaborative_travel_facade_interface.dart';
import '../../model/collaborative_travel/mission_participant.dart';
import '../active_mission/active_mission_view.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/malaysia_loading.dart';

class SharedMissionView extends StatefulWidget {
  const SharedMissionView({required this.facade, super.key});

  final ICollaborativeTravelFacade facade;

  @override
  State<SharedMissionView> createState() => _SharedMissionViewState();
}

class _SharedMissionViewState extends State<SharedMissionView> {
  late final ICollaborativeTravelFacade facade;
  final invite = TextEditingController();
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    facade = widget.facade;
    facade.loadLobby();
    refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!facade.isLoading && facade.sessionId != null) {
        facade.loadLobby();
      }
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    facade.dispose();
    invite.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: facade,
    builder: (context, _) => MalaysiaLoadingBlocker(
      loading: facade.isLoading,
      message: 'Gathering your crew...',
      child: Scaffold(
        appBar: AppBar(title: const Text('Shared mission lobby')),
        body: AnimatedBuilder(
          animation: facade,
          builder: (context, _) {
            if (facade.sessionId == null) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  Text('Generate a mission first, then choose to share it.'),
                  SizedBox(height: 20),
                  Text(
                    'Team locations are not shown. Each traveller’s GPS is checked only when they verify arrival at the hidden destination.',
                  ),
                ],
              );
            }
            return RefreshIndicator(
              onRefresh: facade.loadLobby,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 130),
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
                        StatusPill(
                          label: facade.status.replaceAll('_', ' '),
                          icon: Icons.groups_rounded,
                          color: AppColors.ink,
                          background: AppColors.mango,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          facade.title,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'The same hidden route, clues and progress are synchronised for accepted members.',
                          style: TextStyle(color: Colors.white70, height: 1.4),
                        ),
                      ],
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Your travel crew',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (facade.isHost && facade.status == 'waiting')
                        TextButton.icon(
                          onPressed: () => _showInviteSheet(context),
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Invite'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (facade.isLoading && facade.participants.isEmpty)
                    const Center(
                      child: MalaysiaLoading(message: 'Gathering your crew...'),
                    )
                  else
                    ...facade.participants.map(
                      (participant) => _ParticipantTile(
                        participant: participant,
                        canRemove:
                            facade.isHost &&
                            const [
                              'waiting',
                              'active',
                              'paused',
                            ].contains(facade.status) &&
                            !participant.isHost,
                        onRemove: () => _confirmRemove(participant),
                      ),
                    ),
                  if (facade.message != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              facade.message!,
                              style: const TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
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
                            'Team locations are not shown. Each traveller’s GPS is checked only when they verify arrival at the hidden destination.',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!facade.isHost &&
                      const [
                        'waiting',
                        'active',
                        'paused',
                      ].contains(facade.status)) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: facade.isLoading ? null : _confirmLeave,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Quit shared mission'),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: facade.sessionId == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                  child: AnimatedBuilder(
                    animation: facade,
                    builder: (context, _) {
                      if (facade.status == 'active' ||
                          facade.status == 'paused') {
                        return FilledButton.icon(
                          onPressed: _openMission,
                          icon: const Icon(Icons.explore_rounded),
                          label: const Text('Open shared mission'),
                        );
                      }
                      if (facade.status != 'waiting') {
                        return const SizedBox.shrink();
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: facade.isLoading
                                  ? null
                                  : facade.toggleReady,
                              icon: Icon(
                                facade.isReady
                                    ? Icons.check_circle_rounded
                                    : Icons.how_to_reg_rounded,
                              ),
                              label: Text(
                                facade.isReady ? 'Ready' : 'Mark ready',
                              ),
                            ),
                          ),
                          if (facade.isHost) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: facade.isLoading
                                    ? null
                                    : facade.start,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Start'),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
      ),
    ),
  );

  Future<void> _openMission() async {
    try {
      final launch = await facade.loadCurrentMission();
      if (!mounted || launch == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ActiveMissionView(
            facade: AppDependencies.activeMission(launch: launch),
          ),
        ),
      );
      facade.loadLobby();
    } catch (_) {}
  }

  void _showInviteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          24,
          22,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
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
              'Enter an email address. Registered travellers receive an in-app invitation; otherwise an account invitation is emailed automatically.',
            ),
            const SizedBox(height: 18),
            TextField(
              controller: invite,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final sent = await facade.invite(invite.text);
                  if (!sent || !sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  if (context.mounted && facade.message != null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(facade.message!)));
                  }
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

  void _confirmRemove(MissionParticipant participant) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${participant.name}?'),
        content: const Text(
          'They will immediately lose access to this shared mission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final removed = await facade.remove(participant.userId);
              if (removed && context.mounted) Navigator.pop(context);
            },
            child: const Text('Remove member'),
          ),
        ],
      ),
    );
  }

  void _confirmLeave() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quit this shared mission?'),
        content: const Text(
          'You will leave the travel crew and lose access to its shared progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Stay with crew'),
          ),
          FilledButton(
            onPressed: () async {
              final left = await facade.leave();
              if (!left || !dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('Quit mission'),
          ),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.participant,
    required this.canRemove,
    required this.onRemove,
  });

  final MissionParticipant participant;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final color = Color(participant.colorValue);
    final ready = participant.state == ParticipantState.ready;
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
            Expanded(
              child: Text(
                participant.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (participant.isHost) ...[
              const SizedBox(width: 7),
              const StatusPill(label: 'Host', color: AppColors.hibiscus),
            ],
          ],
        ),
        subtitle: Text(ready ? 'Ready' : 'Waiting'),
        trailing: canRemove
            ? IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.person_remove_outlined),
              )
            : Icon(
                ready ? Icons.check_circle_rounded : Icons.schedule_rounded,
                color: ready ? AppColors.green : AppColors.purple,
              ),
      ),
    );
  }
}
