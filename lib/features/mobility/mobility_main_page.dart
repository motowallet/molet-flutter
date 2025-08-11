import 'package:flutter/material.dart';
import 'map_select_page.dart';

class MobilityMainPage extends StatelessWidget {
  const MobilityMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primaryContainer,
                      cs.primaryContainer.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        color: cs.onPrimaryContainer.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.auto_mode_rounded, size: 34),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('자율주행 호출',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              )),
                          const SizedBox(height: 6),
                          Text(
                            '지도를 탭해 출발지·도착지를 고르면 즉시 호출이 시작돼요.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onPrimaryContainer.withOpacity(.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Steps
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: const [
                      _StepTile(icon: Icons.map_rounded, title: '지도로 출발/도착 선택'),
                      _StepDivider(),
                      _StepTile(icon: Icons.directions_car_filled, title: '차량 이동 및 도착 안내'),
                      _StepDivider(),
                      _StepTile(icon: Icons.qr_code_scanner, title: '도착 후 QR로 결제'),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // CTA
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.map_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('지도로 출발/도착 선택'),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MapSelectPage()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '도착지에 도착하면 결제 안내가 표시됩니다.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final IconData icon;
  final String title;
  const _StepTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
    );
  }
}

class _StepDivider extends StatelessWidget {
  const _StepDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1),
    );
  }
}
