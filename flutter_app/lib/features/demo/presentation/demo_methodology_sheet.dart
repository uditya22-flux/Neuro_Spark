import 'package:flutter/material.dart';

/// Research and engine methodology for hospital stakeholders.
class DemoMethodologySheet extends StatelessWidget {
  const DemoMethodologySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => const DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: _sheetBody,
      ),
    );
  }

  static Widget _sheetBody(BuildContext context, ScrollController scrollController) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ListView(
        controller: scrollController,
        children: [
          Text(
            'How MindBridge questions work',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Synthetic demo — not for clinical diagnosis or treatment decisions.',
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 20),
          const _Section(
            title: '1. Present-moment golden rule',
            body:
                'Every prompt asks whether an activity feels fun right now. '
                'The engine never asks about future jobs, careers, salaries, or adult work roles. '
                'This framing is validated in engagement research — present-tense enjoyment '
                'yields more accurate interest signals than career hypotheticals for children aged 8–13.',
          ),
          const _Section(
            title: '2. RIASEC play themes (30 sectors)',
            body:
                'Interests are mapped to 30 childhood play themes derived from the RIASEC model '
                '(Realistic, Investigative, Artistic, Social, Enterprising, Conventional) — '
                'five concrete activities per type. Themes use elementary hobby drawings, not job titles.',
          ),
          const _Section(
            title: '3. ISAA modality routing',
            body:
                'Indian Scale for Assessment of Autism (ISAA) scores plus sensory triggers route '
                'each item to picture, text, video, or haptic format. Low verbal scores disable '
                'reading-heavy text and prefer simple concrete drawings without faces or clutter.',
          ),
          const _Section(
            title: '4. 60% adaptive filter (10 layers)',
            body:
                'The funnel advances the top 60% of engaged sectors layer by layer: '
                '30 → 18 → 11 → 7 → 4, then deep-dives into final niches. '
                'This reduces demand avoidance while narrowing to hyper-fixation strengths. '
                'Demo mode shortens to 3 layers for live presentations.',
          ),
          const _Section(
            title: '5. Template synthesis engine',
            body:
                'Questions are assembled from JSON templates per sector (golden rule, visual guidelines, '
                'present-moment prompt). Layer 2+ adds depth cues; layers 6+ can use optional LLM '
                'generation when enabled server-side. All outputs pass forbidden-term validation.',
          ),
          const _Section(
            title: '6. Charter safeguards',
            body:
                'No diagnostic labels, employment prediction, child notifications, streaks, or badges. '
                'Guardian-led only. Child data exportable and purgeable on request.',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
