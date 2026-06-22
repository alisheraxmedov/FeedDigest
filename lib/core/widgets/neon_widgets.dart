/*
Shared building blocks for the Neon Professional UI, all reading their colors
from the AppPalette theme extension so they render correctly in both the dark and
light themes. Callers pass already-localized strings; these widgets hold no text.
*/
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const double kCardRadius = 20;
const TextStyle _labelSm = TextStyle(
  fontSize: 12,
  height: 16 / 12,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.6,
);

class NeonCard extends StatelessWidget {
  const NeonCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = kCardRadius,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final decorated = Container(
      decoration: BoxDecoration(
        color: palette.cardColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? palette.mutedBorder),
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return decorated;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: decorated),
    );
  }
}

class IconCircle extends StatelessWidget {
  const IconCircle({
    super.key,
    required this.icon,
    this.accent = false,
    this.size = 40,
  });

  final IconData icon;
  final bool accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent ? palette.accentSoft : palette.iconCircle,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: accent
            ? palette.accentText
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.width,
    this.radius = 999,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  /// Fixed width for a uniform, centered chip. When null the chip hugs its
  /// content (pill behaviour used by the Saved screen).
  final double? width;

  /// Corner radius. Defaults to a full pill; the feed bar passes a small value
  /// for near-rectangular chips.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final labelText = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _labelSm.copyWith(
        color: selected ? palette.accentText : scheme.onSurfaceVariant,
      ),
    );
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        alignment: width == null ? null : Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? palette.accentSoft : scheme.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: selected ? palette.accent : palette.mutedBorder,
          ),
          boxShadow: selected
              ? [BoxShadow(color: palette.glow, blurRadius: 10)]
              : null,
        ),
        child: Row(
          mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color: selected ? palette.accentText : palette.textDim),
              const SizedBox(width: 6),
            ],
            width == null ? labelText : Flexible(child: labelText),
          ],
        ),
      ),
    );
  }
}

class NeonBadge extends StatelessWidget {
  const NeonBadge({super.key, required this.label, this.dot = true});

  final String label;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: palette.accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(label, style: _labelSm.copyWith(color: palette.accentText)),
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.accentIcon = false,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;
  final bool accentIcon;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return NeonCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconCircle(icon: icon, accent: accentIcon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    value!,
                    style: TextStyle(fontSize: 13, color: palette.textDim),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.uppercase = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: palette.accent.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: palette.accent,
            foregroundColor: palette.onAccent,
            disabledBackgroundColor: palette.accent.withValues(alpha: 0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _ButtonLabel(label: label, icon: icon, uppercase: uppercase),
        ),
      ),
    );
  }
}

class NeonGhostButton extends StatelessWidget {
  const NeonGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.uppercase = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.accentText,
          side: BorderSide(color: palette.accent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _ButtonLabel(label: label, icon: icon, uppercase: uppercase),
      ),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.label, this.icon, this.uppercase = false});

  final String label;
  final IconData? icon;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      uppercase ? label.toUpperCase() : label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: uppercase ? 0.6 : 0.2,
      ),
    );
    if (icon == null) return text;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Flexible(child: text),
      ],
    );
  }
}

class PickerOption<T> {
  const PickerOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

Future<void> showOptionPicker<T>({
  required BuildContext context,
  required String title,
  required List<PickerOption<T>> options,
  required T selected,
  required ValueChanged<T> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _OptionPickerSheet<T>(
      title: title,
      options: options,
      selected: selected,
      onSelected: onSelected,
    ),
  );
}

class _OptionPickerSheet<T> extends StatelessWidget {
  const _OptionPickerSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<PickerOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final option in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _OptionTile<T>(
                  option: option,
                  selected: option.value == selected,
                  onTap: () {
                    onSelected(option.value);
                    Navigator.of(context).pop();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile<T> extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PickerOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? palette.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? palette.accent : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              if (option.icon != null) ...[
                IconCircle(icon: option.icon!),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: palette.accent),
            ],
          ),
        ),
      ),
    );
  }
}
