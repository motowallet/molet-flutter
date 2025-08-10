import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<int?> showAmountSheet(BuildContext context) async {
  final controller = TextEditingController(text: '10000');
  final formKey = GlobalKey<FormState>();

  final result = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('금액 입력', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                validator: (v) {
                  final n = int.tryParse(v?.replaceAll(',', '') ?? '');
                  if (n == null || n <= 0) return '올바른 금액을 입력하세요';
                  return null;
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (v) {
                  final raw = v.replaceAll(',', '');
                  final n = int.tryParse(raw);
                  if (n == null) return;
                  final t = NumberFormat('#,###').format(n);
                  controller.value = TextEditingValue(
                    text: t,
                    selection: TextSelection.collapsed(offset: t.length),
                  );
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  final n = int.parse(controller.text.replaceAll(',', ''));
                  Navigator.pop(ctx, n);
                },
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result;
}
