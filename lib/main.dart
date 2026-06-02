
import 'package:blokoyunu/oyun_ekrani.dart';
import 'package:flutter/material.dart';
 

void main() {
  runApp(const OyunaBasla());
}

class OyunaBasla extends StatelessWidget {
  const OyunaBasla({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sayı Birleştirme',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      home: const OyunEkrani(),
    );
  }
}