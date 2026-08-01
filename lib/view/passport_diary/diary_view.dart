import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controller/passport_diary/passport_diary_facade_interface.dart';
import '../../model/passport_diary/traveller_progress.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/malaysia_loading.dart';

class DiaryView extends StatefulWidget {
  const DiaryView({required this.facade, super.key, this.sessionId});

  final IPassportDiaryFacade facade;
  final String? sessionId;

  @override
  State<DiaryView> createState() => _DiaryViewState();
}

class _DiaryViewState extends State<DiaryView> {
  late final IPassportDiaryFacade facade;
  final reflection = TextEditingController();
  final title = TextEditingController();
  final content = TextEditingController();
  bool generated = false;
  bool reflectionSubmitted = false;

  @override
  void initState() {
    super.initState();
    facade = widget.facade;
    _load();
  }

  @override
  void dispose() {
    facade.dispose();
    reflection.dispose();
    title.dispose();
    content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Travel diary')),
    body: AnimatedBuilder(
      animation: facade,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.paleHibiscus,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              children: [
                const Text('✍️', style: TextStyle(fontSize: 42)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.sessionId == null
                            ? 'Your memory book'
                            : _isGroup
                            ? 'Create your crew diary'
                            : 'Create a verified memory',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        widget.sessionId == null
                            ? 'Choose an eligible completed mission below.'
                            : _isGroup
                            ? 'Every member contributes before the host confirms one shared AI diary.'
                            : 'Submit your reflection first, then ask AI to shape the diary.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.sessionId == null) ...[
            const SizedBox(height: 24),
            Text(
              'Eligible completed missions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            if (!facade.isLoading && facade.eligibleDiaryMissions.isEmpty)
              const Text(
                'No missions are waiting for a diary. Complete all three verified stops to unlock one.',
              )
            else
              ...facade.eligibleDiaryMissions.map(
                (mission) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(
                      mission.mode == 'collaborative'
                          ? Icons.groups_rounded
                          : Icons.explore_rounded,
                      color: AppColors.teal,
                    ),
                    title: Text(mission.title),
                    subtitle: const Text('Ready for your reflection'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        '/diary',
                        arguments: mission.sessionId,
                      );
                      if (mounted) await facade.load();
                    },
                  ),
                ),
              ),
          ],
          if (widget.sessionId != null && _isGroup) ..._groupDiarySection(),
          if (widget.sessionId != null && !generated) ...[
            if (!_isGroup) ...[
              const SizedBox(height: 20),
              if (!reflectionSubmitted) ...[
                TextField(
                  controller: reflection,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Your travel reflection',
                    hintText:
                        'Share feelings, memorable moments, keywords and what you learned...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: facade.isLoading ? null : _submitReflection,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Submit reflection'),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.paleTeal,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_rounded, color: AppColors.green),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Reflection submitted. You can now generate your AI travel diary.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: facade.isLoading ? null : _generate,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Generate AI travel diary'),
                ),
              ],
            ],
          ],
          if (generated) ...[
            const SizedBox(height: 20),
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Diary title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: content,
              minLines: 8,
              maxLines: 16,
              decoration: const InputDecoration(
                labelText: 'Review and edit your diary',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _copyDiary(title.text, content.text),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy diary for social media'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: facade.isLoading ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save diary'),
            ),
          ],
          if (facade.error != null) ...[
            const SizedBox(height: 12),
            Text(
              facade.error!,
              style: const TextStyle(color: AppColors.hibiscus),
            ),
          ],
          const SizedBox(height: 30),
          Text('Saved memories', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (facade.isLoading && facade.memories.isEmpty)
            const Center(
              child: MalaysiaLoading(message: 'Gathering your memories...'),
            )
          else if (facade.memories.isEmpty)
            const Text('No saved diaries yet.')
          else
            ...facade.memories.map(
              (memory) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: Text(
                    memory.isShared ? '👥' : memory.emoji,
                    style: const TextStyle(fontSize: 30),
                  ),
                  title: Text(memory.title),
                  subtitle: Text(
                    memory.isShared
                        ? 'Shared with your travel crew • ${memory.date}'
                        : memory.date,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(memory.summary),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: () =>
                                _copyDiary(memory.title, memory.summary),
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Copy for social media'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );

  bool get _isGroup {
    if (facade.groupDiaryState != null) return true;
    return facade.eligibleDiaryMissions.any(
      (mission) =>
          mission.sessionId == widget.sessionId &&
          mission.mode == 'collaborative',
    );
  }

  List<Widget> _groupDiarySection() {
    final state = facade.groupDiaryState;
    if (state == null) {
      return const [
        SizedBox(height: 20),
        MalaysiaLoading(message: 'Gathering your crew reflections...'),
      ];
    }
    final viewer = state.viewer;
    return [
      const SizedBox(height: 22),
      Text('Crew reflections', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 6),
      const Text(
        'These reflections are visible only to the accepted members of this completed mission.',
      ),
      const SizedBox(height: 12),
      for (final member in state.members)
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${member.name}${member.isViewer ? ' (You)' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (member.isHost)
                      const Chip(label: Text('Host'))
                    else
                      Icon(
                        member.submitted
                            ? Icons.check_circle_rounded
                            : Icons.schedule_rounded,
                        color: member.submitted
                            ? AppColors.green
                            : AppColors.purple,
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                if (member.submitted)
                  SelectableText(member.reflection!)
                else
                  const Text(
                    'Waiting for this member\'s reflection.',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
              ],
            ),
          ),
        ),
      if (viewer?.submitted != true) ...[
        const SizedBox(height: 8),
        TextField(
          controller: reflection,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Your reflection for the group diary',
            hintText:
                'Share what you felt, learned and enjoyed with the crew...',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: facade.isLoading ? null : _submitReflection,
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: const Text('Submit reflection to crew'),
        ),
      ],
      if (state.diary != null) ...[
        const SizedBox(height: 18),
        _SharedDiaryCard(diary: state.diary!, onCopy: _copyDiary),
      ] else if (state.isHost) ...[
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: state.allSubmitted && !facade.isLoading
              ? _confirmAndGenerateGroupDiary
              : null,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: Text(
            state.allSubmitted
                ? 'Review and generate shared diary'
                : 'Waiting for every reflection',
          ),
        ),
      ] else ...[
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.paleTeal,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Text(
            state.allSubmitted
                ? 'All reflections are ready. Waiting for the host to review and confirm generation.'
                : 'The group diary unlocks after every member submits a reflection.',
          ),
        ),
      ],
    ];
  }

  Future<void> _load() async {
    await facade.load();
    if (!mounted || widget.sessionId == null) return;
    final collaborative = facade.eligibleDiaryMissions.any(
      (mission) =>
          mission.sessionId == widget.sessionId &&
          mission.mode == 'collaborative',
    );
    if (!collaborative) return;
    await facade.loadGroupDiary(widget.sessionId!);
    if (!mounted) return;
    final existing = facade.groupDiaryState?.viewer?.reflection;
    if (existing != null) reflection.text = existing;
  }

  Future<void> _confirmAndGenerateGroupDiary() async {
    final state = facade.groupDiaryState;
    if (state == null || !state.isHost || !state.allSubmitted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm all crew reflections'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Review every contribution below. Once confirmed, one AI diary will be generated and shared with all current members.',
              ),
              const SizedBox(height: 14),
              for (final member in state.members) ...[
                Text(
                  member.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(member.reflection ?? ''),
                const Divider(height: 24),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm and generate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        child: MalaysiaLoading(
          message: 'Weaving every crew reflection into one shared story...',
        ),
      ),
    );
    final message = await facade.generateGroupDiary(widget.sessionId!);
    if (!mounted) return;
    Navigator.pop(context);
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _generate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate AI travel diary?'),
        content: const Text(
          'Gemini will use your submitted reflection and verified destination visits to create an editable diary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        child: MalaysiaLoading(
          message: 'Crafting your verified Malaysian travel story...',
        ),
      ),
    );
    final result = await facade.generateDiary(
      widget.sessionId!,
      reflection.text,
    );
    if (!mounted) return;
    Navigator.pop(context);
    if (result == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
    if (!result.generated && result.content.isEmpty) return;
    setState(() {
      generated = true;
      title.text = result.title;
      content.text = result.content;
    });
  }

  Future<void> _submitReflection() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit this reflection?'),
        content: const Text(
          'Confirm that you are ready to use this reflection for your travel diary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final saved = await facade.submitReflection(
      widget.sessionId!,
      reflection.text,
    );
    if (!mounted || !saved) return;
    if (_isGroup) {
      await facade.loadGroupDiary(widget.sessionId!);
      return;
    }
    setState(() => reflectionSubmitted = true);
  }

  Future<void> _save() async {
    final saved = await facade.saveDiary(
      sessionId: widget.sessionId!,
      title: title.text,
      content: content.text,
    );
    if (!mounted || !saved) return;
    setState(() => generated = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your travel diary has been saved.')),
    );
  }

  Future<void> _copyDiary(String diaryTitle, String diaryContent) async {
    final text = [
      diaryTitle.trim(),
      diaryContent.trim(),
    ].where((part) => part.isNotEmpty).join('\n\n');
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diary copied. Ready to paste!')),
    );
  }
}

class _SharedDiaryCard extends StatelessWidget {
  const _SharedDiaryCard({required this.diary, required this.onCopy});

  final DiaryMemory diary;
  final Future<void> Function(String, String) onCopy;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.paleMango,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.groups_rounded, color: AppColors.hibiscus),
            SizedBox(width: 8),
            Text(
              'Shared crew diary',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(diary.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SelectableText(diary.summary),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => onCopy(diary.title, diary.summary),
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Copy shared diary'),
        ),
      ],
    ),
  );
}
