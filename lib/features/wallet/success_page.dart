import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SuccessPage extends StatelessWidget {
  final String title;
  final int? amount;   // 송금 금액 (요청이면 null)
  final String? toName;

  const SuccessPage({super.key, required this.title, this.amount, this.toName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('완료')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 96, color: Colors.blueGrey),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (amount != null && toName != null) {
                    final now  = DateTime.now();
                    final date = DateFormat('yyyy-MM-dd').format(now);
                    Navigator.pop<Map<String, dynamic>>(context, {
                      'event': 'transfer_completed',
                      'amount': amount,   // 양수
                      'toName': toName,
                      'date': date,
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
