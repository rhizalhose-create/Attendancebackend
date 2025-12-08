import 'package:flutter/material.dart';
import '../utils/password_utils.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;
  final double width;

  const PasswordStrengthIndicator({Key? key, required this.strength, this.width = double.infinity}) : super(key: key);

  Color _colorForStrength() {
    switch (strength) {
      case PasswordStrength.veryWeak:
        return Colors.red.shade200;
      case PasswordStrength.weak:
        return Colors.orange.shade300;
      case PasswordStrength.medium:
        return Colors.amber.shade400;
      case PasswordStrength.strong:
        return Colors.lightGreen.shade400;
      case PasswordStrength.veryStrong:
        return Colors.green.shade700;
    }
  }

  double _fractionForStrength() {
    switch (strength) {
      case PasswordStrength.veryWeak:
        return 0.2;
      case PasswordStrength.weak:
        return 0.4;
      case PasswordStrength.medium:
        return 0.6;
      case PasswordStrength.strong:
        return 0.8;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForStrength();
    final frac = _fractionForStrength();
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: frac,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        Text(PasswordUtils.label(strength), style: TextStyle(fontSize: 12)),
      ],
    );
  }
}
