import 'package:flutter/material.dart';

import '../../controller/app_dependencies.dart';
import '../../controller/collaborative_travel/collaborative_travel_facade_interface.dart';
import '../../model/collaborative_travel/mission_participant.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_pill.dart';
import '../../widgets/malaysia_loading.dart';
import 'shared_mission_view.dart';

class InvitationsView extends StatefulWidget {
  const InvitationsView({required this.facade, super.key});

  final ICollaborativeTravelFacade facade;

  @override
  State<InvitationsView> createState() => _InvitationsViewState();
}

class _InvitationsViewState extends State<InvitationsView> {
  late final ICollaborativeTravelFacade facade;

  @override
  void initState() {
    super.initState();
    facade = widget.facade;
    facade.loadOverview();
  }

  @override
  void dispose() {
    facade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: facade,
    builder: (context, _) => MalaysiaLoadingBlocker(
      loading: facade.isLoading,
      message: 'Checking shared missions...',
      child: RefreshIndicator(
        onRefresh: facade.loadOverview,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          children: [
            const _CrewHero(),
            if (facade.error != null) ...[
              const SizedBox(height: 16),
              Text(
                facade.error!,
                style: const TextStyle(color: AppColors.hibiscus),
              ),
            ],
            const SizedBox(height: 22),
            const SectionHeader(title: 'Your shared missions'),
            const SizedBox(height: 10),
            if (!facade.isLoading && facade.sessions.isEmpty)
              _CrewEmptyState(
                icon: Icons.group_add_rounded,
                title: 'Your crew starts here',
                message:
                    'Generate a mystery, choose shared mission, then invite travellers by email.',
                action: 'Create a shared mission',
                onTap: () => Navigator.pushNamed(context, '/missions/request'),
              )
            else
              ...facade.sessions.map(_sessionCard),
            const SizedBox(height: 26),
            const SectionHeader(title: 'Mission invitations'),
            const SizedBox(height: 10),
            if (!facade.isLoading && facade.invitations.isEmpty)
              const _CrewEmptyState(
                icon: Icons.mark_email_read_outlined,
                title: 'You are all caught up',
                message: 'New mission invitations will appear here.',
              )
            else
              ...facade.invitations.map(_invitationCard),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/missions/request'),
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Generate a mission to share'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _sessionCard(SharedMissionSummary mission) {
    final active = mission.status == 'active';
    final color = active ? AppColors.green : AppColors.purple;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openLobby(mission.id),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, color.withValues(alpha: .08)],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(Icons.groups_rounded, color: color, size: 29),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    StatusPill(
                      label: mission.status.replaceAll('_', ' '),
                      icon: active
                          ? Icons.navigation_rounded
                          : Icons.schedule_rounded,
                      color: color,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 17),
            ],
          ),
        ),
      ),
    );
  }

  Widget _invitationCard(SharedInvitation invitation) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusPill(
            label: 'Invitation',
            icon: Icons.mail_outline_rounded,
            color: AppColors.purple,
          ),
          const SizedBox(height: 10),
          Text(invitation.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: facade.isLoading
                      ? null
                      : () => _respond(invitation, false),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: facade.isLoading
                      ? null
                      : () => _respond(invitation, true),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _respond(SharedInvitation invitation, bool accept) async {
    final success = await facade.respond(invitation.id, accept);
    if (!mounted || !success) return;
    if (accept) await _openLobby(invitation.sessionId);
  }

  Future<void> _openLobby(String sessionId) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SharedMissionView(
          facade: AppDependencies.collaborativeTravel(sessionId: sessionId),
        ),
      ),
    );
    facade.loadOverview();
  }
}

class _CrewHero extends StatelessWidget {
  const _CrewHero();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.purple, AppColors.straits],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      boxShadow: [
        BoxShadow(
          color: AppColors.purple.withValues(alpha: .24),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -20,
          top: -26,
          child: Icon(
            Icons.public_rounded,
            color: Colors.white.withValues(alpha: .1),
            size: 130,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CrewFaces(),
            const SizedBox(height: 18),
            Text(
              'Travel together',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Share one mystery, solve the same clues and celebrate every stop together.',
              style: TextStyle(color: Colors.white, height: 1.4),
            ),
            const SizedBox(height: 12),
            const StatusPill(
              label: 'Invite directly by email',
              icon: Icons.alternate_email_rounded,
              color: AppColors.ink,
              background: AppColors.mango,
            ),
          ],
        ),
      ],
    ),
  );
}

class _CrewFaces extends StatelessWidget {
  const _CrewFaces();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 124,
    height: 48,
    child: Stack(
      children: [
        for (var index = 0; index < 3; index++)
          Positioned(
            left: index * 34,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: const [
                  AppColors.hibiscus,
                  AppColors.teal,
                  AppColors.mango,
                ][index],
                foregroundColor: index == 2 ? AppColors.ink : Colors.white,
                child: Icon(
                  const [
                    Icons.face_3_rounded,
                    Icons.face_6_rounded,
                    Icons.face_rounded,
                  ][index],
                  size: 22,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _CrewEmptyState extends StatelessWidget {
  const _CrewEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .88),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      border: Border.all(color: AppColors.purple.withValues(alpha: .12)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: AppColors.purple.withValues(alpha: .12),
          foregroundColor: AppColors.purple,
          child: Icon(icon),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
              if (action != null) ...[
                const SizedBox(height: 7),
                TextButton(onPressed: onTap, child: Text(action!)),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
