import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'oyun_motoru.dart';
import 'blok_model.dart';

class OyunEkrani extends StatefulWidget {
  const OyunEkrani({super.key});

  @override
  State<OyunEkrani> createState() => _OyunEkraniState();
}

class _OyunEkraniState extends State<OyunEkrani> {
  late OyunMotoru _motor;
  final TextEditingController _isimController = TextEditingController();
  List<String> _liderlikTablosu = [];

  @override
  void initState() {
    super.initState();
    _motor = OyunMotoru();
    // Motor her güncellendiğinde arayüzün yenilenmesi ve oyun sonu kontrolü için dinleyici ekliyoruz
    _motor.addListener(_motorDinleyici);
    _skorlariYukle();
  }

  @override
  void dispose() {
    _motor.removeListener(_motorDinleyici);
    _motor.dispose();
    _isimController.dispose();
    super.dispose();
  }

  void _motorDinleyici() {
    if (_motor.oyunBittiMi) {
      _motor.removeListener(_motorDinleyici); // Diyaloğun üst üste açılmasını engellemek için
      _oyunBittiDiyalogGoster();
    }
    setState(() {});
  }

  // Shared Preferences ile liderlik tablosunu yükleme
  Future<void> _skorlariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _liderlikTablosu = prefs.getStringList('liderlik_tablosu') ?? [];
    });
  }

  // Yeni skoru liderlik tablosuna ekleme ve sıralama
  Future<void> _skoruKaydet(String isim, int puan) async {
    final prefs = await SharedPreferences.getInstance();
    // Format: "İsim: Puan"
    _liderlikTablosu.add("$isim: $puan");

    // Skorları puana göre yüksekten düşüğe sırala
    _liderlikTablosu.sort((a, b) {
      int puanA = int.parse(a.split(': ').last);
      int puanB = int.parse(b.split(': ').last);
      return puanB.compareTo(puanA);
    });

    // Sadece ilk 5 skoru tutalım
    if (_liderlikTablosu.length > 5) {
      _liderlikTablosu = _liderlikTablosu.sublist(0, 5);
    }

    await prefs.setStringList('liderlik_tablosu', _liderlikTablosu);
    _skorlariYukle();
  }

  void _onayButonunaBasildi() {
    int sonuc = _motor.islemOnayla();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (sonuc == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az 2 blok seçmelisiniz!'), backgroundColor: Colors.red),
      );
    } else if (sonuc == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yanlış Toplam! Dikkat, 3 yanlışta ceza alacaksınız. (${_motor.yanlisIslemSayac}/3)'),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (sonuc == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('3 Kez Yanlış İşlem! CEZA: Tüm sütunlara blok eklendi.'), backgroundColor: Colors.red),
      );
    }
  }

  void _oyunuYenidenBaslat() {
    setState(() {
      _motor.removeListener(_motorDinleyici);
      _motor.dispose();
      _motor = OyunMotoru();
      _motor.addListener(_motorDinleyici);
    });
  }

  // Oyun bittiğinde açılacak Skor Kayıt ve Liderlik Tablosu Popup'ı
  void _oyunBittiDiyalogGoster() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('OYUN BİTTİ!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Toplam Puanınız: ${_motor.toplamPuan}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                TextField(
                  controller: _isimController,
                  decoration: const InputDecoration(
                    labelText: 'Adınızı Giriniz',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('🏆 EN YÜKSEK SKORLAR 🏆', style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                _liderlikTablosu.isEmpty
                    ? const Text('Henüz kaydedilmiş skor yok.')
                    : Column(
                        children: _liderlikTablosu.map((skor) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Text(skor, style: const TextStyle(fontSize: 16)),
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (_isimController.text.trim().isNotEmpty) {
                  _skoruKaydet(_isimController.text.trim(), _motor.toplamPuan);
                  _isimController.clear();
                  Navigator.of(context).pop();
                  _oyunuYenidenBaslat();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen bir isim girin!')),
                  );
                }
              },
              child: const Text('Skoru Kaydet & Yeniden Başlat'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stratejik Sayı Birleştirme', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _oyunuYenidenBaslat,
            tooltip: 'Yeniden Başlat',
          )
        ],
      ),
      body: Column(
        children: [
          // ÜST BİLGİ PANELİ (Puan, Hedef, Hız)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('HEDEF', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text('${_motor.hedefSayi}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                Column(
                  children: [
                    const Text('TOPLAM', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text('${_motor.mevcutToplam}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _motor.mevcutToplam == _motor.hedefSayi ? Colors.green : Colors.red)),
                  ],
                ),
                Column(
                  children: [
                    const Text('PUAN', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text('${_motor.toplamPuan}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.purple)),
                  ],
                ),
                Column(
                  children: [
                    const Text('HIZ (sn)', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text('${_motor.mevcutSure}s', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
              ],
            ),
          ),

          // MATRİS / OYUN ALANI
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _motor.sutunSayisi,
                  childAspectRatio: 1.0,
                ),
                itemCount: _motor.satirSayisi * _motor.sutunSayisi,
                itemBuilder: (context, index) {
                  int satir = index ~/ _motor.sutunSayisi;
                  int sutun = index % _motor.sutunSayisi;
                  BlokModeli? mevcutBlok = _motor.oyunAlani[satir][sutun];

                  return GestureDetector(
                    onTap: () => _motor.blokSec(satir, sutun),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: mevcutBlok != null ? mevcutBlok.color : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                        border: mevcutBlok != null && mevcutBlok.isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: mevcutBlok != null && mevcutBlok.isSelected
                            ? const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 1))]
                            : [],
                      ),
                      child: mevcutBlok != null
                          ? Center(
                              child: Text(
                                '${mevcutBlok.number}',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),

          // ONAY BUTONU
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _onayButonunaBasildi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: const Text('SEÇİMİ ONAYLA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}