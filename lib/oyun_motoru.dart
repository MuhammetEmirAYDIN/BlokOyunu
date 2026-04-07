import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async'; 
import 'blok_model.dart'; 

class OyunMotoru extends ChangeNotifier {
  final int satirSayisi = 10;
  final int sutunSayisi = 8;
  
  late List<List<BlokModeli?>> oyunAlani;
  final Random _rastgele = Random();
  int hedefSayi = 0;

  List<List<int>> secimZinciri = []; 
  Timer? _zamanlayici; 
  
  // GÜNCELLENDİ: Artık sadece 1 bloğu değil, havada süzülen TÜM blokları bir listede takip ediyoruz
  List<List<int>> aktifDusenBloklar = [];

  int yanlisIslemSayac = 0; 

  OyunMotoru() {
    oyunAlaniniBaslat();
    yeniHedefSayiUret();
    _zamanlayiciyiBaslat(); 
  }

  void yeniHedefSayiUret() {
    hedefSayi = _rastgele.nextInt(16) + 10; 
    notifyListeners(); 
  }

  Color sayiRengiAl(int sayi) {
    switch (sayi) {
      case 1: return Colors.red.shade400;
      case 2: return Colors.blue.shade400;
      case 3: return Colors.green.shade400;
      case 4: return Colors.orange.shade400;
      case 5: return Colors.purple.shade400;
      case 6: return Colors.teal.shade400;
      case 7: return Colors.pink.shade400;
      case 8: return Colors.amber.shade400;
      case 9: return Colors.indigo.shade400;
      default: return Colors.grey;
    }
  }

  void oyunAlaniniBaslat() {
    oyunAlani = List.generate(
      satirSayisi,
      (satirIndeksi) => List.generate(
        sutunSayisi,
        (sutunIndeksi) {
          if (satirIndeksi >= satirSayisi - 3) {
            int rastgeleSayi = _rastgele.nextInt(9) + 1; 
            return BlokModeli(
              number: rastgeleSayi,
              color: sayiRengiAl(rastgeleSayi),
            );
          }
          return null; 
        },
      ),
    );
    notifyListeners();
  }

  void _zamanlayiciyiBaslat() {
    _zamanlayici = Timer.periodic(const Duration(seconds: 1), (timer) {
      _zamanlaAsagiKaydirVeUret();
    });
  }

  // GÜNCELLENDİ: Artık listedeki tüm blokları süzülerek aşağı indiriyor
  void _zamanlaAsagiKaydirVeUret() {
    bool degisiklikOldu = false;
    List<List<int>> yeniDusenler = [];

    // 1. AŞAMA: Havada süzülen tüm blokları 1 adım aşağı kaydır
    for (var blokKord in aktifDusenBloklar) {
      int satir = blokKord[0];
      int sutun = blokKord[1];

      // Altı boş mu ve zemine değmemiş mi?
      if (satir + 1 < satirSayisi && oyunAlani[satir + 1][sutun] == null) {
        oyunAlani[satir + 1][sutun] = oyunAlani[satir][sutun];
        oyunAlani[satir][sutun] = null;

        // Düşen blok oyuncu tarafından o an seçiliyse seçim koordinatını da güncelle
        for (var secilenKord in secimZinciri) {
          if (secilenKord[0] == satir && secilenKord[1] == sutun) {
            secilenKord[0] = satir + 1;
            break;
          }
        }
        
        // Blok hala düşmeye devam ettiği için yeni listeye ekle
        yeniDusenler.add([satir + 1, sutun]);
        degisiklikOldu = true;
      } 
      // Else durumu: Blok bir şeye çarptıysa (veya zemindeyse) listeye eklemiyoruz, böylece sabitleniyor.
    }
    
    // Aktif düşenler listesini güncelle
    aktifDusenBloklar = yeniDusenler;

    // 2. AŞAMA: Eğer havada süzülen HİÇBİR blok kalmadıysa, tepeden 1 tane yeni rastgele blok üret
    if (aktifDusenBloklar.isEmpty) {
      int rastgeleSutun = _rastgele.nextInt(sutunSayisi);
      if (oyunAlani[0][rastgeleSutun] == null) {
        int rastgeleSayi = _rastgele.nextInt(9) + 1;
        oyunAlani[0][rastgeleSutun] = BlokModeli(
          number: rastgeleSayi,
          color: sayiRengiAl(rastgeleSayi),
        );
        aktifDusenBloklar.add([0, rastgeleSutun]); // Yeni üretilen bloğu düşenler listesine ekle
        degisiklikOldu = true;
      }
    }

    if (degisiklikOldu) {
      notifyListeners();
    }
  }

  bool _komsuMu(int satir1, int sutun1, int satir2, int sutun2) {
    int satirFarki = (satir1 - satir2).abs();
    int sutunFarki = (sutun1 - sutun2).abs();
    return satirFarki <= 1 && sutunFarki <= 1 && !(satirFarki == 0 && sutunFarki == 0);
  }

  void blokSec(int satir, int sutun) {
    BlokModeli? tiklananBlok = oyunAlani[satir][sutun];
    if (tiklananBlok == null) return;

    if (tiklananBlok.isSelected) {
      tiklananBlok.isSelected = false;
      secimZinciri.removeWhere((kord) => kord[0] == satir && kord[1] == sutun);
      notifyListeners();
      return;
    }

    if (secimZinciri.length >= 4) return;

    if (secimZinciri.isNotEmpty) {
      bool komsuBulundu = false;
      for (var kord in secimZinciri) {
        if (_komsuMu(kord[0], kord[1], satir, sutun)) {
          komsuBulundu = true;
          break;
        }
      }

      if (!komsuBulundu) return;
    }

    tiklananBlok.isSelected = true;
    secimZinciri.add([satir, sutun]);
    notifyListeners();
  }

  int get mevcutToplam {
    int toplam = 0;
    for (var kord in secimZinciri) {
      toplam += oyunAlani[kord[0]][kord[1]]!.number;
    }
    return toplam;
  }

  void _anindaAsagiKaydir() {
    for (int sutun = 0; sutun < sutunSayisi; sutun++) {
      for (int satir = satirSayisi - 1; satir >= 0; satir--) {
        if (oyunAlani[satir][sutun] == null) {
          for (int ustSatir = satir - 1; ustSatir >= 0; ustSatir--) {
            if (oyunAlani[ustSatir][sutun] != null) {
              
              // KRİTİK GÜNCELLEME: Eğer bu blok "düşmekte olanlar" listesindeyse, anında indirme! Bırak süzülsün.
              bool dusenBlokMu = aktifDusenBloklar.any((b) => b[0] == ustSatir && b[1] == sutun);
              if (dusenBlokMu) continue; 

              oyunAlani[satir][sutun] = oyunAlani[ustSatir][sutun];
              oyunAlani[ustSatir][sutun] = null;

              for (var kord in secimZinciri) {
                if (kord[0] == ustSatir && kord[1] == sutun) {
                  kord[0] = satir;
                  break;
                }
              }
              break;
            }
          }
        }
      }
    }
  }

  // GÜNCELLENDİ: Ceza yediğimizde oluşan 8 bloğu da "havada süzülenler" listesine atıyoruz.
  void _cezaUygula() {
    for (int sutun = 0; sutun < sutunSayisi; sutun++) {
      if (oyunAlani[0][sutun] == null) {
        int rastgeleSayi = _rastgele.nextInt(9) + 1;
        oyunAlani[0][sutun] = BlokModeli(
          number: rastgeleSayi,
          color: sayiRengiAl(rastgeleSayi),
        );
        // Bu blokları listeye ekliyoruz ki timer bunları adım adım indirsin
        aktifDusenBloklar.add([0, sutun]); 
      }
    }
  }

  int islemOnayla() {
    if (secimZinciri.length < 2) return 0; 

    if (mevcutToplam == hedefSayi) {
      for (var kord in secimZinciri) {
        oyunAlani[kord[0]][kord[1]] = null;
      }

      _anindaAsagiKaydir();

      secimZinciri.clear();
      yeniHedefSayiUret();
      yanlisIslemSayac = 0; 
      notifyListeners();
      return 1; 
    } else {
      for (var kord in secimZinciri) {
        oyunAlani[kord[0]][kord[1]]!.isSelected = false;
      }
      secimZinciri.clear();
      
      yanlisIslemSayac++;
      if (yanlisIslemSayac >= 3) {
        _cezaUygula(); 
        // DİKKAT: Buradaki _anindaAsagiKaydir(); satırını sildik! 
        // Artık bloklar anında değil, Timer'ın insafında 5 saniyede bir inecek.
        yanlisIslemSayac = 0; 
        notifyListeners();
        return 3; 
      }

      notifyListeners();
      return 2; 
    }
  }

  @override
  void dispose() {
    _zamanlayici?.cancel(); 
    super.dispose();
  }
}