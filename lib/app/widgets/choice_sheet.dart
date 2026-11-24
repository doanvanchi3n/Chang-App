import 'package:flutter/material.dart';

import 'feature_surface.dart';

class ChangChoice {
  const ChangChoice(
    this.value,
    this.title, {
    this.subtitle,
    this.icon = Icons.checklist_rounded,
  });
  final String value, title;
  final String? subtitle;
  final IconData icon;
}

Future<String?> showChangChoices(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String selected,
  required List<ChangChoice> choices,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: Colors.white,
  constraints: const BoxConstraints(maxWidth: 560),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (context) => SafeArea(
    top: false,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .72,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          Text(
            title,
            style: const TextStyle(
              color: changInk,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: changMuted, height: 1.5),
          ),
          const SizedBox(height: 20),
          for (final choice in choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ChoiceTile(
                title: choice.title,
                subtitle: choice.subtitle,
                icon: choice.icon,
                selected: choice.value == selected,
                onTap: () => Navigator.pop(context, choice.value),
              ),
            ),
        ],
      ),
    ),
  ),
);

class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? changSoft : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: selected ? changBlue : changBorder,
        width: selected ? 1.5 : 1,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      selected: selected,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: selected ? Colors.white : changSoft,
        child: Icon(icon, color: changBlue, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: changInk,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle!,
                style: const TextStyle(
                  color: changMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
      trailing:
          trailing ??
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: selected ? changBlue : changBorder,
            size: 24,
          ),
      onTap: onTap,
    ),
  );
}

class ChoiceField extends StatelessWidget {
  const ChoiceField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });
  final String label, value;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: changBorder),
    ),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      enabled: onTap != null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Icon(icon, color: changBlue),
      title: Text(
        label,
        style: const TextStyle(color: changMuted, fontSize: 13),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          value,
          style: const TextStyle(
            color: changInk,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ),
      trailing: const Icon(Icons.expand_more_rounded, color: changBlue),
      onTap: onTap,
    ),
  );
}
