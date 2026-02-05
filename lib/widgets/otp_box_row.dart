import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OtpBoxRow extends StatelessWidget {
  final String value;
  final bool obscure;
  final int length;

  const OtpBoxRow({
    super.key,
    required this.value,
    this.obscure = false,
    this.length = 6,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ 화면이 좁으면 gap 줄이기
        final isNarrow = constraints.maxWidth < 360;
        final gap = isNarrow ? 6.0 : 8.0;

        final totalGap = gap * (length - 1);
        final boxW = (constraints.maxWidth - totalGap) / length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(length, (i) {
            final filled = i < value.length;

            return Container(
              // ✅ 최소값을 낮춰서 overflow 방지
              width: boxW.clamp(34.0, 56.0),
              height: 54,
              margin: EdgeInsets.only(right: i == length - 1 ? 0 : gap),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: filled ? Colors.grey.shade500 : Colors.grey.shade300,
                ),
              ),
              child: Text(
                filled ? (obscure ? '●' : value[i]) : '',
                style: TextStyle(
                  fontSize: obscure ? 22 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
