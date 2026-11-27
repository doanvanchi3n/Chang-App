import 'package:flutter/material.dart';

import 'feature_surface.dart';

Future<bool> showChangConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Hủy',
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        icon: Align(
          alignment: Alignment.centerLeft,
          child: CircleAvatar(
            backgroundColor: destructive ? const Color(0xFFFFEEEE) : changSoft,
            child: Icon(
              destructive ? Icons.delete_outline : Icons.info_outline,
              color: destructive
                  ? Theme.of(context).colorScheme.error
                  : changBlue,
            ),
          ),
        ),
        title: Text(title, textAlign: TextAlign.start),
        content: Text(message, textAlign: TextAlign.start),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: changBlue,
              side: const BorderSide(color: changBorder),
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: destructive
                  ? Theme.of(context).colorScheme.error
                  : changBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;
