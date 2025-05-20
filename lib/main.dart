import 'package:flutter/material.dart';

void main() {
  runApp(MoletApp());
}

class MoletApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Molet',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Roboto',
      ),
      home: MoletMainPage(),
    );
  }
}

class MoletMainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Molet'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 100, color: Colors.indigo),
            SizedBox(height: 20),
            Text(
              'Welcome to Molet!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '당신의 스마트 지갑을 시작해보세요.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
              },
              child: Text('시작하기'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
