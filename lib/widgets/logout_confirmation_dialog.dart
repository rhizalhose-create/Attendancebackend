import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'modern_button.dart';
import 'modern_card.dart';

Future<bool?> showLogoutConfirmationDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ModernCard(
          padding: EdgeInsets.all(AppTheme.spacingLG),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.logout, color: AppTheme.primaryColor, size: 28),
                  SizedBox(width: AppTheme.spacingMD),
                  Expanded(
                    child: Text(
                      'Confirm Logout',
                      style: AppTheme.heading4,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingSM),
              Text(
                'Are you sure you want to logout? You will need to login again to continue using the app.',
                style: AppTheme.bodyMedium,
              ),
              SizedBox(height: AppTheme.spacingLG),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ModernButton(
                    label: 'Cancel',
                    outline: true,
                    primary: false,
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                  SizedBox(width: AppTheme.spacingSM),
                  ModernButton(
                    label: 'Logout',
                    outline: false,
                    primary: true,
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
