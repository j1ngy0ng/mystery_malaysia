import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controller/passport_diary/passport_diary_facade_interface.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

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

  @override
  void initState() {
    super.initState();
    facade = widget.facade;
    facade.load();
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
                            : 'How did it feel?',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        widget.sessionId == null
                            ? 'Open a completed mission to create another diary.'
                            : 'Only your reflection and verified visits are used.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.sessionId != null && !generated) ...[
            const SizedBox(height: 20),
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
              onPressed: facade.isLoading ? null : _generate,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Generate verified travel diary'),
            ),
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
            const Center(child: CircularProgressIndicator())
          else if (facade.memories.isEmpty)
            const Text('No saved diaries yet.')
          else
            ...facade.memories.map(
              (memory) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: Text(
                    memory.emoji,
                    style: const TextStyle(fontSize: 30),
                  ),
                  title: Text(memory.title),
                  subtitle: Text(memory.date),
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

  Future<void> _generate() async {
    final result = await facade.generateDiary(
      widget.sessionId!,
      reflection.text,
    );
    if (!mounted || result == null) return;
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
