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
  Timer? _dusmeTimeri;
  

  List<List<int>> aktifDusenBloklar = [];

  int yanlisIslemSayac = 0; 

  int toplamPuan = 0;
  int mevcutSure = 5;
  bool oyunBittiMi = false;

  //Sayıların puan değeri
  final Map<int, int> puanHaritasi = {
    1: 1, 2: 2, 3: 3, 4: 5, 5: 7, 6: 9, 7: 12, 8: 15, 9: 20
  };

  OyunMotoru() {
    oyunAlaniniBaslat();
    yeniHedefSayiUret();
    _zamanlayiciyiBaslat();
    _dusmeTimeriBaslat();
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
    oyunBittiMi = false;
    toplamPuan = 0;
    mevcutSure = 5;
    yanlisIslemSayac = 0;
    secimZinciri.clear();
    aktifDusenBloklar.clear();

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
    _zamanlayici?.cancel();
    _zamanlayici = Timer.periodic(Duration(seconds: mevcutSure), (timer) {
      if(oyunBittiMi){
        timer.cancel();
        return;
      }
      _zamanlaAsagiKaydirVeUret();
    });
  }
  void _dusmeTimeriBaslat() {
  _dusmeTimeri?.cancel();

  int dusmeHizi = 200 + (mevcutSure - 1) * 150;
  _dusmeTimeri = Timer.periodic(Duration(milliseconds: dusmeHizi), (timer) {
    if (oyunBittiMi) {
      timer.cancel();
      return;
    } 
    _bloklariAsagiKaydirSadece();
  });
}

void _bloklariAsagiKaydirSadece() {
  if (aktifDusenBloklar.isEmpty) return;
  bool degisiklikOldu = false;
  List<List<int>> yeniDusenler = [];

  for (var blokKord in aktifDusenBloklar) {
    int satir = blokKord[0];
    int sutun = blokKord[1];

    if (satir + 1 < satirSayisi && oyunAlani[satir + 1][sutun] == null) {
      oyunAlani[satir + 1][sutun] = oyunAlani[satir][sutun];
      oyunAlani[satir][sutun] = null;
      yeniDusenler.add([satir + 1, sutun]);
      degisiklikOldu = true;
    }
  }

  aktifDusenBloklar = yeniDusenler;
  if (degisiklikOldu) notifyListeners();
}
  void _sureyiGuncelle(){
    int yeniSure = 5;
    if(toplamPuan >= 400) yeniSure = 1;
    else if (toplamPuan >= 300) yeniSure = 2; 
    else if (toplamPuan >= 200) yeniSure = 3; 
    else if (toplamPuan >= 100) yeniSure = 4; 

    if(yeniSure != mevcutSure){
      mevcutSure = yeniSure;
      _zamanlayiciyiBaslat();
      _dusmeTimeriBaslat();
    }
  }

  void _zamanlaAsagiKaydirVeUret() {
  if (oyunBittiMi) return;

  if (aktifDusenBloklar.isEmpty) {
    bool tumSutunlarDolu = false;
    for (int s = 0; s < sutunSayisi; s++) {
      if (oyunAlani[0][s] != null) {
        tumSutunlarDolu = true;
        break;
      }
    }

    if (tumSutunlarDolu) {
      oyunBittiMi = true;
      _zamanlayici?.cancel();
      _dusmeTimeri?.cancel();
      notifyListeners();
      return;
    }

    int rastgeleSutun = _rastgele.nextInt(sutunSayisi);
    int rastgeleSayi = _rastgele.nextInt(9) + 1;
    oyunAlani[0][rastgeleSutun] = BlokModeli(
      number: rastgeleSayi,
      color: sayiRengiAl(rastgeleSayi),
    );
    aktifDusenBloklar.add([0, rastgeleSutun]);
    notifyListeners();
  }
} 

  bool _komsuMu(int satir1, int sutun1, int satir2, int sutun2) {
    int satirFarki = (satir1 - satir2).abs();
    int sutunFarki = (sutun1 - sutun2).abs();
    return satirFarki <= 1 && sutunFarki <= 1 && !(satirFarki == 0 && sutunFarki == 0);
  }

  void blokSec(int satir, int sutun) {
    if(oyunBittiMi) return;

    bool dusenBlokMu = aktifDusenBloklar.any((b) => b[0] == satir && b[1] == sutun);
    if (dusenBlokMu) return;
    
    BlokModeli? tiklananBlok = oyunAlani[satir][sutun];
    if (tiklananBlok == null) return;

    if (tiklananBlok.isSelected) {
      if(secimZinciri.isNotEmpty &&
         secimZinciri.last[0] == satir &&
         secimZinciri.last[1] == sutun){
        tiklananBlok.isSelected = false;
        secimZinciri.removeLast();
        notifyListeners();
        }

      return;
    }

    if (secimZinciri.length >= 4) return;

    if (secimZinciri.isNotEmpty) {
      var sonSecilen = secimZinciri.last;
      if (!_komsuMu(sonSecilen[0], sonSecilen[1], satir, sutun)) {
        return; // Komşu değilse seçtirirmez
      }
    }

    tiklananBlok.isSelected = true;
    secimZinciri.add([satir, sutun]);
    notifyListeners();
  }

  int get mevcutToplam {
    int toplam = 0;
    for (var kord in secimZinciri) {
      var blok = oyunAlani[kord[0]][kord[1]];
      if (blok != null) toplam += blok.number;
    }
    return toplam;
  }

  void _anindaAsagiKaydirVeDoldur() {
    for (int sutun = 0; sutun < sutunSayisi; sutun++) {
      for (int satir = satirSayisi - 1; satir >= 0; satir--) {
        if (oyunAlani[satir][sutun] == null) {
          for (int ustSatir = satir - 1; ustSatir >= 0; ustSatir--) {
            if (oyunAlani[ustSatir][sutun] != null) {
              bool dusenBlokMu = aktifDusenBloklar.any((b) => b[0] == ustSatir && b[1] == sutun);
              if (dusenBlokMu) continue; 

              oyunAlani[satir][sutun] = oyunAlani[ustSatir][sutun];
              oyunAlani[ustSatir][sutun] = null;
              break;
            }
          }
        }
      }

    }
  }


  void _cezaUygula() {
    for (int sutun = 0; sutun < sutunSayisi; sutun++) {
      if (oyunAlani[0][sutun] != null) {
        oyunBittiMi = true;
        _zamanlayici?.cancel();
        return;
      }
      
      int rastgeleSayi = _rastgele.nextInt(9) + 1;
      oyunAlani[0][sutun] = BlokModeli(
        number: rastgeleSayi,
        color: sayiRengiAl(rastgeleSayi),
      );
      aktifDusenBloklar.add([0, sutun]); 
    }
  }

int islemOnayla() {
    if (secimZinciri.length < 2) return 0; 

    if (mevcutToplam == hedefSayi) { 
      int hamlePuani = 0;
      for (var kord in secimZinciri) {
        int sayi = oyunAlani[kord[0]][kord[1]]!.number;
        hamlePuani += puanHaritasi[sayi] ?? 0; 
        oyunAlani[kord[0]][kord[1]] = null;
      }

      toplamPuan += hamlePuani;
      _sureyiGuncelle();

      _anindaAsagiKaydirVeDoldur(); 
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
    _dusmeTimeri?.cancel();
    super.dispose();
  }
}