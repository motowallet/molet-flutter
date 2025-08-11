import 'package:flutter/material.dart';

class DonePage extends StatelessWidget {
  final int amount;
  final int? newBalance;
  final String? tripId;

  const DonePage({
    super.key,
    required this.amount,
    this.newBalance,
    this.tripId,
  });

  String _won(int v) {
    final s = v.toString(); final b = StringBuffer();
    for (int i=0;i<s.length;i++){final r=s.length-i; b.write(s[i]); if(r>1&&r%3==1)b.write(',');}
    return '$b원';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mobility')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                elevation: 0,
                color: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const SizedBox(width: 220, height: 220, child: Icon(Icons.check, size: 64)),
              ),
              const SizedBox(height: 16),
              Text('결제가 완료되었습니다', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _line('결제 금액', _won(amount)),
              if (newBalance != null) _line('결제 후 잔액', _won(newBalance!)),
              if (tripId != null) _line('트립 ID', tripId!),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                      child: const Text('처음으로'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('확인'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(k), Text(v, style: const TextStyle(fontWeight: FontWeight.w700))],
    ),
  );
}
