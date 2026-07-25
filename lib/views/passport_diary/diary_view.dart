import 'package:flutter/material.dart';

import '../../controllers/passport_diary/passport_diary_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/status_pill.dart';

class DiaryView extends StatefulWidget {
  const DiaryView({super.key});

  @override
  State<DiaryView> createState() => _DiaryViewState();
}

class _DiaryViewState extends State<DiaryView> {
  final controller = PassportDiaryController();
  final reflection = TextEditingController();
  bool submitted = false;

  @override
  void dispose() {
    controller.dispose();
    reflection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Travel diary')),
      body: ListView(
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
                        'How did it feel?',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Text(
                        'Your reflection helps AI craft a personal travel story.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: reflection,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Reflection for Lanterns & Legends',
              hintText: 'A moment, feeling or surprise you want to remember...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => setState(() => submitted = true),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Save & generate diary'),
          ),
          if (submitted) ...[
            const SizedBox(height: 12),
            const StatusPill(
              label: 'Reflection submitted',
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.green,
            ),
          ],
          const SizedBox(height: 30),
          Text(
            'Your memory book',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...controller.memories.map(
            (memory) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 78,
                        decoration: BoxDecoration(
                          color: AppColors.paleMango,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          memory.emoji,
                          style: const TextStyle(fontSize: 34),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              memory.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              memory.date,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(memory.summary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
