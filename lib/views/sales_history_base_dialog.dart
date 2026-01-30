import 'package:flutter/material.dart';

class SalesHistoryBaseDialog extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color iconColor;
  final Color subTextColor;
  final VoidCallback onConfirm;
  final bool isDangerDialog;
  final String yesText;
  final String noText;
  final Widget? customContent;

  const SalesHistoryBaseDialog({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    required this.iconColor,
    this.subTextColor = Colors.black54,
    required this.onConfirm,
    this.isDangerDialog = false,
    this.yesText = "확인",
    this.noText = "취소",
    this.customContent
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      backgroundColor: Colors.white,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 50),
            ),
            const SizedBox(height: 24),
            Text(title, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: iconColor)),
            const SizedBox(height: 12),
            Text(content, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: subTextColor, height: 1.5)),
            if (customContent != null) ...[
              const SizedBox(height: 20),
              customContent!,
            ],
            const SizedBox(height: 35),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: isDangerDialog ? Colors.white : iconColor,
                        side: isDangerDialog ? BorderSide(color: iconColor, width: 1.5) : BorderSide.none,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(yesText,
                        style: TextStyle(
                        fontSize: 18,
                        color: isDangerDialog ? iconColor : Colors.white,
                        fontWeight: FontWeight.w900
                        )
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(noText, style: TextStyle(fontSize: 18, color: Colors.black87)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}