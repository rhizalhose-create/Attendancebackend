import 'package:flutter/material.dart';
import 'dart:math';

class VerificationGame extends StatefulWidget {
  final Function(String token) onVerified;

  const VerificationGame({required this.onVerified});

  @override
  _VerificationGameState createState() => _VerificationGameState();
}

class _VerificationGameState extends State<VerificationGame> {
  late String question;
  late String correctAnswer;
  late List<String> options;
  String? selectedAnswer;
  bool isAnswered = false;
  int score = 0;

  @override
  void initState() {
    super.initState();
    generateQuestion();
  }

  void generateQuestion() {
    Random random = Random();
    int puzzleType = random.nextInt(4); // 4 different puzzle types
    
    switch (puzzleType) {
      case 0: // Sequence puzzle
        int start = random.nextInt(10) + 1;
        int step = random.nextInt(3) + 1;
        List<int> sequence = [];
        for (int i = 0; i < 4; i++) {
          sequence.add(start + i * step);
        }
        question = 'What comes next: ${sequence.join(', ')}, ?';
        correctAnswer = (start + 4 * step).toString();
        break;
      case 1: // Odd one out
        List<String> items = ['Apple', 'Banana', 'Carrot', 'Orange'];
        question = 'Which is different: ${items.join(', ')}';
        correctAnswer = 'Carrot'; // vegetable among fruits
        break;
      case 2: // Simple math (keep one)
        int num1 = random.nextInt(10) + 1;
        int num2 = random.nextInt(10) + 1;
        String op = ['+', '-', '×'][random.nextInt(3)];
        int answer;
        switch (op) {
          case '+': answer = num1 + num2; break;
          case '-': answer = num1 - num2; break;
          default: answer = num1 * num2; break;
        }
        question = 'Solve: $num1 $op $num2 = ?';
        correctAnswer = answer.toString();
        break;
      case 3: // Pattern
        question = 'Complete the pattern: 1, 4, 9, 16, ?';
        correctAnswer = '25'; // squares
        break;
    }

    // Generate options
    options = [correctAnswer];
    while (options.length < 4) {
      String wrong;
      if (puzzleType == 0 || puzzleType == 2 || puzzleType == 3) {
        // Numeric answers
        int numAnswer = int.parse(correctAnswer);
        wrong = (numAnswer + random.nextInt(10) - 5).toString();
      } else {
        // Text answers
        List<String> alternatives = ['Apple', 'Banana', 'Orange', 'Grape', 'Pear'];
        wrong = alternatives[random.nextInt(alternatives.length)];
      }
      if (wrong != correctAnswer && !options.contains(wrong)) {
        options.add(wrong);
      }
    }
    options.shuffle();
    
    selectedAnswer = null;
    isAnswered = false;
  }

  void checkAnswer(String answer) {
    setState(() {
      selectedAnswer = answer;
      isAnswered = true;
      if (answer == correctAnswer) {
        score++;
      }
    });

    Future.delayed(Duration(milliseconds: 800), () {
      if (score >= 3) {
        // Generate token and call callback
        String token = 'verification_game_token_${DateTime.now().millisecondsSinceEpoch}';
        widget.onVerified(token);
      } else {
        setState(() {
          generateQuestion();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Header
            Text(
              'Quick Verification',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Solve ${3 - score} more to proceed',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),

            // Progress
            LinearProgressIndicator(
              value: score / 3,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(Colors.green),
            ),
            SizedBox(height: 20),

            // Question
            Text(
              question,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),

            // Options Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: options.map((option) {
                bool isSelected = selectedAnswer == option;
                bool isCorrect = option == correctAnswer;
                
                Color bgColor = Colors.grey[100]!;
                Color borderColor = Colors.grey[300]!;
                Color textColor = Colors.black;

                if (isAnswered) {
                  if (isCorrect) {
                    bgColor = Colors.green[100]!;
                    borderColor = Colors.green;
                    textColor = Colors.green[900]!;
                  } else if (isSelected) {
                    bgColor = Colors.red[100]!;
                    borderColor = Colors.red;
                    textColor = Colors.red[900]!;
                  }
                }

                return GestureDetector(
                  onTap: isAnswered ? null : () => checkAnswer(option),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: borderColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$option',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 20),

            // Status message
            if (isAnswered)
              Text(
                selectedAnswer == correctAnswer ? '✓ Correct!' : '✗ Wrong, try again',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: selectedAnswer == correctAnswer ? Colors.green : Colors.red,
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }
}
