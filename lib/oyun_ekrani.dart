import 'package:flutter/material.dart';
import 'oyun_motoru.dart';
import 'blok_model.dart'; 

class OyunEkrani extends StatefulWidget {
  const OyunEkrani({super.key});

  @override
  State<OyunEkrani> createState() => _OyunEkraniState();
}

class _OyunEkraniState extends State<OyunEkrani> {
  final OyunMotoru _motor = OyunMotoru();

  // GÜNCELLENDİ: Yeni kodlara göre mesaj sistemi
  void _onayButonunaBasildi() {
    int sonuc = _motor.islemOnayla();
    
    // Açık olan eski SnackBar'ları hemen kapat
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (sonuc == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En az 2 blok seçmelisiniz!')));
    } else if (sonuc == 1) {
    
    } else if (sonuc == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yanlış Toplam! Dikkat, 3 yanlışta ceza alacaksınız. (${_motor.yanlisIslemSayac}/3)'), backgroundColor: Colors.orange),
      );
    } else if (sonuc == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('3 Kez Yanlış İşlem! CEZA: Yukarıdan Yeni Bloklar İndi.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _motor,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Hedef Sayı: ${_motor.hedefSayi}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24)),
            backgroundColor: Colors.blueGrey[800],
            centerTitle: true,
          ),
          body: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AspectRatio(
                      aspectRatio: 8 / 10,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          color: Colors.grey[800], 
                        ),
                        child: _oyunIzgarasiniCiz(),
                      ),
                    ),
                  ),
                ),
              ),
              // GÜNCELLENDİ: Ceza Sayacını oyuncuya görsel olarak da gösteriyoruz
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mevcut Toplam: ${_motor.mevcutToplam}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hatalı İşlem: ${_motor.yanlisIslemSayac} / 3',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _motor.yanlisIslemSayac > 0 ? Colors.red : Colors.grey),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _motor.secimZinciri.isEmpty ? null : _onayButonunaBasildi,
                      icon: const Icon(Icons.check),
                      label: const Text('ONAYLA', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      }
    );
  }

  Widget _oyunIzgarasiniCiz() {
    return Column(
      children: List.generate(_motor.satirSayisi, (satir) {
        return Expanded(
          child: Row(
            children: List.generate(_motor.sutunSayisi, (sutun) {
              
              BlokModeli? mevcutBlok = _motor.oyunAlani[satir][sutun];

              return Expanded(
                child: GestureDetector(
                  onTap: () => _motor.blokSec(satir, sutun),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: mevcutBlok != null ? mevcutBlok.color : Colors.grey[700], 
                      borderRadius: BorderRadius.circular(8), 
                      border: mevcutBlok != null && mevcutBlok.isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: mevcutBlok != null && mevcutBlok.isSelected
                          ? const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 2))]
                          : [],
                    ),
                    child: mevcutBlok != null 
                        ? Center(
                            child: Text(
                              '${mevcutBlok.number}',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          )
                        : null,
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}