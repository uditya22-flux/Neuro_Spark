import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class IntakeStepHeader extends StatelessWidget {
  const IntakeStepHeader({
    super.key,
    required this.stepIndex,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
  });

  final int stepIndex;
  final int totalSteps;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (stepIndex + 1) / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Step ${stepIndex + 1} of $totalSteps',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surface,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Step ${stepIndex + 1} of $totalSteps',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class IntakeSectionCard extends StatelessWidget {
  const IntakeSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class IntakeDomainSlider extends StatelessWidget {
  const IntakeDomainSlider({
    super.key,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$label, score $value out of 5',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$value',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Slider(
              value: value.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$value',
              onChanged: (v) => onChanged(v.round()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 — Minimal', style: theme.textTheme.labelSmall),
                Text('5 — Elevated', style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class IntakeChoiceChipGroup<T> extends StatelessWidget {
  const IntakeChoiceChipGroup({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  final String label;
  final List<T> options;
  final T selected;
  final String Function(T option) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            final isSelected = option == selected;
            return Semantics(
              button: true,
              selected: isSelected,
              label: labelBuilder(option),
              child: FilterChip(
                label: Text(labelBuilder(option)),
                selected: isSelected,
                showCheckmark: true,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                labelStyle: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 15,
                ),
                onSelected: (_) => onSelected(option),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class IntakeTriggerCheckboxList extends StatelessWidget {
  const IntakeTriggerCheckboxList({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final String title;
  final List<String> options;
  final List<String> selected;
  final void Function(String option, bool isSelected) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...options.map((option) {
          final isChecked = selected.contains(option);
          return Semantics(
            checked: isChecked,
            label: option,
            child: CheckboxListTile(
              value: isChecked,
              onChanged: (checked) => onToggle(option, checked ?? false),
              title: Text(option, style: theme.textTheme.bodyLarge),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        }),
      ],
    );
  }
}

class ConfigPreviewRow extends StatelessWidget {
  const ConfigPreviewRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (highlight ? theme.colorScheme.secondary : theme.colorScheme.primary)
                  .withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: highlight ? theme.colorScheme.secondary : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
