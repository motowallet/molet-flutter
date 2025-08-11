import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _done = false;

  void _onDetect(BarcodeCapture cap) async {
    if (_done) return;
    final raw = cap.barcodes.first.rawValue;
    if (raw == null) return;
    _done = true;
    if (!mounted) return;

    // QR 문자열에서 amount/tripId 추출 (확실하지 않음: 팀 포맷 확정 전 임시 파서)
    final parsed = _parseQr(raw);
    Navigator.pop(context, parsed); // {amount:int?, tripId:String?, raw:String}
  }

  Map<String, dynamic> _parseQr(String raw) {
    int? amount;
    String? tripId;

    // 1) URL 쿼리로 전달되는 경우: moletpay://pay?amt=12000&tripId=abc
    try {
      final u = Uri.parse(raw);
      final a = u.queryParameters['amt'] ?? u.queryParameters['amount'];
      if (a != null) amount = int.tryParse(a);
      tripId = u.queryParameters['tripId'] ?? tripId;
    } catch (_) {}

    // 2) 텍스트에 숫자만 있는 경우(ex: 12,000원)
    if (amount == null) {
      final m = RegExp(r'(\d{3,})\s*원?').firstMatch(raw.replaceAll(',', ''));
      if (m != null) amount = int.tryParse(m.group(1)!);
    }

    return {'amount': amount, 'tripId': tripId, 'raw': raw};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR스캔'), centerTitle: true),
      body: Container(
        color: Colors.black,
        child: MobileScanner(onDetect: _onDetect),
      ),
    );
  }
}
