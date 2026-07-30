import 'package:flutter/material.dart';

import '../../controller/app_dependencies.dart';
import '../../controller/collaborative_travel/collaborative_travel_facade_interface.dart';
import '../../model/collaborative_travel/mission_participant.dart';
import '../../theme/app_colors.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_pill.dart';
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
    builder: (context, _) => RefreshIndicator(
      onRefresh: facade.loadOverview,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
          Text(
            'Travel together',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 5),
          Text(
            'Invite people directly by email. No friend list is needed.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (facade.isLoading) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
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
            const Text('No shared missions yet.')
          else
            ...facade.sessions.map(_sessionCard),
          const SizedBox(height: 26),
          const SectionHeader(title: 'Mission invitations'),
          const SizedBox(height: 10),
          if (!facade.isLoading && facade.invitations.isEmpty)
            const Text('No pending invitations.')
          else
            ...facade.invitations.map(_invitationCard),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/missions/request'),
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('Generate a mission to share'),
          ),
        ],
      ),
    ),
  );

  Widget _sessionCard(SharedMissionSummary mission) => Card(
    color: AppColors.paleTeal,
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: const Icon(Icons.groups_rounded, color: AppColors.teal),
      title: Text(mission.title),
      subtitle: Text(mission.status.replaceAll('_', ' ')),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => _openLobby(mission.id),
    ),
  );

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
