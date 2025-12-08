import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool outline;
  final bool primary;

  const ModernButton({Key? key, required this.label, this.onPressed, this.loading = false, this.icon, this.outline = false, this.primary = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = outline || !primary ? AppTheme.secondaryButtonStyle : AppTheme.primaryButtonStyle;

    return ElevatedButton(
      onPressed: (loading || onPressed == null) ? null : onPressed,
      style: style,
      child: SizedBox(
        height: 48,
        child: Center(
          child: loading
              ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18),
                      SizedBox(width: 8),
                    ],
                    Text(label, style: AppTheme.buttonText),
                  ],
                ),
        ),
      ),
    );
  }
}
