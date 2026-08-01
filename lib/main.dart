import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kYesil = Color(0xFF2E7D32);
const Color kGokMavisi = Color(0xFF87CEEB);
const Color kTuruncu = Color(0xFFF57C00);
const Color kAltin = Color(0xFFFFD54F);

// TODO: Yayın öncesi gerçek rewarded reklam birimi kimliği ile değiştir!
const String kRewardedReklamId = 'ca-app-pub-3940256099942542/5224354917';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Reklam SDK'sı (test modunda)
  try {
    MobileAds.instance.initialize();
  } catch (_) {}
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(const FutbolKariyerApp());
  });
}

class FutbolKariyerApp extends StatelessWidget {
  const FutbolKariyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Futbol Kariyer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kYesil),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 20),
          bodyMedium: TextStyle(fontSize: 18),
        ),
      ),
      home: const AnaCerceve(),
    );
  }
}

enum Ekran { yukleniyor, anaMenu, ayarlar, yeniKariyer, takimSecim, sozlesme, gazete, kariyer }

// ---------------------------------------------------------------------------
// LİGLER: her ülkede 18 kurgu (lisansız) takım
// ---------------------------------------------------------------------------

const List<String> kUlkeler = <String>[
  'Türkiye', 'İngiltere', 'Almanya', 'İspanya', 'İtalya', 'Fransa',
  'Hollanda', 'Portekiz', 'Belçika', 'Brezilya', 'Arjantin',
];

const Map<String, List<String>> kLigTakimlari = <String, List<String>>{
  'Türkiye': <String>[
    'Galata SK', 'Sarı Kanaryaspor', 'Kara Kartal FK', 'Karadeniz Fırtına',
    'Başkent Yıldızı', 'Ege Efeleri', 'Akdeniz Feneri', 'Anadolu Kartalı',
    'Yeşil Timsahlar', 'Kırmızı Şimşekler', 'Mavi Yıldızspor', 'Toros Aslanları',
    'Marmara Denizcileri', 'Kapadokya Perileri', 'Çukurova Ateşi', 'Bozkır Gücü',
    'Meşale İzmir', 'Doğu Kaplanları',
  ],
  'İngiltere': <String>[
    'Londra Kralları', 'Kırmızı Şeytanlar', 'Mavi Ay FC', 'Mersey Kırmızıları',
    'Saksağan United', 'Villa Şövalyeleri', 'Kuzey Tiyatrosu', 'Thames Rovers',
    'Demir Şehir FC', 'Liman Martıları', 'Sisli Ada SK', 'Taç Giyenler',
    'Aslan Yürek FC', 'Güneş Kasabası', 'Değirmen Rovers', 'Şato United',
    'Nehir Şehri', 'Kuzey Denizcileri',
  ],
  'Almanya': <String>[
    'Berlin Kartalları', 'Ren Şimşekleri', 'Bavyera Ayıları', 'Ruhr Madencileri',
    'Elbe Denizcileri', 'Kara Orman FK', 'Oto Şehir FC', 'Bira Bahçesi SK',
    'Kale Muhafızları', 'Demir Yumruk', 'Şato Spor', 'Kuzey Yıldızları',
    'Tuna Boğaları', 'Şimşek Dresden', 'Lale Hamburg', 'Panter Stuttgart',
    'Köprü Köln', 'Zirve Münih',
  ],
  'İspanya': <String>[
    'Madrid Güneşi', 'Katalan Şahinleri', 'Endülüs Boğaları', 'Bask Fırtınası',
    'Valensiya Portakalları', 'Sevilla Ateşi', 'Akdeniz Dalga', 'Kale Duvarı',
    'Boğa Gücü FC', 'Kastilya Şövalyeleri', 'Galiçya Denizcileri', 'Flemenko SK',
    'Altın Kum FC', 'Sierra Kartalları', 'Kırmızı Pelerin', 'Yeşil Ova',
    'Taç Madrid', 'Marbella Yıldızı',
  ],
  'İtalya': <String>[
    'Roma Gladyatörleri', 'Venedik Denizcileri', 'Toskana Zeytinleri', 'Milano Duomo',
    'Napoli Volkanı', 'Torino Boğaları', 'Sicilya Korsanları', 'Floransa Laleleri',
    'Cenova Fenerleri', 'Alp Dağcıları', 'Bologna Makarna FC', 'Verona Aşıkları',
    'Parma Peynirleri', 'Sardunya Kayaları', 'Umbria Tepeleri', 'Adriyatik Dalga',
    'Kuzey Yıldızı Milano', 'Güneş Puglia',
  ],
  'Fransa': <String>[
    'Paris Horozları', 'Riviera Yıldızları', 'Lyon Aslanları', 'Marsilya Denizcileri',
    'Bordeaux Şarapları', 'Lille Kuzeylileri', 'Monako Prensleri', 'Nantes Kanaryaları',
    'Alp Dağcıları FC', 'Normandiya Elması', 'Korsika Fırtınası', 'Provans Lavantaları',
    'Eyfel Işıkları', 'Loire Şatolari', 'Breton Dalgaları', 'Şampanya Baloncukları',
    'Rennes Kurtları', 'Nice Güneşi',
  ],
  'Hollanda': <String>[
    'Amsterdam Laleleri', 'Değirmen United', 'Peynir Şehri SK', 'Rotterdam Liman',
    'Eindhoven Işıkları', 'Kanal Botları FC', 'Utrecht Katedral', 'Deniz Feneri',
    'Tulip Yıldızı', 'Delta Denizcileri', 'Kuzey Polderleri', 'Tahta Ayakkabı SK',
    'Felemenk Gücü', 'Groningen Buğdayı', 'Arnhem Köprüsü', 'Breda Kaleleri',
    'Zwolle Zirvesi', 'Maas Dalgası',
  ],
  'Portekiz': <String>[
    'Lizbon Fenerleri', 'Porto Deniz Kartalı', 'Madeira Kayaları', 'Braga Melekleri',
    'Algarve Güneşi', 'Douro Üzümleri', 'Coimbra Öğrencileri', 'Azorlar Fırtınası',
    'Yeşil Ada FC', 'Faro Kumları', 'Setubal Balıkçıları', 'Guimaraes Şövalyeleri',
    'Fado Yıldızı', 'Tejo Dalgası', 'Estoril Taçları', 'Aveiro Kanalları',
    'Beja Ovaları', 'Viana Rüzgarı',
  ],
  'Belçika': <String>[
    'Brüksel Waffle FC', 'Flaman Şövalyeleri', 'Antwerp Elmasları', 'Brugge Kanalları',
    'Gent Çanları', 'Liege Çelikleri', 'Charleroi Kömürleri', 'Leuven Üniversitesi',
    'Çikolata Şehri', 'Flanders Aslanı', 'Mechelen Kedileri', 'Oostende Denizcileri',
    'Arden Ormanı', 'Kortrijk Ketenleri', 'Genk Madencileri', 'Aalst Soğanları',
    'Sint Niklaas', 'Wavre Tepeleri',
  ],
  'Brezilya': <String>[
    'Rio Samba Spor', 'Amazon Pumaları', 'Sao Paulo Yıldırım', 'Bahia Güneşi',
    'Pantanal Jaguarları', 'Minas Altınları', 'Gaucho Kovboyları', 'Karnaval FC',
    'Copacabana Dalgası', 'Iguazu Şelaleleri', 'Cerrado Rüzgarı', 'Noronha Kaplumbağaları',
    'Recife Resifleri', 'Fortaleza Kaleleri', 'Manaus Nehirleri', 'Curitiba Çamları',
    'Santos Kumları', 'Brasilia Taçları',
  ],
  'Arjantin': <String>[
    'Buenos Tango FC', 'Pampa Kovboyları', 'And Kondorları', 'Rosario Gülleri',
    'Cordoba Sierrası', 'Mendoza Üzümleri', 'Patagonya Rüzgarı', 'La Plata Gümüşleri',
    'Mar del Plata Dalgası', 'Salta Vadileri', 'Tucuman Şekerleri', 'Neuquen Kayaları',
    'Santa Fe Trenleri', 'Parana Nehirleri', 'Ushuaia Buzulları', 'Bariloche Gölleri',
    'Jujuy Renkleri', 'Bahia Fenerleri',
  ],
};

// Takım renk paleti (index'e göre otomatik atanır)
const List<int> kTakimRenk1 = <int>[
  0xFFD32F2F, 0xFF1565C0, 0xFFF9A825, 0xFF2E7D32, 0xFF6A1B9A, 0xFF00838F,
  0xFF37474F, 0xFFE65100, 0xFFAD1457, 0xFF455A64, 0xFF0277BD, 0xFF33691E,
  0xFF5D4037, 0xFF283593, 0xFF8E0000, 0xFFEF6C00, 0xFF1B5E20, 0xFF00695C,
];
const List<int> kTakimRenk2 = <int>[
  0xFFFFFFFF, 0xFFFFD54F, 0xFF212121, 0xFFFFFFFF, 0xFFFFD54F, 0xFFFFFFFF,
  0xFFF9A825, 0xFF212121, 0xFFF9A825, 0xFFFFD54F, 0xFFFFFFFF, 0xFFFFF176,
  0xFFFFB300, 0xFFFFFFFF, 0xFFFFD54F, 0xFF212121, 0xFF8D6E63, 0xFFFFFFFF,
];

class TakimBilgi {
  final String ulke;
  final String ad;
  final int renk1;
  final int renk2;
  final int index;
  const TakimBilgi(this.ulke, this.ad, this.renk1, this.renk2, this.index);
}

List<TakimBilgi> ligTakimlari(String ulke) {
  final List<String> adlar = kLigTakimlari[ulke] ?? kLigTakimlari['Türkiye']!;
  return <TakimBilgi>[
    for (int i = 0; i < adlar.length; i++)
      TakimBilgi(ulke, adlar[i], kTakimRenk1[i % kTakimRenk1.length], kTakimRenk2[i % kTakimRenk2.length], i),
  ];
}

TakimBilgi takimBul(String ad) {
  for (final String u in kUlkeler) {
    final List<TakimBilgi> l = ligTakimlari(u);
    for (final TakimBilgi t in l) {
      if (t.ad == ad) return t;
    }
  }
  return ligTakimlari('Türkiye')[0];
}

// Ülkelere göre oyuncu isimleri
const Map<String, List<String>> kOyuncuIsimleri = <String, List<String>>{
  'Türkiye': <String>['Kayra', 'Ahmet', 'Ali', 'Mehmet', 'Emir', 'Yusuf', 'Ömer', 'Miraç', 'Eymen', 'Kerem', 'Aras', 'Alp', 'Cem', 'Deniz', 'Efe', 'Kaan', 'Mert', 'Umut', 'Baran', 'Doruk', 'Rüzgar', 'Toprak'],
  'İngiltere': <String>['James', 'Harry', 'Jack', 'Oliver', 'Charlie', 'George', 'Alfie', 'Leo', 'Oscar', 'Henry', 'Archie', 'Joshua', 'Ethan', 'Freddie', 'Jacob', 'Logan', 'Thomas', 'Daniel', 'Sam', 'Max', 'Teddy', 'Arthur'],
  'Almanya': <String>['Leon', 'Ben', 'Paul', 'Finn', 'Lukas', 'Jonas', 'Felix', 'Maximilian', 'Elias', 'Noah', 'Emil', 'Moritz', 'Henry', 'Oskar', 'Anton', 'Theo', 'Jakob', 'Liam', 'David', 'Tom', 'Karl', 'Bruno'],
  'İspanya': <String>['Hugo', 'Mateo', 'Leo', 'Pablo', 'Daniel', 'Alejandro', 'Alvaro', 'Adrian', 'Enzo', 'Lucas', 'Diego', 'Marco', 'Iker', 'Sergio', 'Carlos', 'Javier', 'Miguel', 'Rafael', 'Bruno', 'Izan', 'Thiago', 'Gael'],
  'İtalya': <String>['Leonardo', 'Francesco', 'Alessandro', 'Lorenzo', 'Mattia', 'Andrea', 'Gabriele', 'Riccardo', 'Tommaso', 'Edoardo', 'Marco', 'Giovanni', 'Luca', 'Nicola', 'Simone', 'Stefano', 'Paolo', 'Diego', 'Enzo', 'Giacomo', 'Pietro', 'Samuele'],
  'Fransa': <String>['Gabriel', 'Louis', 'Raphael', 'Jules', 'Adam', 'Arthur', 'Lucas', 'Hugo', 'Leo', 'Ethan', 'Nathan', 'Theo', 'Enzo', 'Noah', 'Mathis', 'Axel', 'Antoine', 'Clement', 'Maxime', 'Olivier', 'Pierre', 'Victor'],
  'Hollanda': <String>['Daan', 'Sem', 'Lucas', 'Milan', 'Levi', 'Luuk', 'Thijs', 'Bram', 'Finn', 'Jesse', 'Noah', 'Ruben', 'Stijn', 'Timo', 'Lars', 'Jens', 'Pim', 'Guus', 'Floris', 'Sven', 'Wout', 'Joep'],
  'Portekiz': <String>['Joao', 'Tiago', 'Diogo', 'Rui', 'Andre', 'Bruno', 'Carlos', 'Miguel', 'Pedro', 'Ricardo', 'Goncalo', 'Rafael', 'Afonso', 'Duarte', 'Tomas', 'Martim', 'Lourenco', 'Vicente', 'Rodrigo', 'Francisco', 'Santiago', 'Dinis'],
  'Belçika': <String>['Arthur', 'Noah', 'Liam', 'Louis', 'Jules', 'Adam', 'Victor', 'Lucas', 'Leon', 'Finn', 'Emiel', 'Vince', 'Wout', 'Arne', 'Thibaut', 'Kevin', 'Eden', 'Romelu', 'Dries', 'Yannick', 'Michy', 'Axel'],
  'Brezilya': <String>['Miguel', 'Arthur', 'Gael', 'Théo', 'Heitor', 'Ravi', 'Davi', 'Bernardo', 'Gabriel', 'Pedro', 'Lucas', 'Matheus', 'Rafael', 'Guilherme', 'Enzo', 'Nicolas', 'João', 'Felipe', 'Bruno', 'Vinicius', 'Rodrigo', 'Caio'],
  'Arjantin': <String>['Mateo', 'Bautista', 'Juan', 'Felipe', 'Bruno', 'Noah', 'Benicio', 'Thiago', 'Lorenzo', 'Benjamin', 'Joaquin', 'Valentino', 'Santino', 'Francisco', 'Facundo', 'Agustin', 'Ignacio', 'Santiago', 'Lautaro', 'Julian', 'Emiliano', 'Gonzalo'],
};

// Menajer isimleri (rastgele, cinsiyetli)
const List<List<String>> kMenajerler = <List<String>>[
  <String>['Ayşe Yılmaz', 'Kadın'],
  <String>['Murat Demir', 'Erkek'],
  <String>['Elif Kaya', 'Kadın'],
  <String>['Carlos Mendes', 'Erkek'],
  <String>['Sofia Rossi', 'Kadın'],
  <String>['Hans Weber', 'Erkek'],
  <String>['Zeynep Arslan', 'Kadın'],
  <String>['Pierre Dubois', 'Erkek'],
];

// Özellik kategorileri
const Map<String, List<List<String>>> kOzellikler = <String, List<List<String>>>{
  'Hücum': <List<String>>[
    <String>['sut', 'Şut'],
    <String>['pas', 'Pas'],
    <String>['bit', 'Bitiricilik'],
  ],
  'Hız': <List<String>>[
    <String>['dep', 'Depar'],
    <String>['hiz', 'Hızlanma'],
  ],
  'Dayanıklılık': <List<String>>[
    <String>['day', 'Dayanıklılık'],
    <String>['kuv', 'Kuvvet'],
    <String>['zip', 'Zıplama'],
  ],
};

// Krampon mağazası (lisansız kurgu markalar)
const List<Map<String, dynamic>> kKramponMagaza = <Map<String, dynamic>>[
  <String, dynamic>{'ad': 'Speedo Blitz', 'renk': 0xFFD32F2F, 'fiyat': 60, 'guc': 2},
  <String, dynamic>{'ad': 'Turbo Kanat', 'renk': 0xFF1565C0, 'fiyat': 120, 'guc': 4},
  <String, dynamic>{'ad': 'Panter Pençe', 'renk': 0xFF212121, 'fiyat': 200, 'guc': 6},
  <String, dynamic>{'ad': 'Yıldırım Pro', 'renk': 0xFFF9A825, 'fiyat': 320, 'guc': 9},
  <String, dynamic>{'ad': 'Kobra Strike', 'renk': 0xFF2E7D32, 'fiyat': 480, 'guc': 12},
  <String, dynamic>{'ad': 'Altın Şimşek', 'renk': 0xFFFFB300, 'fiyat': 700, 'guc': 16},
  <String, dynamic>{'ad': 'Galaksi X', 'renk': 0xFF6A1B9A, 'fiyat': 1000, 'guc': 21},
  <String, dynamic>{'ad': 'Efsane 99', 'renk': 0xFF00838F, 'fiyat': 1500, 'guc': 27},
];

// ---------------------------------------------------------------------------

class AnaCerceve extends StatefulWidget {
  const AnaCerceve({super.key});

  @override
  State<AnaCerceve> createState() => _AnaCerceveState();
}

class _AnaCerceveState extends State<AnaCerceve> {
  Ekran ekran = Ekran.yukleniyor;
  bool splashGosterildi = false;
  SharedPreferences? prefs;
  Map<String, dynamic>? kariyer;
  Map<String, dynamic> ayarlar = <String, dynamic>{
    'zorluk': 'Orta',
    'ses': 0.5,
    'titresim': true,
  };

  String formAd = '';
  String formSoyad = '';
  String formUlke = 'Türkiye';
  String formTakim = '';

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    prefs = await SharedPreferences.getInstance();
    try {
      final String? c = prefs!.getString('career');
      if (c != null) {
        final Map<String, dynamic> k = Map<String, dynamic>.from(jsonDecode(c) as Map<dynamic, dynamic>);
        // Eski/uyumsuz kayıt kontrolü: v2 şeması yoksa temiz başlat
        if (k['v'] == 2 && k['ozellikler'] is Map && k['fikstur'] is List) {
          // Takım arkadaşları eksik/bozuksa 10 kişiye tamamla (yeniKariyerOlustur mantığı)
          final List<dynamic> mevcutArkadaslar = (k['arkadaslar'] is List) ? List<dynamic>.from(k['arkadaslar'] as List) : <dynamic>[];
          if (mevcutArkadaslar.length < 10) {
            final Random rr = Random();
            final String ulke = (k['ulke'] ?? 'Türkiye') as String;
            final List<String> isimler = List<String>.from(kOyuncuIsimleri[ulke] ?? kOyuncuIsimleri['Türkiye']!);
            isimler.shuffle(rr);
            for (final String isim in isimler) {
              if (mevcutArkadaslar.length >= 10) break;
              if (!mevcutArkadaslar.contains(isim)) mevcutArkadaslar.add(isim);
            }
            k['arkadaslar'] = mevcutArkadaslar;
          }
          kariyer = k;
        }
      }
    } catch (_) {
      kariyer = null;
    }
    try {
      final String? s = prefs!.getString('settings');
      if (s != null) {
        final Map<String, dynamic> a = Map<String, dynamic>.from(jsonDecode(s) as Map<dynamic, dynamic>);
        // Şema doğrulaması: bozuksa varsayılan ayarlar korunur
        if (a['zorluk'] is String && a['ses'] is num) {
          ayarlar = a;
        }
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> kariyerKaydet() async {
    if (prefs == null) return;
    if (kariyer != null) {
      await prefs!.setString('career', jsonEncode(kariyer));
    } else {
      await prefs!.remove('career');
    }
  }

  Future<void> ayarlarKaydet() async {
    if (prefs == null) return;
    await prefs!.setString('settings', jsonEncode(ayarlar));
  }

  void git(Ekran e) {
    setState(() => ekran = e);
  }

  @override
  Widget build(BuildContext context) {
    Widget govde;
    switch (ekran) {
      case Ekran.yukleniyor:
        if (!splashGosterildi) {
          govde = CeaSplashEkrani(bitir: () => setState(() => splashGosterildi = true));
        } else {
          govde = YukleniyorEkrani(bitir: () => git(Ekran.anaMenu));
        }
        break;
      case Ekran.anaMenu:
        govde = AnaMenuEkrani(kariyer: kariyer, git: git);
        break;
      case Ekran.ayarlar:
        govde = AyarlarEkrani(
          ayarlar: ayarlar,
          kaydet: ayarlarKaydet,
          geri: () => git(Ekran.anaMenu),
          sifirla: () {
            setState(() => kariyer = null);
            kariyerKaydet();
          },
          degisti: () => setState(() {}),
        );
        break;
      case Ekran.yeniKariyer:
        govde = YeniKariyerEkrani(
          git: git,
          formAd: formAd,
          formSoyad: formSoyad,
          formUlke: formUlke,
          degisti: (String ad, String soyad, String ulke) {
            formAd = ad;
            formSoyad = soyad;
            formUlke = ulke;
          },
        );
        break;
      case Ekran.takimSecim:
        govde = TakimSecimEkrani(
          ulke: formUlke,
          geri: () => git(Ekran.yeniKariyer),
          secti: (String takim) {
            formTakim = takim;
            git(Ekran.sozlesme);
          },
        );
        break;
      case Ekran.sozlesme:
        govde = SozlesmeEkrani(
          ad: formAd,
          soyad: formSoyad,
          takim: formTakim,
          geri: () => git(Ekran.takimSecim),
          imzaladi: () => git(Ekran.gazete),
        );
        break;
      case Ekran.gazete:
        govde = GazeteEkrani(
          ad: formAd,
          soyad: formSoyad,
          takim: formTakim,
          basla: () {
            setState(() {
              kariyer = yeniKariyerOlustur(formAd, formSoyad, formUlke, formTakim);
            });
            kariyerKaydet();
            git(Ekran.kariyer);
          },
        );
        break;
      case Ekran.kariyer:
        govde = KariyerEkrani(
          kariyer: kariyer!,
          ayarlar: ayarlar,
          kaydet: kariyerKaydet,
          anaMenu: () => git(Ekran.anaMenu),
          degisti: () => setState(() {}),
        );
        break;
    }
    return Scaffold(body: SafeArea(child: govde));
  }
}

// ---------- Kariyer oluşturma ----------

Map<String, dynamic> yeniKariyerOlustur(String ad, String soyad, String ulke, String takim) {
  final Random r = Random();
  final List<TakimBilgi> lig = ligTakimlari(ulke);
  int benimIndex = lig.indexWhere((TakimBilgi t) => t.ad == takim);
  if (benimIndex < 0) benimIndex = 0; // Takım bulunamazsa güvenli varsayılan
  // 34 haftalık fikstür (her takımla 2 kez)
  final List<int> rakipler = <int>[for (int i = 0; i < lig.length; i++) if (i != benimIndex) i];
  rakipler.shuffle(r);
  final List<int> ilkYari = List<int>.from(rakipler);
  rakipler.shuffle(r);
  final List<int> fikstur = <int>[...ilkYari, ...rakipler];
  // Özellikler: 58-65 rastgele taban
  final Map<String, dynamic> oz = <String, dynamic>{};
  kOzellikler.forEach((String kat, List<List<String>> liste) {
    for (final List<String> o in liste) {
      oz[o[0]] = <String, dynamic>{'t': 58 + r.nextInt(8), 'e': 0};
    }
  });
  // Takım arkadaşları (kariyer boyu sabit 10 isim)
  final List<String> isimler = List<String>.from(kOyuncuIsimleri[ulke] ?? kOyuncuIsimleri['Türkiye']!);
  isimler.shuffle(r);
  final List<String> arkadaslar = isimler.take(10).toList();
  final List<String> menajer = kMenajerler[r.nextInt(kMenajerler.length)];
  // Puan tablosu
  final List<Map<String, dynamic>> tablo = <Map<String, dynamic>>[
    for (int i = 0; i < lig.length; i++)
      <String, dynamic>{'i': i, 'p': 0, 'g': 0, 'b': 0, 'm': 0, 'ag': 0, 'yg': 0},
  ];
  return <String, dynamic>{
    'v': 2,
    'ad': ad,
    'soyad': soyad,
    'ulke': ulke,
    'lig': '$ulke 3. Ligi',
    'takim': takim,
    'sezon': 1,
    'hafta': 1,
    'gun': 1,
    'yas': 18,
    'formaNo': 99,
    'gol': 0,
    'asist': 0,
    'macSayisi': 0,
    'sezonGol': 0,
    'sezonAsist': 0,
    'sezonMac': 0,
    'ilk11Mac': 0,
    'ratingGecmisi': <double>[],
    'altin': 50,
    'antPuani': 0,
    'ozellikler': oz,
    'kramponlar': <int>[],
    'aktifKrampon': -1,
    'arkadaslar': arkadaslar,
    'menajerAd': menajer[0],
    'menajerCinsiyet': menajer[1],
    'fikstur': fikstur,
    'tablo': tablo,
    'mesajlar': <Map<String, dynamic>>[
      <String, dynamic>{
        'kimden': menajer[0],
        'kim': 'Menajer',
        'metin': 'Merhaba $ad! Ben senin menajerin ${menajer[0]}. Birlikte harika bir kariyer yapacağız! 💪',
        'tip': 'normal',
        'okundu': false,
      },
      <String, dynamic>{
        'kimden': 'Teknik Direktör',
        'kim': 'Teknik Direktör',
        'metin': 'Takıma hoş geldin $ad! Antrenmanlarda kendini göster, ilk 11 seni bekliyor.',
        'tip': 'td',
        'okundu': false,
      },
    ],
    'bildirimler': <Map<String, dynamic>>[
      <String, dynamic>{'metin': '🎉 $takim ile sözleşme imzaladın! Yeni maceran başlıyor.', 'tip': 'haber', 'okundu': false},
    ],
    'antHafta': 0,
    'carkTarih': '',
    'carkSayi': 0,
    'teklifVerildi': false,
    'teklifler': <Map<String, dynamic>>[],
    'transferTakim': '',
  };
}

// ---------- Ortak yardımcılar ----------

String takimEk(String takim) {
  final String s = takim.toLowerCase();
  const String sertler = 'fhstkçşp';
  final RegExp harfler = RegExp(r'[a-zçğıöşü]');
  String sonHarf = '';
  for (int i = s.length - 1; i >= 0; i--) {
    if (harfler.hasMatch(s[i])) {
      sonHarf = s[i];
      break;
    }
  }
  final bool sert = sertler.contains(sonHarf);
  final RegExp unluler = RegExp(r'[aeıioöuü]');
  String sonUnlu = '';
  for (int i = s.length - 1; i >= 0; i--) {
    if (unluler.hasMatch(s[i])) {
      sonUnlu = s[i];
      break;
    }
  }
  final bool ince = 'eiöü'.contains(sonUnlu);
  if (sert) return ince ? "'te" : "'ta";
  return ince ? "'de" : "'da";
}

String basHarfler(String takim) {
  final List<String> parcalar = takim.split(' ');
  if (parcalar.length == 1) {
    return takim.substring(0, min(2, takim.length)).toUpperCase();
  }
  String s = '';
  for (final String p in parcalar) {
    if (p.isNotEmpty && s.length < 2) s += p[0];
  }
  return s.toUpperCase();
}

// Kariyer map okuma yardımcıları (tip güvenli)
String kStr(Map<String, dynamic> k, String anahtar, [String d = '']) => (k[anahtar] ?? d) as String;
int kInt(Map<String, dynamic> k, String anahtar, [int d = 0]) => ((k[anahtar] ?? d) as num).toInt();
List<dynamic> kListe(Map<String, dynamic> k, String anahtar) => (k[anahtar] ?? <dynamic>[]) as List<dynamic>;

int ozellik(Map<String, dynamic> k, String kod) {
  final Map<String, dynamic> oz = Map<String, dynamic>.from((k['ozellikler'] ?? <String, dynamic>{}) as Map<dynamic, dynamic>);
  final Map<String, dynamic> o = Map<String, dynamic>.from((oz[kod] ?? <String, dynamic>{'t': 60, 'e': 0}) as Map<dynamic, dynamic>);
  return ((o['t'] ?? 60) as num).toInt() + ((o['e'] ?? 0) as num).toInt();
}

int kramponGucu(Map<String, dynamic> k) {
  final int aktif = kInt(k, 'aktifKrampon', -1);
  if (aktif < 0 || aktif >= kKramponMagaza.length) return 0;
  return (kKramponMagaza[aktif]['guc'] as num).toInt();
}

double ortalamaRating(Map<String, dynamic> k) {
  final List<dynamic> g = kListe(k, 'ratingGecmisi');
  if (g.isEmpty) return 6.0;
  double t = 0;
  for (final dynamic e in g) {
    t += e is num ? (e as num).toDouble() : 6.0;
  }
  return t / g.length;
}

// Takım rozeti: CustomPainter ile kalkan
class RozetPainter extends CustomPainter {
  final Color renk1;
  final Color renk2;
  final String harfler;

  RozetPainter(this.renk1, this.renk2, this.harfler);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Path kalkan = Path()
      ..moveTo(w * 0.5, h * 0.98)
      ..lineTo(w * 0.05, h * 0.55)
      ..lineTo(w * 0.05, h * 0.05)
      ..lineTo(w * 0.95, h * 0.05)
      ..lineTo(w * 0.95, h * 0.55)
      ..close();
    canvas.drawPath(kalkan, Paint()..color = renk1);
    final Path serit = Path()
      ..moveTo(w * 0.35, h * 0.05)
      ..lineTo(w * 0.65, h * 0.05)
      ..lineTo(w * 0.65, h * 0.75)
      ..lineTo(w * 0.5, h * 0.9)
      ..lineTo(w * 0.35, h * 0.75)
      ..close();
    canvas.drawPath(serit, Paint()..color = renk2);
    canvas.drawPath(
      kalkan,
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: harfler,
        style: TextStyle(
          color: renk1.computeLuminance() > 0.5 ? Colors.black : Colors.white,
          fontSize: h * 0.28,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w * 0.5 - tp.width / 2, h * 0.32 - tp.height / 2));
    canvas.drawCircle(Offset(w * 0.5, h * 0.72), h * 0.09, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.72),
      h * 0.09,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget rozet(String takimAd, double boyut) {
  final TakimBilgi t = takimBul(takimAd);
  return SizedBox(
    width: boyut,
    height: boyut,
    child: CustomPaint(painter: RozetPainter(Color(t.renk1), Color(t.renk2), basHarfler(t.ad))),
  );
}

Widget buyukButon({required String yazi, required VoidCallback onPressed, Color? renk}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: renk ?? kTuruncu,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onPressed,
      child: Text(yazi),
    ),
  );
}

Widget sahaArkaplan({required Widget child}) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[kGokMavisi, Color(0xFFB3E5FC), kYesil],
        stops: <double>[0.0, 0.55, 1.0],
      ),
    ),
    child: child,
  );
}

// Alt ekran çatısı: başlık + ✕ kapatma
Widget altEkran({required String baslik, required Widget child, Color? arkaplan}) {
  return Builder(
    builder: (BuildContext context) {
      return Scaffold(
        backgroundColor: arkaplan ?? const Color(0xFFE8F5E9),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Container(
                color: kYesil,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: <Widget>[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(baslik, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 32),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      );
    },
  );
}

// ---------- Gercek resim varliklari (assets/) ----------
// Yuklenemeyen resim null kalir: o durumda mevcut kod-cizim fallback devreye girer.
class Resimler {
  static ui.Image? saha; // saha_zemin.jpg (artik mac ekraninda kullanilmiyor)
  static ui.Image? sahaDikey; // saha_dikey.jpg (mac zemini: kale ustte, dikey foto)
  static ui.Image? splash; // splash_stadyum.jpg
  static ui.Image? top; // top.png
  static ui.Image? kaleci; // kaleci.png
  static ui.Image? kirmizi1; // oyuncu_kirmizi_1.png
  static ui.Image? kirmizi2; // oyuncu_kirmizi_2.png
  static ui.Image? mavi1; // oyuncu_mavi_1.png
  static ui.Image? mavi2; // oyuncu_mavi_2.png
  static bool _basladi = false;

  static Future<ui.Image?> _tek(String yol) async {
    try {
      final ByteData veri = await rootBundle.load(yol);
      final ui.Codec codec = await ui.instantiateImageCodec(veri.buffer.asUint8List());
      final ui.FrameInfo kare = await codec.getNextFrame();
      return kare.image;
    } catch (_) {
      return null; // fallback: kod-cizim
    }
  }

  static Future<void> yukle() {
    if (_basladi) return Future<void>.value();
    _basladi = true;
    return Future.wait(<Future<void>>[
      _tek('assets/saha_zemin.jpg').then((ui.Image? i) => saha = i),
      _tek('assets/saha_dikey.jpg').then((ui.Image? i) => sahaDikey = i),
      _tek('assets/splash_stadyum.jpg').then((ui.Image? i) => splash = i),
      _tek('assets/top.png').then((ui.Image? i) => top = i),
      _tek('assets/kaleci.png').then((ui.Image? i) => kaleci = i),
      _tek('assets/oyuncu_kirmizi_1.png').then((ui.Image? i) => kirmizi1 = i),
      _tek('assets/oyuncu_kirmizi_2.png').then((ui.Image? i) => kirmizi2 = i),
      _tek('assets/oyuncu_mavi_1.png').then((ui.Image? i) => mavi1 = i),
      _tek('assets/oyuncu_mavi_2.png').then((ui.Image? i) => mavi2 = i),
    ]);
  }
}

// BoxFit.cover mantigi: dst oranina gore kaynak dikdortgeni kirpilir.
// yBas/ySon: kaynak dikey araligi sinirlar (or. cim bolgesine agirlik vermek icin),
// alt kenara sabitlenir (cim altta kalsin).
Rect coverKaynak(ui.Image img, Rect dst, {double yBas = 0.0, double ySon = 1.0}) {
  final double iw = img.width.toDouble();
  final double ih = img.height.toDouble();
  final double ry0 = (ih * yBas).clamp(0.0, ih - 1);
  final double ry1 = (ih * ySon).clamp(ry0 + 1, ih);
  final double rh = ry1 - ry0;
  final double hedefOran = dst.width / dst.height;
  double sw = iw;
  double sh = rh;
  if (iw / rh > hedefOran) {
    sw = rh * hedefOran; // yataydan kirp
  } else {
    sh = iw / hedefOran; // dikeyden kirp
    if (sh > rh) sh = rh;
  }
  final double x0 = (iw - sw) / 2;
  double yy0 = ry1 - sh;
  if (yy0 < ry0) yy0 = ry0;
  if (yy0 + sh > ry1) sh = ry1 - yy0;
  return Rect.fromLTRB(x0, yy0, x0 + sw, yy0 + sh);
}

// ---------- CEA GAMES açılış imza ekranı ----------

class CeaSplashEkrani extends StatefulWidget {
  final VoidCallback bitir;
  const CeaSplashEkrani({super.key, required this.bitir});

  @override
  State<CeaSplashEkrani> createState() => _CeaSplashEkraniState();
}

class _CeaSplashEkraniState extends State<CeaSplashEkrani> with SingleTickerProviderStateMixin {
  late final AnimationController kontrol;
  bool bittiMi = false;

  @override
  void initState() {
    super.initState();
    kontrol = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    kontrol.addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed) bitis();
    });
    kontrol.forward();
    // Gercek resim varliklari: async yukle, yuklenince yeniden ciz
    Resimler.yukle().then((_) {
      if (mounted) setState(() {});
    });
  }

  void bitis() {
    if (bittiMi) return;
    bittiMi = true;
    widget.bitir();
  }

  @override
  void dispose() {
    kontrol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: bitis, // dokununca atla
      child: Container(
        color: Colors.black,
        child: AnimatedBuilder(
          animation: kontrol,
          builder: (BuildContext context, Widget? child) {
            final double t = kontrol.value;
            // Son ~0.4 sn: tum sahne yukari kayarak acilir
            final double kayma = Curves.easeInCubic.transform(((t - 0.865) / 0.135).clamp(0.0, 1.0));
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints cons) {
                return Transform.translate(
                  offset: Offset(0, -cons.maxHeight * kayma),
                  child: Opacity(
                    opacity: 1.0 - kayma * 0.4,
                    child: SizedBox.expand(child: CustomPaint(painter: SplashPainter(t, Resimler.splash))),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// Gece stadyumu: projektor huzmeleri + isik zerrecikleri + falsolu gelip seken top
// + harf harf elastik dusen metalik "CEA GAMES" logosu
class SplashPainter extends CustomPainter {
  final double t;
  final ui.Image? zemin; // splash_stadyum.jpg (null ise kod-cizim fallback)
  SplashPainter(this.t, [this.zemin]);

  static const String logo = 'CEA GAMES';

  void besgen(Canvas canvas, Offset c, double r, double rot, Paint p) {
    final Path yol = Path();
    for (int i = 0; i < 5; i++) {
      final double a = rot - pi / 2 + i * 2 * pi / 5;
      final Offset n = c + Offset(cos(a) * r, sin(a) * r);
      if (i == 0) {
        yol.moveTo(n.dx, n.dy);
      } else {
        yol.lineTo(n.dx, n.dy);
      }
    }
    yol.close();
    canvas.drawPath(yol, p);
  }

  // Besgen desenli futbol topu (squash destekli)
  void topCiz(Canvas canvas, Offset c, double r, double rot, double squash) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(1.0 + squash * 0.25, 1.0 - squash * 0.30);
    final Paint beyaz = Paint()..color = Colors.white;
    canvas.drawCircle(Offset.zero, r, beyaz);
    canvas.drawCircle(Offset.zero, r, Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0);
    final Paint siyah = Paint()..color = Colors.black87;
    besgen(canvas, Offset.zero, r * 0.34, rot, siyah);
    for (int i = 0; i < 5; i++) {
      final double a = rot - pi / 2 + i * 2 * pi / 5;
      final Offset d = Offset(cos(a) * r * 0.80, sin(a) * r * 0.80);
      besgen(canvas, d, r * 0.22, rot + pi / 5, siyah);
      canvas.drawLine(Offset(cos(a) * r * 0.34, sin(a) * r * 0.34), d, Paint()
        ..color = Colors.black54
        ..strokeWidth = 1.2);
    }
    // parlama
    canvas.drawCircle(Offset(-r * 0.35, -r * 0.4), r * 0.22, Paint()..color = Colors.white.withOpacity(0.5));
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double ufuk = h * 0.72; // cim ufuk cizgisi

    if (zemin != null) {
      // --- Gercek stadyum fotografi: tam ekran cover ---
      final Rect tam = Rect.fromLTWH(0, 0, w, h);
      canvas.drawRect(tam, Paint()..color = Colors.black);
      canvas.drawImageRect(zemin!, coverKaynak(zemin!, tam), tam, Paint()..filterQuality = FilterQuality.medium);
      // Harfler resmin ustunde okunabilsin diye hafif karartma
      canvas.drawRect(tam, Paint()..color = Colors.black.withOpacity(0.22));
    } else {
      // --- Gece gokyuzu: ustte koyu lacivert, ufukta hafif aydinlik ---
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF02060F), Color(0xFF071224), Color(0xFF0B1E33)],
            stops: <double>[0.0, 0.55, 0.72],
          ).createShader(Rect.fromLTWH(0, 0, w, h)),
      );
      // --- Cim zemini: ufuk cizgisinden asagiya yesil gradyan ---
      canvas.drawRect(
        Rect.fromLTWH(0, ufuk, w, h - ufuk),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF14380F)],
          ).createShader(Rect.fromLTWH(0, ufuk, w, h - ufuk)),
      );
      // Ufuk isik hatti
      canvas.drawRect(Rect.fromLTWH(0, ufuk - 1, w, 2), Paint()..color = const Color(0xFF66BB6A).withOpacity(0.5));
    }

    // --- 4 projektor huzmesi (hafif salinir, yarim seffaf beyaz-altin koniler) ---
    final double isik = (t / 0.18).clamp(0.0, 1.0);
    for (int i = 0; i < 4; i++) {
      final double cx = w * (0.14 + i * 0.24);
      final double salin = sin(t * 6.0 + i * 1.9) * w * 0.02;
      final Path huzme = Path()
        ..moveTo(cx - 10, 0)
        ..lineTo(cx + 10, 0)
        ..lineTo(cx + salin + w * 0.17, ufuk)
        ..lineTo(cx + salin - w * 0.17, ufuk)
        ..close();
      canvas.drawPath(huzme, Paint()..color = const Color(0xFFFFF8E1).withOpacity(0.10 * isik));
      canvas.drawPath(huzme, Paint()..color = kAltin.withOpacity(0.06 * isik));
      // projektor basligi
      canvas.drawCircle(Offset(cx, 4), 5, Paint()..color = const Color(0xFFFFFDE7).withOpacity(0.9 * isik));
      // zeminde isik havuzu
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + salin, ufuk + 8), width: w * 0.30, height: 18),
        Paint()..color = kAltin.withOpacity(0.08 * isik),
      );
    }

    // --- Havada isik zerrecikleri (toz parcaciklari) ---
    for (int i = 0; i < 48; i++) {
      final double bx = ((i * 173) % 983) / 983;
      final double by = ((i * 389) % 977) / 977;
      final double kay = sin(t * 4 + i * 1.3) * 10 + t * 14;
      final double pOp = (0.25 + 0.55 * (0.5 + 0.5 * sin(t * 9 + i * 2.1))) * isik;
      canvas.drawCircle(
        Offset(bx * w + kay, by * ufuk * 0.95 + cos(t * 3 + i) * 6),
        0.9 + (i % 3) * 0.5,
        Paint()..color = const Color(0xFFFFF9C4).withOpacity(pOp),
      );
    }

    // --- Falsolu gelip seken futbol topu ---
    final double giris = ((t - 0.06) / 0.44).clamp(0.0, 1.0); // ucus
    final double sekme = ((t - 0.50) / 0.22).clamp(0.0, 1.0); // sekme+durus
    final Offset durmaNokta = Offset(w * 0.5, h * 0.60);
    double squash = 0;
    double rot = 0;
    Offset topP;
    if (giris < 1.0) {
      final double e = Curves.easeOut.transform(giris);
      // falsolu parabol: soldan girip hafif kavisle merkeze iner
      final double x = aralD(-w * 0.12, durmaNokta.dx, e);
      final double y = aralD(h * 0.30, durmaNokta.dy, e) - sin(pi * giris) * h * 0.16;
      topP = Offset(x, y + sin(giris * 2 * pi) * 10 * (1 - e)); // falso salinimi
      rot = giris * 9.0;
    } else {
      // iki kucuk sekme + squash
      final double s1 = sin(pi * sekme.clamp(0.0, 1.0));
      final double yukseklik = s1 * (1 - sekme) * 26;
      topP = durmaNokta - Offset(0, yukseklik);
      squash = (sekme < 0.10 || (sekme > 0.42 && sekme < 0.52)) ? 1.0 : (yukseklik < 2 ? 0.4 : 0.0);
      rot = 9.0 + sekme * 1.5;
    }
    if (giris > 0) {
      // top golgesi
      final double golgeK = giris < 1.0 ? (0.5 + 0.5 * giris) : 1.0;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(topP.dx, durmaNokta.dy + 20), width: 40 * golgeK, height: 9 * golgeK),
        Paint()..color = Colors.black.withOpacity(0.35 * golgeK),
      );
      topCiz(canvas, topP, 26, rot, squash);
    }

    // --- Topun durdugu yerden altin isik dalgasi ---
    final double dalga = ((t - 0.52) / 0.30).clamp(0.0, 1.0);
    if (dalga > 0 && dalga < 1) {
      final double rr = dalga * w * 0.75;
      canvas.drawCircle(
        durmaNokta + const Offset(0, 16),
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * (1 - dalga) + 1
          ..color = kAltin.withOpacity(0.55 * (1 - dalga)),
      );
      canvas.drawCircle(
        durmaNokta + const Offset(0, 16),
        rr * 0.7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFFFF8E1).withOpacity(0.35 * (1 - dalga)),
      );
    }

    // --- "CEA GAMES" harfleri tek tek yukardan elastik duser ---
    const double harfBoyut = 46;
    final List<TextPainter> harfler = <TextPainter>[];
    double toplam = 0;
    for (int i = 0; i < logo.length; i++) {
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: logo[i],
          style: const TextStyle(fontSize: harfBoyut, fontWeight: FontWeight.w900, letterSpacing: 2, color: kAltin),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      harfler.add(tp);
      toplam += tp.width + 3;
    }
    toplam -= 3;
    double hx = (w - toplam) / 2;
    final double tabanY = h * 0.30;
    for (int i = 0; i < logo.length; i++) {
      final TextPainter tp = harfler[i];
      if (logo[i] != ' ') {
        final double dt2 = ((t - (0.18 + i * 0.045)) / 0.20).clamp(0.0, 1.0);
        if (dt2 > 0) {
          final double e = Curves.elasticOut.transform(dt2);
          final double y = tabanY - (1 - e) * h * 0.35;
          final double op = (dt2 * 3).clamp(0.0, 1.0);
          final Rect hr = Rect.fromLTWH(hx, y, tp.width, tp.height);
          canvas.saveLayer(hr.inflate(6), Paint()..color = Colors.white.withOpacity(op));
          // ince siyah kontur
          final TextPainter konturTp = TextPainter(
            text: TextSpan(
              text: logo[i],
              style: TextStyle(
                fontSize: harfBoyut,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 4
                  ..color = Colors.black,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          konturTp.paint(canvas, Offset(hx, y));
          // metalik altin gradyan dolgu
          final TextPainter dolgu = TextPainter(
            text: TextSpan(
              text: logo[i],
              style: TextStyle(
                fontSize: harfBoyut,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0xFFFFF6C9), Color(0xFFFFD54F), Color(0xFFB8860B), Color(0xFFFFE082)],
                    stops: <double>[0.0, 0.35, 0.62, 1.0],
                  ).createShader(hr),
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          dolgu.paint(canvas, Offset(hx, y));
          canvas.restore();
        }
      }
      hx += tp.width + 3;
    }
    // Parlama sweepi: harflerin ustunden gecen isik bandi
    final double sweep = ((t - 0.62) / 0.25).clamp(0.0, 1.0);
    if (sweep > 0 && sweep < 1) {
      final double sx = (w - toplam) / 2 + sweep * (toplam + 120) - 60;
      canvas.save();
      canvas.translate(sx, tabanY + harfBoyut / 2);
      canvas.rotate(-0.35);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 26, height: harfBoyut * 1.8),
        Paint()..color = Colors.white.withOpacity(0.35 * sin(pi * sweep)),
      );
      canvas.restore();
    }

    // --- ince cizgi + "sunar" ---
    final double sunarOp = ((t - 0.72) / 0.14).clamp(0.0, 1.0);
    if (sunarOp > 0) {
      final double cy = tabanY + harfBoyut + 22;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(w / 2, cy), width: (toplam + 40) * sunarOp, height: 1),
        Paint()..color = kAltin.withOpacity(0.6 * sunarOp),
      );
      final TextPainter sunar = TextPainter(
        text: TextSpan(
          text: 's  u  n  a  r',
          style: TextStyle(color: Colors.white.withOpacity(0.75 * sunarOp), fontSize: 15, letterSpacing: 4),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      sunar.paint(canvas, Offset((w - sunar.width) / 2, cy + 8));
    }

    // Alt kisimda hafif vinyet
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.1),
          radius: 1.25,
          colors: <Color>[Colors.transparent, Colors.black.withOpacity(0.45)],
          stops: const <double>[0.62, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
  }

  static double aralD(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant SplashPainter oldDelegate) => oldDelegate.t != t;
}

// ---------- Ekran 1: Yükleniyor ----------

class YukleniyorEkrani extends StatefulWidget {
  final VoidCallback bitir;
  const YukleniyorEkrani({super.key, required this.bitir});

  @override
  State<YukleniyorEkrani> createState() => _YukleniyorEkraniState();
}

class _YukleniyorEkraniState extends State<YukleniyorEkrani> with SingleTickerProviderStateMixin {
  late final AnimationController kontrol;
  bool zipliyor = false;

  @override
  void initState() {
    super.initState();
    kontrol = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    kontrol.addStatusListener((AnimationStatus s) async {
      if (s == AnimationStatus.completed) {
        if (!mounted) return;
        setState(() => zipliyor = true);
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        widget.bitir();
      }
    });
    kontrol.forward();
  }

  @override
  void dispose() {
    kontrol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return sahaArkaplan(
      child: Column(
        children: <Widget>[
          const Spacer(flex: 2),
          const Text('🏃‍♂️⚽', style: TextStyle(fontSize: 110)),
          const SizedBox(height: 12),
          const Text(
            'FUTBOL KARİYER',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, shadows: <Shadow>[Shadow(blurRadius: 8, color: Colors.black45)]),
          ),
          const Spacer(flex: 3),
          const Text(
            'Yükleniyor...',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kAltin),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AnimatedBuilder(
              animation: kontrol,
              builder: (BuildContext context, Widget? child) {
                return LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints c) {
                    final double genislik = c.maxWidth;
                    final double topX = zipliyor ? genislik - 46 : (genislik - 46) * kontrol.value;
                    return SizedBox(
                      height: 60,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: <Widget>[
                          Container(
                            height: 12,
                            decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(6)),
                          ),
                          FractionallySizedBox(
                            widthFactor: zipliyor ? 1.0 : kontrol.value,
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(color: kAltin, borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                          const Positioned(right: 0, child: Text('🥅', style: TextStyle(fontSize: 40))),
                          Positioned(
                            left: topX,
                            bottom: zipliyor ? 26 : 10,
                            child: AnimatedScale(
                              scale: zipliyor ? 1.4 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: const Text('⚽', style: TextStyle(fontSize: 34)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ---------- Ekran 2: Ana Menü ----------

class AnaMenuEkrani extends StatelessWidget {
  final Map<String, dynamic>? kariyer;
  final void Function(Ekran) git;
  const AnaMenuEkrani({super.key, required this.kariyer, required this.git});

  @override
  Widget build(BuildContext context) {
    return sahaArkaplan(
      child: Stack(
        children: <Widget>[
          const Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Text(
              'CEA GAMES',
              textAlign: TextAlign.center,
              style: TextStyle(color: kAltin, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 4, shadows: <Shadow>[Shadow(blurRadius: 8, color: kAltin)]),
            ),
          ),
          Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: <Widget>[
            const Expanded(
              flex: 4,
              child: Center(child: Text('🏃‍♂️⚽🥅', style: TextStyle(fontSize: 70))),
            ),
            Expanded(
              flex: 6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    '⚽ FUTBOL\nKARİYER',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white, shadows: <Shadow>[Shadow(blurRadius: 8, color: Colors.black45)]),
                  ),
                  const SizedBox(height: 40),
                  if (kariyer != null) ...<Widget>[
                    buyukButon(yazi: '▶️ Kariyere Devam Et', renk: kYesil, onPressed: () => git(Ekran.kariyer)),
                    const SizedBox(height: 16),
                  ],
                  buyukButon(yazi: '🌟 Yeni Kariyer', onPressed: () {
                    if (kariyer != null) {
                      showDialog<void>(
                        context: context,
                        builder: (BuildContext c) => AlertDialog(
                          title: const Text('⚠️ Dikkat'),
                          content: const Text('Daha önce bir kariyeriniz var. Yeni kariyer oluşturmak ister misiniz?'),
                          actions: <Widget>[
                            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Hayır', style: TextStyle(fontSize: 18))),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(c);
                                git(Ekran.yeniKariyer);
                              },
                              child: const Text('Evet', style: TextStyle(fontSize: 18)),
                            ),
                          ],
                        ),
                      );
                    } else {
                      git(Ekran.yeniKariyer);
                    }
                  }),
                  const SizedBox(height: 16),
                  buyukButon(yazi: '⚙️ Ayarlar', renk: const Color(0xFF546E7A), onPressed: () => git(Ekran.ayarlar)),
                ],
              ),
            ),
          ],
        ),
          ),
        ],
      ),
    );
  }
}

// ---------- Ekran 3: Ayarlar ----------

class AyarlarEkrani extends StatelessWidget {
  final Map<String, dynamic> ayarlar;
  final VoidCallback kaydet;
  final VoidCallback geri;
  final VoidCallback sifirla;
  final VoidCallback degisti;

  const AyarlarEkrani({
    super.key,
    required this.ayarlar,
    required this.kaydet,
    required this.geri,
    required this.sifirla,
    required this.degisti,
  });

  @override
  Widget build(BuildContext context) {
    final String zorluk = (ayarlar['zorluk'] ?? 'Orta') as String;
    final double ses = ((ayarlar['ses'] ?? 0.5) as num).toDouble();
    final bool titresim = (ayarlar['titresim'] ?? true) as bool;
    return sahaArkaplan(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text('⚙️ Ayarlar', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            const Text('Zorluk', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                for (final String z in <String>['Kolay', 'Orta', 'Zor'])
                  ChoiceChip(
                    label: Text(z, style: const TextStyle(fontSize: 18)),
                    selected: zorluk == z,
                    selectedColor: kTuruncu,
                    onSelected: (bool v) {
                      ayarlar['zorluk'] = z;
                      kaydet();
                      degisti();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 32),
            Text('🔊 Ses Düzeyi: %${(ses * 100).round()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            Slider(
              value: ses,
              min: 0,
              max: 1,
              activeColor: kTuruncu,
              onChanged: (double v) {
                ayarlar['ses'] = v;
                kaydet();
                degisti();
              },
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('📳 Titreşim', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              value: titresim,
              activeColor: kTuruncu,
              onChanged: (bool v) {
                ayarlar['titresim'] = v;
                kaydet();
                degisti();
              },
            ),
            const Spacer(),
            buyukButon(
              yazi: '🗑 Kariyeri Sıfırla',
              renk: Colors.red.shade700,
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (BuildContext c) => AlertDialog(
                    title: const Text('⚠️ Emin misiniz?'),
                    content: const Text('Kariyeriniz tamamen silinecek!'),
                    actions: <Widget>[
                      TextButton(onPressed: () => Navigator.pop(c), child: const Text('Vazgeç', style: TextStyle(fontSize: 18))),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {
                          sifirla();
                          Navigator.pop(c);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kariyer silindi')));
                        },
                        child: const Text('Sil', style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            buyukButon(yazi: '◀ Geri', renk: const Color(0xFF546E7A), onPressed: geri),
          ],
        ),
      ),
    );
  }
}

// ---------- Ekran 4: Yeni Kariyer ----------

class YeniKariyerEkrani extends StatefulWidget {
  final void Function(Ekran) git;
  final String formAd;
  final String formSoyad;
  final String formUlke;
  final void Function(String, String, String) degisti;

  const YeniKariyerEkrani({
    super.key,
    required this.git,
    required this.formAd,
    required this.formSoyad,
    required this.formUlke,
    required this.degisti,
  });

  @override
  State<YeniKariyerEkrani> createState() => _YeniKariyerEkraniState();
}

class _YeniKariyerEkraniState extends State<YeniKariyerEkrani> {
  late final TextEditingController adC;
  late final TextEditingController soyadC;
  late String ulke;

  @override
  void initState() {
    super.initState();
    adC = TextEditingController(text: widget.formAd);
    soyadC = TextEditingController(text: widget.formSoyad);
    ulke = widget.formUlke;
  }

  @override
  void dispose() {
    adC.dispose();
    soyadC.dispose();
    super.dispose();
  }

  bool gecerli(String s) => s.trim().length >= 3 && s.trim().length <= 30;

  void uyari(String mesaj) {
    showDialog<void>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('⚠️ Uyarı'),
        content: Text(mesaj, style: const TextStyle(fontSize: 18)),
        actions: <Widget>[
          ElevatedButton(onPressed: () => Navigator.pop(c), child: const Text('Tamam', style: TextStyle(fontSize: 18))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return sahaArkaplan(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text('🌟 Yeni Kariyer', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            TextField(
              controller: adC,
              maxLength: 30,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                labelText: 'Ad (3-30 karakter)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            TextField(
              controller: soyadC,
              maxLength: 30,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                labelText: 'Soyad (3-30 karakter)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: ulke,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 20, color: Colors.black87),
                  items: <DropdownMenuItem<String>>[
                    for (final String u in kUlkeler) DropdownMenuItem<String>(value: u, child: Text(u)),
                  ],
                  onChanged: (String? v) {
                    if (v != null) setState(() => ulke = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.lock, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Lig: $ulke 3. Ligi', style: const TextStyle(fontSize: 20, color: Colors.black54)),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF546E7A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(18),
                    shape: const CircleBorder(),
                  ),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext c) => AlertDialog(
                        title: const Text('⚠️ Uyarı'),
                        content: const Text('Geri dönerseniz bilgileriniz silinecektir. Kabul ediyor musunuz?'),
                        actions: <Widget>[
                          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Hayır', style: TextStyle(fontSize: 18))),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(c);
                              widget.git(Ekran.anaMenu);
                            },
                            child: const Text('Evet', style: TextStyle(fontSize: 18)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('◀', style: TextStyle(fontSize: 26)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTuruncu,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(18),
                    shape: const CircleBorder(),
                  ),
                  onPressed: () {
                    if (!gecerli(adC.text) || !gecerli(soyadC.text)) {
                      uyari('Lütfen bilgileri doldurun (ad ve soyad 3-30 karakter olmalı)');
                      return;
                    }
                    widget.degisti(adC.text.trim(), soyadC.text.trim(), ulke);
                    widget.git(Ekran.takimSecim);
                  },
                  child: const Text('▶', style: TextStyle(fontSize: 26)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Ekran 5: Takım Seçimi (18 takım) ----------

class TakimSecimEkrani extends StatefulWidget {
  final String ulke;
  final VoidCallback geri;
  final void Function(String) secti;

  const TakimSecimEkrani({super.key, required this.ulke, required this.geri, required this.secti});

  @override
  State<TakimSecimEkrani> createState() => _TakimSecimEkraniState();
}

class _TakimSecimEkraniState extends State<TakimSecimEkrani> {
  int secili = -1;

  @override
  Widget build(BuildContext context) {
    final List<TakimBilgi> takimlar = ligTakimlari(widget.ulke);
    return sahaArkaplan(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('${widget.ulke} 3. Ligi', textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Takımını Seç! (18 takım)', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, color: Colors.white)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: takimlar.length,
                itemBuilder: (BuildContext context, int i) {
                  final TakimBilgi t = takimlar[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => secili = i),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: secili == i ? kAltin : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: secili == i ? kTuruncu : Colors.transparent, width: 4),
                        ),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 52,
                              height: 52,
                              child: CustomPaint(
                                painter: RozetPainter(Color(t.renk1), Color(t.renk2), basHarfler(t.ad)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(t.ad, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ),
                            if (secili == i) const Icon(Icons.check_circle, color: kYesil, size: 32),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(child: buyukButon(yazi: '◀ Geri', renk: const Color(0xFF546E7A), onPressed: widget.geri)),
                const SizedBox(width: 12),
                Expanded(
                  child: buyukButon(
                    yazi: 'İleri ▶',
                    onPressed: secili < 0
                        ? () {}
                        : () {
                            widget.secti(takimlar[secili].ad);
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Ekran 6: Sözleşme ----------

class ImzaPainter extends CustomPainter {
  final List<Offset?> noktalar;
  ImzaPainter(this.noktalar);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = Colors.blue.shade900
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < noktalar.length - 1; i++) {
      final Offset? a = noktalar[i];
      final Offset? b = noktalar[i + 1];
      if (a != null && b != null) canvas.drawLine(a, b, p);
    }
  }

  @override
  bool shouldRepaint(covariant ImzaPainter oldDelegate) => true;
}

class SozlesmeEkrani extends StatefulWidget {
  final String ad;
  final String soyad;
  final String takim;
  final VoidCallback geri;
  final VoidCallback imzaladi;

  const SozlesmeEkrani({
    super.key,
    required this.ad,
    required this.soyad,
    required this.takim,
    required this.geri,
    required this.imzaladi,
  });

  @override
  State<SozlesmeEkrani> createState() => _SozlesmeEkraniState();
}

class _SozlesmeEkraniState extends State<SozlesmeEkrani> {
  final List<Offset?> noktalar = <Offset?>[];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF5D4037),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Card(
                color: const Color(0xFFFFF8E1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text('📜 RESMİ SÖZLEŞME', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      const Divider(height: 32),
                      Text('Takım: ${widget.takim}', style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 8),
                      Text('Oyuncu: ${widget.ad} ${widget.soyad}', style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 8),
                      const Text('3. Lig — 1 yıllık sözleşme', style: const TextStyle(fontSize: 20)),
                      const Spacer(),
                      const Text('⬇ İmza at', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 4),
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: GestureDetector(
                          onPanUpdate: (DragUpdateDetails d) {
                            setState(() => noktalar.add(d.localPosition));
                          },
                          onPanEnd: (DragEndDetails d) => noktalar.add(null),
                          child: CustomPaint(painter: ImzaPainter(noktalar), size: Size.infinite),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(child: buyukButon(yazi: '◀ Geri', renk: const Color(0xFF546E7A), onPressed: widget.geri)),
                const SizedBox(width: 8),
                Expanded(
                  child: buyukButon(
                    yazi: '🧹 Temizle',
                    renk: Colors.red.shade400,
                    onPressed: () => setState(noktalar.clear),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: buyukButon(
                    yazi: '🖋 İmzala',
                    renk: kYesil,
                    onPressed: () {
                      if (noktalar.where((Offset? o) => o != null).isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Önce imza atmalısınız!')));
                        return;
                      }
                      widget.imzaladi();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Ekran 7: Gazete ----------

class GazeteEkrani extends StatelessWidget {
  final String ad;
  final String soyad;
  final String takim;
  final VoidCallback basla;

  const GazeteEkrani({super.key, required this.ad, required this.soyad, required this.takim, required this.basla});

  @override
  Widget build(BuildContext context) {
    final DateTime simdi = DateTime.now();
    final String tarih = '${simdi.day}.${simdi.month}.${simdi.year}';
    return Container(
      color: const Color(0xFF37474F),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              color: const Color(0xFFFFF8E1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: <Widget>[
                    Text('SPOR GAZETESİ — $tarih', style: const TextStyle(fontSize: 14, letterSpacing: 2, color: Colors.black54)),
                    const Divider(height: 24),
                    const Text('SON DAKİKA!', textAlign: TextAlign.center, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    Text(
                      '$ad $soyad resmen $takim${takimEk(takim)}!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text('3. Lig transfer haberi ⚽🖋', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 12),
                    const Text(
                      'Genç yıldız adayı, yeni takımıyla 1 yıllık sözleşme imzaladı. Taraftarlar büyük heyecan içinde!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            buyukButon(yazi: 'Kariyere Başla ▶', renk: kYesil, onPressed: basla),
          ],
        ),
      ),
    );
  }
}

// ---------- Ekran 8: Kariyer Ana Sayfası (hub) ----------

const List<String> kGunAdlari = <String>['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'MAÇ'];

class KariyerEkrani extends StatefulWidget {
  final Map<String, dynamic> kariyer;
  final Map<String, dynamic> ayarlar;
  final Future<void> Function() kaydet;
  final VoidCallback anaMenu;
  final VoidCallback degisti;

  const KariyerEkrani({
    super.key,
    required this.kariyer,
    required this.ayarlar,
    required this.kaydet,
    required this.anaMenu,
    required this.degisti,
  });

  @override
  State<KariyerEkrani> createState() => _KariyerEkraniState();
}

class _KariyerEkraniState extends State<KariyerEkrani> {
  final Random r = Random();

  Map<String, dynamic> get k => widget.kariyer;

  TakimBilgi get benimTakim => takimBul(kStr(k, 'takim'));

  TakimBilgi rakipTakim() {
    final List<TakimBilgi> lig = ligTakimlari(kStr(k, 'ulke'));
    final List<dynamic> fik = kListe(k, 'fikstur');
    final int hafta = kInt(k, 'hafta', 1);
    if (fik.isEmpty || hafta < 1 || hafta > fik.length) return lig[0];
    // Fikstür kaydını güvenli oku
    final dynamic kayit = fik[hafta - 1];
    if (kayit is! num) return lig[0];
    final int idx = kayit.toInt().clamp(0, lig.length - 1);
    return lig[idx];
  }

  void bildirimEkle(String metin, [String tip = 'haber']) {
    final List<dynamic> b = kListe(k, 'bildirimler');
    b.insert(0, <String, dynamic>{'metin': metin, 'tip': tip, 'okundu': false});
    k['bildirimler'] = b;
  }

  void mesajEkle(String kimden, String kim, String metin, [String tip = 'normal']) {
    final List<dynamic> m = kListe(k, 'mesajlar');
    m.insert(0, <String, dynamic>{'kimden': kimden, 'kim': kim, 'metin': metin, 'tip': tip, 'okundu': false});
    k['mesajlar'] = m;
  }

  int okunmamisBildirim() {
    int s = 0;
    for (final dynamic e in kListe(k, 'bildirimler')) {
      final Map<String, dynamic> m = Map<String, dynamic>.from(e as Map<dynamic, dynamic>);
      if (m['okundu'] != true) s++;
    }
    return s;
  }

  int okunmamisMesaj() {
    int s = 0;
    for (final dynamic e in kListe(k, 'mesajlar')) {
      final Map<String, dynamic> m = Map<String, dynamic>.from(e as Map<dynamic, dynamic>);
      if (m['okundu'] != true) s++;
    }
    return s;
  }

  // Hafta ilerletme: günleri geçir
  void gunIlerlet() {
    int gun = kInt(k, 'gun', 1);
    if (gun < 7) {
      gun++;
      k['gun'] = gun;
      if (gun >= 5 && kInt(k, 'antHafta', 0) != kInt(k, 'hafta', 1)) {
        bildirimEkle('🏋 Maç öncesi antrenman zamanı! Şut çalışıp antrenman puanı kazan.', 'antrenman');
      }
      if (gun == 7) {
        bildirimEkle('📢 Bugün maç günü! ${rakipTakim().ad} ile oynuyorsun. Bol şans!', 'mac');
      }
      widget.kaydet();
      setState(() {});
      widget.degisti();
    }
  }

  void macaGit() {
    final TakimBilgi rakip = rakipTakim();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext c) => MacGunuEkrani(
          kariyer: k,
          rakip: rakip,
          macaGec: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext c2) => MacEkrani(
                  kariyer: k,
                  rakip: rakip,
                  zorluk: (widget.ayarlar['zorluk'] ?? 'Orta') as String,
                  bitti: (Map<String, dynamic> sonuc) {
                    macSonucuUygula(sonuc);
                    Navigator.pop(c2);
                  },
                ),
              ),
            );
          },
        ),
      ),
    ).then((_) {
      setState(() {});
      widget.degisti();
    });
  }

  // Maç sonucunu kariyere uygula
  void macSonucuUygula(Map<String, dynamic> s) {
    final int gol = (s['gol'] as num?)?.toInt() ?? 0;
    final int asist = (s['asist'] as num?)?.toInt() ?? 0;
    final double rating = ((s['rating'] as num?)?.toDouble() ?? 6.0);
    final int skorBiz = (s['skorBiz'] as num?)?.toInt() ?? 0;
    final int skorRakip = (s['skorRakip'] as num?)?.toInt() ?? 0;
    final bool galibiyet = skorBiz > skorRakip;
    final bool berabere = skorBiz == skorRakip;
    // Altın ekonomisi
    int altin = kInt(k, 'altin', 0);
    final int kazanc = gol * 15 + asist * 10 + (galibiyet ? 20 : (berabere ? 8 : 3));
    altin += kazanc;
    k['altin'] = altin;
    k['gol'] = kInt(k, 'gol') + gol;
    k['asist'] = kInt(k, 'asist') + asist;
    k['macSayisi'] = kInt(k, 'macSayisi') + 1;
    k['sezonGol'] = kInt(k, 'sezonGol') + gol;
    k['sezonAsist'] = kInt(k, 'sezonAsist') + asist;
    k['sezonMac'] = kInt(k, 'sezonMac') + 1;
    k['ilk11Mac'] = kInt(k, 'ilk11Mac') + 1;
    final List<dynamic> gecmis = kListe(k, 'ratingGecmisi');
    gecmis.add(double.parse(rating.toStringAsFixed(1)));
    k['ratingGecmisi'] = gecmis;
    // Puan tablosu güncelle
    tabloGuncelle(skorBiz, skorRakip);
    // Teknik direktör mesajı
    if (rating >= 7.5) {
      final List<String> iyi = <String>[
        'Bu maç iyi iş çıkardın! Böyle devam et! 👏',
        'Harika bir performanstı. Gözüm üzerinde, yıldızlaşıyorsun! ⭐',
        'Bugün sahada parladın. Takımın lideri oluyorsun! 💪',
      ];
      mesajEkle('Teknik Direktör', 'Teknik Direktör', iyi[r.nextInt(iyi.length)], 'td');
    } else if (rating < 5.0) {
      mesajEkle('Teknik Direktör', 'Teknik Direktör', 'Bugün istediğim gibi değildin. Antrenmanlarda daha çok çalışmalısın.', 'td');
    }
    if (gol > 0) {
      final List<dynamic> ark = kListe(k, 'arkadaslar');
      if (ark.isNotEmpty) {
        mesajEkle(ark[r.nextInt(ark.length)] as String, 'Takım Arkadaşı', 'Attığın gol muhteşemdi! 🎉 Beraber daha çok gol atacağız!');
      }
    }
    bildirimEkle('🏟 Maç bitti: ${benimTakim.ad} $skorBiz - $skorRakip ${rakipTakim().ad} • +$kazanc altın 💰');
    k['gun'] = 1;
    k['hafta'] = kInt(k, 'hafta', 1) + 1;
    // Sezon ortası transfer teklifleri
    if (kInt(k, 'hafta', 1) >= 9 && k['teklifVerildi'] != true && kInt(k, 'hafta', 1) <= 20) {
      teklifleriOlustur();
    }
    // Sezon sonu
    if (kInt(k, 'hafta', 1) > 34) {
      sezonSonu();
    }
    widget.kaydet();
    setState(() {});
    widget.degisti();
  }

  void tabloGuncelle(int skorBiz, int skorRakip) {
    final List<TakimBilgi> lig = ligTakimlari(kStr(k, 'ulke'));
    final int benimIdx = benimTakim.index;
    final int rakipIdx = rakipTakim().index;
    if (benimIdx == rakipIdx) return; // Rakip kendi takımıysa tabloyu güncelleme
    final List<dynamic> tablo = kListe(k, 'tablo');
    void satir(int i, int ag, int yg) {
      if (i < 0 || i >= tablo.length) return;
      final Map<String, dynamic> t = Map<String, dynamic>.from(tablo[i] as Map<dynamic, dynamic>);
      t['ag'] = ((t['ag'] ?? 0) as num).toInt() + ag;
      t['yg'] = ((t['yg'] ?? 0) as num).toInt() + yg;
      if (ag > yg) {
        t['p'] = ((t['p'] ?? 0) as num).toInt() + 3;
        t['g'] = ((t['g'] ?? 0) as num).toInt() + 1;
      } else if (ag == yg) {
        t['p'] = ((t['p'] ?? 0) as num).toInt() + 1;
        t['b'] = ((t['b'] ?? 0) as num).toInt() + 1;
      } else {
        t['m'] = ((t['m'] ?? 0) as num).toInt() + 1;
      }
      tablo[i] = t;
    }
    satir(benimIdx, skorBiz, skorRakip);
    satir(rakipIdx, skorRakip, skorBiz);
    // Diğer takımların sonuçlarını simüle et
    for (int i = 0; i < lig.length; i++) {
      if (i == benimIdx || i == rakipIdx) continue;
      final int a = r.nextInt(4);
      final int b = r.nextInt(4);
      satir(i, a, b);
    }
    k['tablo'] = tablo;
  }

  void teklifleriOlustur() {
    k['teklifVerildi'] = true;
    final Random rr = Random();
    final List<String> digerUlkeler = <String>[for (final String u in kUlkeler) u];
    final int adet = 3 + rr.nextInt(2); // 3-4 teklif
    final Set<String> secilen = <String>{kStr(k, 'takim')};
    final List<Map<String, dynamic>> teklifler = <Map<String, dynamic>>[];
    while (teklifler.length < adet) {
      final String u = digerUlkeler[rr.nextInt(digerUlkeler.length)];
      final List<TakimBilgi> l = ligTakimlari(u);
      final TakimBilgi t = l[rr.nextInt(l.length)];
      if (secilen.contains(t.ad)) continue;
      secilen.add(t.ad);
      final int golHedef = 10 + rr.nextInt(8);
      final int asistHedef = 6 + rr.nextInt(6);
      final List<Map<String, dynamic>> gorevler = <Map<String, dynamic>>[
        <String, dynamic>{'metin': 'Bu sezon $golHedef gol at', 'tip': 'gol', 'hedef': golHedef},
        <String, dynamic>{'metin': 'Bu sezon $asistHedef asist yap', 'tip': 'asist', 'hedef': asistHedef},
        <String, dynamic>{'metin': 'İlk 11\'de maçların %35\'inde oyna', 'tip': 'ilk11', 'hedef': 35},
        <String, dynamic>{'metin': 'Maç reyting ortalaman 6.5 üzeri olsun', 'tip': 'rating', 'hedef': 65},
      ];
      gorevler.shuffle(rr);
      teklifler.add(<String, dynamic>{
        'ulke': u,
        'takim': t.ad,
        'gorevler': gorevler.take(3 + rr.nextInt(2)).toList(),
        'durum': 'bekliyor',
      });
    }
    k['teklifler'] = teklifler;
    mesajEkle(
      kStr(k, 'menajerAd'),
      'Menajer',
      'Seninle ilgilenen takımlar var, bakmak ister misin? 📩 Mesajlar ekranındaki "Transfer Teklifleri" butonuna dokun!',
      'teklif',
    );
  }

  void sezonSonu() {
    // Transfer varsa uygula
    final String hedef = kStr(k, 'transferTakim', '');
    if (hedef.isNotEmpty) {
      final TakimBilgi t = takimBul(hedef);
      k['takim'] = t.ad;
      k['ulke'] = t.ulke;
      k['lig'] = '${t.ulke} 3. Ligi';
      final List<String> isimler = List<String>.from(kOyuncuIsimleri[t.ulke] ?? kOyuncuIsimleri['Türkiye']!);
      isimler.shuffle(r);
      k['arkadaslar'] = isimler.take(10).toList();
      bildirimEkle('✈️ Transferin gerçekleşti! Artık ${t.ad} oyuncususun. Yeni takımında bol şans!');
    } else {
      bildirimEkle('🏁 Sezon bitti! Yeni sezonda da ${benimTakim.ad} forması giyiyorsun.');
    }
    k['sezon'] = kInt(k, 'sezon', 1) + 1;
    k['yas'] = kInt(k, 'yas', 18) + 1;
    k['hafta'] = 1;
    k['gun'] = 1;
    k['sezonGol'] = 0;
    k['sezonAsist'] = 0;
    k['sezonMac'] = 0;
    k['ilk11Mac'] = 0;
    k['teklifVerildi'] = false;
    k['teklifler'] = <Map<String, dynamic>>[];
    k['transferTakim'] = '';
    // Yeni fikstür + tablo
    final List<TakimBilgi> lig = ligTakimlari(kStr(k, 'ulke'));
    final int benimIndex = lig.indexWhere((TakimBilgi t) => t.ad == kStr(k, 'takim'));
    final List<int> rakipler = <int>[for (int i = 0; i < lig.length; i++) if (i != benimIndex) i];
    rakipler.shuffle(r);
    final List<int> ilkYari = List<int>.from(rakipler);
    rakipler.shuffle(r);
    k['fikstur'] = <int>[...ilkYari, ...rakipler];
    k['tablo'] = <Map<String, dynamic>>[
      for (int i = 0; i < lig.length; i++)
        <String, dynamic>{'i': i, 'p': 0, 'g': 0, 'b': 0, 'm': 0, 'ag': 0, 'yg': 0},
    ];
  }

  void ac(Widget sayfa) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (BuildContext c) => sayfa)).then((_) {
      widget.kaydet();
      setState(() {});
      widget.degisti();
    });
  }

  Widget menuButon(String emoji, String yazi, VoidCallback bas, [int rozetSayi = 0]) {
    return Stack(
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.all(6),
            ),
            onPressed: bas,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 4),
                Text(yazi, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        if (rozetSayi > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Text('$rozetSayi', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final int gun = kInt(k, 'gun', 1);
    final int hafta = kInt(k, 'hafta', 1);
    final bool macGunu = gun >= 7;
    final TakimBilgi rakip = rakipTakim();
    return sahaArkaplan(
      child: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Üst bilgi
                  Row(
                    children: <Widget>[
                      rozet(kStr(k, 'takim'), 64),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('${kStr(k, 'ad')} ${kStr(k, 'soyad')}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('${kStr(k, 'takim')} • ${kStr(k, 'lig')}', style: const TextStyle(fontSize: 15, color: Colors.white)),
                            Text('Sezon ${kInt(k, 'sezon', 1)} • Hafta $hafta/34', style: const TextStyle(fontSize: 15, color: Colors.white)),
                          ],
                        ),
                      ),
                      Column(
                        children: <Widget>[
                          const Icon(Icons.monetization_on, color: kAltin, size: 28),
                          Text('${kInt(k, 'altin')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Haftalık takvim
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        for (int i = 1; i <= 7; i++)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: i == gun ? kAltin : (i < gun ? Colors.white38 : Colors.transparent),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              kGunAdlari[i - 1],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: i == gun ? FontWeight.bold : FontWeight.normal,
                                color: i == gun ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Sonraki maç
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: <Widget>[
                          Text(macGunu ? '⚽ BUGÜN MAÇ GÜNÜ!' : 'Sonraki Maç', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kYesil)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Column(
                                children: <Widget>[
                                  rozet(benimTakim.ad, 64),
                                  const SizedBox(height: 4),
                                  SizedBox(width: 110, child: Text(benimTakim.ad, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                                ],
                              ),
                              const Text('v', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kTuruncu)),
                              Column(
                                children: <Widget>[
                                  rozet(rakip.ad, 64),
                                  const SizedBox(height: 4),
                                  SizedBox(width: 110, child: Text(rakip.ad, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Menü butonları
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.05,
                    children: <Widget>[
                      menuButon('📅', 'Bildirimler', () => ac(BildirimlerEkrani(kariyer: k)), okunmamisBildirim()),
                      menuButon('✉️', 'Mesajlar', () => ac(MesajlarEkrani(kariyer: k)), okunmamisMesaj()),
                      menuButon('🏆', 'Puan Durumu', () => ac(PuanDurumuEkrani(kariyer: k))),
                      menuButon('👟', 'Kramponlar', () => ac(KramponlarEkrani(kariyer: k))),
                      menuButon('💪', 'Özellikler', () => ac(OzelliklerEkrani(kariyer: k))),
                      menuButon('ℹ️', 'Bilgiler', () => ac(BilgilerEkrani(kariyer: k))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  buyukButon(yazi: '🏠 Ana Menü', renk: const Color(0xFF546E7A), onPressed: widget.anaMenu),
                ],
              ),
            ),
          ),
          // Alt maç butonu
          Container(
            color: Colors.black26,
            padding: const EdgeInsets.all(12),
            child: buyukButon(
              yazi: macGunu ? '⚽ Maça Git →' : '⏭ Maç Gününe Git →',
              renk: macGunu ? kYesil : kTuruncu,
              onPressed: macGunu ? macaGit : gunIlerlet,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Bildirimler ----------

class BildirimlerEkrani extends StatefulWidget {
  final Map<String, dynamic> kariyer;
  const BildirimlerEkrani({super.key, required this.kariyer});

  @override
  State<BildirimlerEkrani> createState() => _BildirimlerEkraniState();
}

class _BildirimlerEkraniState extends State<BildirimlerEkrani> {
  @override
  Widget build(BuildContext context) {
    final List<dynamic> b = kListe(widget.kariyer, 'bildirimler');
    // Hepsini okundu yap
    for (final dynamic e in b) {
      if (e is Map) (e as Map<dynamic, dynamic>)['okundu'] = true;
    }
    return altEkran(
      baslik: '📅 Bildirimler',
      child: b.isEmpty
          ? const Center(child: Text('Henüz bildirim yok', style: TextStyle(fontSize: 20)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: b.length,
              itemBuilder: (BuildContext context, int i) {
                final dynamic oge = b[i]; // Öğe referansı: index kaymasına karşı
                final Map<String, dynamic> m = Map<String, dynamic>.from(oge as Map<dynamic, dynamic>);
                final bool antrenman = m['tip'] == 'antrenman';
                return Card(
                  color: antrenman ? const Color(0xFFFFF9C4) : Colors.white,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: Text(antrenman ? '🏋' : '📢', style: const TextStyle(fontSize: 28)),
                    title: Text((m['metin'] ?? '') as String, style: const TextStyle(fontSize: 17)),
                    subtitle: antrenman ? const Text('Antrenman yapmak için dokun! +1 antrenman puanı', style: TextStyle(color: kTuruncu)) : null,
                    onTap: antrenman
                        ? () async {
                            final bool haftaYapildi = kInt(widget.kariyer, 'antHafta', 0) == kInt(widget.kariyer, 'hafta', 1);
                            await Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (BuildContext c) => AntrenmanEkrani(
                                  kariyer: widget.kariyer,
                                  yapildi: haftaYapildi,
                                  bitir: () {
                                    // Haftada sadece 1 kez antrenman puanı kazanılır
                                    if (kInt(widget.kariyer, 'antHafta', 0) == kInt(widget.kariyer, 'hafta', 1)) return;
                                    widget.kariyer['antPuani'] = kInt(widget.kariyer, 'antPuani') + 1;
                                    widget.kariyer['antHafta'] = kInt(widget.kariyer, 'hafta', 1);
                                    b.remove(oge);
                                    setState(() {});
                                  },
                                ),
                              ),
                            );
                            setState(() {});
                          }
                        : null,
                  ),
                );
              },
            ),
    );
  }
}

// ---------- Antrenman (3 oynanabilir mini oyun) ----------

class AntrenmanEkrani extends StatefulWidget {
  final Map<String, dynamic> kariyer;
  final bool yapildi;
  final VoidCallback bitir;
  const AntrenmanEkrani({super.key, required this.kariyer, required this.yapildi, required this.bitir});

  @override
  State<AntrenmanEkrani> createState() => _AntrenmanEkraniState();
}

class _AntrenmanEkraniState extends State<AntrenmanEkrani> {
  int oyun = 0; // 0 = seçim menüsü

  // Kazanılan her puan mevcut sisteme yazılır (haftalık sınır bitir içinde korunur)
  void puanVer(int n) {
    for (int i = 0; i < n; i++) {
      widget.bitir();
    }
    setState(() {});
  }

  Widget oyunKarti(String emoji, String ad, String aciklama, int no, Color renk) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Text(emoji, style: const TextStyle(fontSize: 36)),
        title: Text(ad, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        subtitle: Text(aciklama, style: const TextStyle(fontSize: 14)),
        trailing: Icon(Icons.play_circle_fill, color: renk, size: 40),
        onTap: () => setState(() => oyun = no),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (oyun == 1) {
      return PasOyunu(kariyer: widget.kariyer, puanVer: puanVer, geri: () => setState(() => oyun = 0));
    }
    if (oyun == 2) {
      return FrikikOyunu(kariyer: widget.kariyer, puanVer: puanVer, geri: () => setState(() => oyun = 0));
    }
    if (oyun == 3) {
      return CalimOyunu(kariyer: widget.kariyer, puanVer: puanVer, geri: () => setState(() => oyun = 0));
    }
    return altEkran(
      baslik: '🏋 Antrenman',
      arkaplan: const Color(0xFFC8E6C9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Text('Antrenman Puanın: ${kInt(widget.kariyer, 'antPuani')}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kYesil)),
            const SizedBox(height: 4),
            const Text('Bir mini oyun seç, puanları topla! (Haftalık puan sınırı geçerlidir.)',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 15)),
            const SizedBox(height: 16),
            oyunKarti('🎯', 'Pas Antrenmanı', 'İki direğin arasından topu geçir! 5 hak.', 1, kTuruncu),
            oyunKarti('🥅', 'Frikik', 'Barajı aşıp falsolu vuruşla golü bul! 3 hak.', 2, kYesil),
            oyunKarti('🚧', 'Çalım Parkuru', 'Konilere değmeden bitişe ulaş! 45 saniye.', 3, const Color(0xFF1565C0)),
          ],
        ),
      ),
    );
  }
}

// Mini oyun ortak çerçevesi: başlık + puan + hak + rozet
Widget miniOyunCerceve({
  required String baslik,
  required Color arkaplan,
  required int skor,
  required int hak,
  required String rozet,
  required VoidCallback geri,
  required Widget saha,
  String aciklama = '',
}) {
  return altEkran(
    baslik: baslik,
    arkaplan: arkaplan,
    child: Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: <Widget>[
              TextButton.icon(onPressed: geri, icon: const Icon(Icons.arrow_back), label: const Text('Geri', style: TextStyle(fontSize: 16))),
              const Spacer(),
              Text('Skor: $skor', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kYesil)),
              const SizedBox(width: 14),
              Text('Hak: $hak', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTuruncu)),
            ],
          ),
        ),
        if (aciklama.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(aciklama, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
          ),
        const SizedBox(height: 6),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(borderRadius: BorderRadius.circular(16), child: saha),
          ),
        ),
        SizedBox(
          height: 56,
          child: Center(
            child: rozet.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kAltin, width: 2),
                    ),
                    child: Text(rozet, style: const TextStyle(color: kAltin, fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
          ),
        ),
      ],
    ),
  );
}

// Mini futbol topu çizimi (mini oyunlarda ortak)
void miniTopCiz(Canvas canvas, Offset c, double r) {
  canvas.drawOval(Rect.fromCenter(center: c + Offset(0, r * 0.9), width: r * 1.8, height: r * 0.6), Paint()..color = Colors.black26);
  canvas.drawCircle(c, r, Paint()..color = Colors.white);
  canvas.drawCircle(c, r, Paint()
    ..color = Colors.black54
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2);
  canvas.drawCircle(c + Offset(-r * 0.25, -r * 0.2), r * 0.24, Paint()..color = Colors.black87);
  canvas.drawCircle(c + Offset(r * 0.3, r * 0.3), r * 0.16, Paint()..color = Colors.black87);
}

// ===== 1) PAS ANTRENMANI: iki turuncu direğin arasından topu geçir (5 hak) =====

class PasOyunu extends StatefulWidget {
  final Map<String, dynamic> kariyer;
  final void Function(int) puanVer;
  final VoidCallback geri;
  const PasOyunu({super.key, required this.kariyer, required this.puanVer, required this.geri});

  @override
  State<PasOyunu> createState() => _PasOyunuState();
}

class _PasOyunuState extends State<PasOyunu> {
  final Random r = Random();
  Timer? timer;
  Offset top = const Offset(0.5, 0.85); // oran
  Offset? surukle;
  Offset ucusBas = Offset.zero;
  Offset ucusBit = Offset.zero;
  double ucusT = 0;
  bool ucuyor = false;
  int hak = 5;
  int skor = 0;
  String rozet = '';
  double direkMerkez = 0.5; // her turda kayar

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void atis(Offset bit) {
    if (ucuyor || hak <= 0) return;
    ucusBas = top;
    ucusBit = bit;
    ucusT = 0;
    ucuyor = true;
    rozet = '';
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 30), (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        ucusT += 0.06;
        top = Offset.lerp(ucusBas, ucusBit, ucusT.clamp(0.0, 1.0))!;
        if (ucusT >= 1) {
          t.cancel();
          ucuyor = false;
          hak--;
          final bool gecti = (top.dx - direkMerkez).abs() < 0.09 && top.dy <= 0.22;
          if (gecti) {
            skor++;
            rozet = 'Harika! +1';
            widget.puanVer(1);
          } else {
            rozet = 'Olmedi, tekrar dene';
          }
          if (hak > 0) {
            top = const Offset(0.5, 0.85);
            direkMerkez = 0.3 + r.nextDouble() * 0.4;
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return miniOyunCerceve(
      baslik: '🎯 Pas Antrenmanı',
      arkaplan: const Color(0xFFC8E6C9),
      skor: skor,
      hak: hak,
      rozet: hak <= 0 && !ucuyor ? 'Bitti! Skor: $skor/5' : rozet,
      geri: widget.geri,
      aciklama: 'Parmağını toptan hedefe doğru kaydır ve bırak. Turuncu direklerin arasından geçir!',
      saha: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          return GestureDetector(
            onPanStart: (DragStartDetails d) {
              if (ucuyor || hak <= 0) return;
              setState(() => surukle = d.localPosition);
            },
            onPanUpdate: (DragUpdateDetails d) => setState(() => surukle = d.localPosition),
            onPanEnd: (DragEndDetails d) {
              if (surukle != null) {
                final Size sz = Size(c.maxWidth, c.maxHeight);
                final Offset n = Offset((surukle!.dx / sz.width).clamp(0.0, 1.0), (surukle!.dy / sz.height).clamp(0.0, 1.0));
                surukle = null;
                atis(n);
              }
            },
            child: CustomPaint(
              size: Size(c.maxWidth, c.maxHeight),
              painter: PasOyunuPainter(top: top, direkMerkez: direkMerkez, surukle: surukle, ucuyor: ucuyor),
            ),
          );
        },
      ),
    );
  }
}

class PasOyunuPainter extends CustomPainter {
  final Offset top;
  final double direkMerkez;
  final Offset? surukle;
  final bool ucuyor;
  PasOyunuPainter({required this.top, required this.direkMerkez, required this.surukle, required this.ucuyor});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    // Cim
    for (int i = 0; i < 8; i++) {
      canvas.drawRect(Rect.fromLTWH(0, h * i / 8, w, h / 8), Paint()..color = i.isEven ? const Color(0xFF2E7D32) : const Color(0xFF388E3C));
    }
    // Turuncu direkler
    final Offset d1 = Offset((direkMerkez - 0.09) * w, h * 0.18);
    final Offset d2 = Offset((direkMerkez + 0.09) * w, h * 0.18);
    final Paint direk = Paint()
      ..color = kTuruncu
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(d1, d1 + const Offset(0, 46), direk);
    canvas.drawLine(d2, d2 + const Offset(0, 46), direk);
    canvas.drawLine(d1 + const Offset(0, 50), d2 + const Offset(0, 50), Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 2);
    // Nişan çizgisi
    if (surukle != null && !ucuyor) {
      canvas.drawLine(Offset(top.dx * w, top.dy * h), surukle!, Paint()
        ..color = kAltin
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round);
      canvas.drawCircle(surukle!, 9, Paint()..color = kAltin.withOpacity(0.7));
    }
    miniTopCiz(canvas, Offset(top.dx * w, top.dy * h), 14);
  }

  @override
  bool shouldRepaint(covariant PasOyunuPainter oldDelegate) => true;
}

// ===== 2) FRIKIK: baraj + kaleci, falsolu kavisli vuruş (3 hak, gol = +2) =====

class FrikikOyunu extends StatefulWidget {
  final Map<String, dynamic> kariyer;
  final void Function(int) puanVer;
  final VoidCallback geri;
  const FrikikOyunu({super.key, required this.kariyer, required this.puanVer, required this.geri});

  @override
  State<FrikikOyunu> createState() => _FrikikOyunuState();
}

class _FrikikOyunuState extends State<FrikikOyunu> {
  Timer? timer;
  Offset top = const Offset(0.5, 0.88);
  Offset? surukleBas;
  Offset? surukleSon;
  Offset ucusBas = Offset.zero;
  Offset ucusBit = Offset.zero;
  double kavis = 0; // falsolu kavis miktarı (+sağ / -sol)
  double ucusT = 0;
  bool ucuyor = false;
  int hak = 3;
  int skor = 0;
  String rozet = '';
  final Random r = Random();
  double kaleciX = 0.5;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void atis() {
    if (ucuyor || hak <= 0 || surukleBas == null || surukleSon == null) return;
    final Offset f = surukleSon! - surukleBas!;
    if (f.distance < 20) return;
    ucusBas = top;
    // Bitiş: sürükleme yönünün uzatılmış hali (yukarı vuruş)
    ucusBit = Offset((top.dx + f.dx * 0.004).clamp(0.05, 0.95), 0.07);
    kavis = (f.dx * 0.0012).clamp(-0.35, 0.35);
    kaleciX = 0.35 + r.nextDouble() * 0.3;
    ucusT = 0;
    ucuyor = true;
    rozet = '';
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 30), (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        ucusT += 0.05;
        final double tt = ucusT.clamp(0.0, 1.0);
        final Offset dogru = Offset.lerp(ucusBas, ucusBit, tt)!;
        // Falso: yana doğru sinüzoidal sapma
        top = dogru + Offset(sin(pi * tt) * kavis, 0);
        if (ucusT >= 1) {
          t.cancel();
          ucuyor = false;
          hak--;
          final bool barajAsti = kavis.abs() >= 0.10 || (top.dx - 0.5).abs() > 0.22;
          final bool kalede = (top.dx - 0.5).abs() < 0.20;
          final bool kaleciKurtardi = (top.dx - kaleciX).abs() < 0.07;
          if (kalede && barajAsti && !kaleciKurtardi) {
            skor += 2;
            rozet = 'Mükemmel! +2';
            widget.puanVer(2);
          } else if (!barajAsti) {
            rozet = 'Baraja çarptı! Olmedi, tekrar dene';
          } else if (kaleciKurtardi) {
            rozet = 'Kaleci kurtardı! Olmedi, tekrar dene';
          } else {
            rozet = 'Aut! Olmedi, tekrar dene';
          }
          if (hak > 0) top = const Offset(0.5, 0.88);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return miniOyunCerceve(
      baslik: '🥅 Frikik',
      arkaplan: const Color(0xFFC8E6C9),
      skor: skor,
      hak: hak,
      rozet: hak <= 0 && !ucuyor ? 'Bitti! Skor: $skor' : rozet,
      geri: widget.geri,
      aciklama: 'Toptan yana-yukarı sürükle: yönü ve falsoyu sen çiz! Barajı aşıp kaleyi bul.',
      saha: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          return GestureDetector(
            onPanStart: (DragStartDetails d) {
              if (ucuyor || hak <= 0) return;
              setState(() {
                surukleBas = d.localPosition;
                surukleSon = d.localPosition;
              });
            },
            onPanUpdate: (DragUpdateDetails d) => setState(() => surukleSon = d.localPosition),
            onPanEnd: (DragEndDetails d) {
              atis();
              surukleBas = null;
              surukleSon = null;
            },
            child: CustomPaint(
              size: Size(c.maxWidth, c.maxHeight),
              painter: FrikikPainter(top: top, kaleciX: kaleciX, surukleBas: surukleBas, surukleSon: surukleSon),
            ),
          );
        },
      ),
    );
  }
}

class FrikikPainter extends CustomPainter {
  final Offset top;
  final double kaleciX;
  final Offset? surukleBas;
  final Offset? surukleSon;
  FrikikPainter({required this.top, required this.kaleciX, required this.surukleBas, required this.surukleSon});

  void miniAdam(Canvas canvas, Offset g, Color renk) {
    canvas.drawOval(Rect.fromCenter(center: g + const Offset(0, 2), width: 16, height: 5), Paint()..color = Colors.black26);
    canvas.drawCircle(g - const Offset(0, 14), 4.5, Paint()..color = const Color(0xFFFFCC9E));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(g.dx - 6, g.dy - 12, 12, 12), const Radius.circular(3)), Paint()..color = renk);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    for (int i = 0; i < 8; i++) {
      canvas.drawRect(Rect.fromLTWH(0, h * i / 8, w, h / 8), Paint()..color = i.isEven ? const Color(0xFF2E7D32) : const Color(0xFF388E3C));
    }
    // Kale
    final Offset ks = Offset(w * 0.30, h * 0.045);
    final double kw = w * 0.40;
    canvas.drawRect(Rect.fromLTWH(ks.dx, ks.dy, kw, 8), Paint()..color = Colors.white.withOpacity(0.3));
    final Paint direk = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(ks, ks + const Offset(0, 18), direk);
    canvas.drawLine(ks + Offset(kw, 0), ks + Offset(kw, 18), direk);
    canvas.drawLine(ks, ks + Offset(kw, 0), direk);
    // Kaleci
    miniAdam(canvas, Offset(kaleciX * w, h * 0.10), kTuruncu);
    // Baraj (3 mini adam)
    for (int i = 0; i < 3; i++) {
      miniAdam(canvas, Offset(w * (0.44 + i * 0.06), h * 0.45), const Color(0xFF1565C0));
    }
    // Sürükleme yönü
    if (surukleBas != null && surukleSon != null) {
      canvas.drawLine(surukleBas!, surukleSon!, Paint()
        ..color = kAltin
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round);
      canvas.drawCircle(surukleSon!, 8, Paint()..color = kAltin.withOpacity(0.7));
    }
    miniTopCiz(canvas, Offset(top.dx * w, top.dy * h), 13);
  }

  @override
  bool shouldRepaint(covariant FrikikPainter oldDelegate) => true;
}

// ===== 3) ÇALIM PARKURU: konilere değmeden topu bitişe sür (45 sn) =====

class CalimOyunu extends StatefulWidget {
  final Map<String, dynamic> kariyer;
  final void Function(int) puanVer;
  final VoidCallback geri;
  const CalimOyunu({super.key, required this.kariyer, required this.puanVer, required this.geri});

  @override
  State<CalimOyunu> createState() => _CalimOyunuState();
}

class _CalimOyunuState extends State<CalimOyunu> {
  Timer? timer;
  Offset top = const Offset(0.5, 0.92);
  bool surukluyor = false;
  double kalan = 45;
  int skor = 0;
  String rozet = '';
  bool bittiMi = false;

  static const List<Offset> koniler = <Offset>[
    Offset(0.30, 0.78), Offset(0.65, 0.68), Offset(0.35, 0.56),
    Offset(0.70, 0.45), Offset(0.30, 0.34), Offset(0.60, 0.24),
  ];

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 100), (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (bittiMi) return;
        kalan -= 0.1;
        if (kalan <= 0) {
          kalan = 0;
          bittiMi = true;
          surukluyor = false;
          rozet = skor > 0 ? 'Süre bitti! Skor: $skor' : 'Süre bitti! Olmedi, tekrar dene';
        }
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void kontrol() {
    // Koni çarpması
    for (final Offset k in koniler) {
      if ((top - k).distance < 0.055) {
        top = const Offset(0.5, 0.92);
        rozet = 'Koniye çarptın! Olmedi, tekrar dene';
        return;
      }
    }
    // Bitiş çizgisi
    if (top.dy <= 0.10) {
      skor++;
      rozet = 'Harika! +1';
      widget.puanVer(1);
      top = const Offset(0.5, 0.92);
    }
  }

  @override
  Widget build(BuildContext context) {
    return miniOyunCerceve(
      baslik: '🚧 Çalım Parkuru',
      arkaplan: const Color(0xFFC8E6C9),
      skor: skor,
      hak: kalan.ceil(),
      rozet: bittiMi ? rozet : (rozet == 'Harika! +1' ? rozet : ''),
      geri: widget.geri,
      aciklama: 'Topu parmağınla sürükle, konilere değmeden üstteki bitiş çizgisine ulaş! Kalan saniye hak yerine geçer.',
      saha: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          return GestureDetector(
            onPanStart: (DragStartDetails d) {
              if (bittiMi) return;
              setState(() => surukluyor = true);
            },
            onPanUpdate: (DragUpdateDetails d) {
              if (bittiMi || !surukluyor) return;
              setState(() {
                top = Offset(
                  (top.dx + d.delta.dx / c.maxWidth).clamp(0.04, 0.96),
                  (top.dy + d.delta.dy / c.maxHeight).clamp(0.05, 0.96),
                );
                kontrol();
              });
            },
            onPanEnd: (DragEndDetails d) => setState(() => surukluyor = false),
            child: CustomPaint(
              size: Size(c.maxWidth, c.maxHeight),
              painter: CalimPainter(top: top, koniler: koniler),
            ),
          );
        },
      ),
    );
  }
}

class CalimPainter extends CustomPainter {
  final Offset top;
  final List<Offset> koniler;
  CalimPainter({required this.top, required this.koniler});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    for (int i = 0; i < 8; i++) {
      canvas.drawRect(Rect.fromLTWH(0, h * i / 8, w, h / 8), Paint()..color = i.isEven ? const Color(0xFF2E7D32) : const Color(0xFF388E3C));
    }
    // Bitiş çizgisi
    canvas.drawRect(Rect.fromLTWH(0, h * 0.07, w, 6), Paint()..color = kAltin);
    final TextPainter tp = TextPainter(
      text: const TextSpan(text: 'BİTİŞ', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w / 2 - tp.width / 2, h * 0.02));
    // Koniler (turuncu üçgen)
    for (final Offset k in koniler) {
      final Offset g = Offset(k.dx * w, k.dy * h);
      final Path koni = Path()
        ..moveTo(g.dx, g.dy - 12)
        ..lineTo(g.dx + 10, g.dy + 8)
        ..lineTo(g.dx - 10, g.dy + 8)
        ..close();
      canvas.drawPath(koni, Paint()..color = kTuruncu);
      canvas.drawRect(Rect.fromLTWH(g.dx - 13, g.dy + 8, 26, 4), Paint()..color = kTuruncu);
      canvas.drawRect(Rect.fromLTWH(g.dx - 7, g.dy - 2, 14, 3), Paint()..color = Colors.white);
    }
    miniTopCiz(canvas, Offset(top.dx * w, top.dy * h), 13);
  }

  @override
  bool shouldRepaint(covariant CalimPainter oldDelegate) => true;
}

// ---------- Mesajlar ----------

class MesajlarEkrani extends StatefulWidget {
  final Map<String, dynamic> kariyer;
  const MesajlarEkrani({super.key, required this.kariyer});

  @override
  State<MesajlarEkrani> createState() => _MesajlarEkraniState();
}

class _MesajlarEkraniState extends State<MesajlarEkrani> {
  IconData ikon(String kim) {
    switch (kim) {
      case 'Menajer':
        return Icons.business_center;
      case 'Teknik Direktör':
        return Icons.sports;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> m = kListe(widget.kariyer, 'mesajlar');
    for (final dynamic e in m) {
      if (e is Map) (e as Map<dynamic, dynamic>)['okundu'] = true;
    }
    final List<dynamic> teklifler = kListe(widget.kariyer, 'teklifler');
    final bool teklifVar = teklifler.any((dynamic e) {
      final Map<String, dynamic> t = Map<String, dynamic>.from(e as Map<dynamic, dynamic>);
      return t['durum'] == 'bekliyor';
    });
    return altEkran(
      baslik: '✉️ Mesajlar',
      child: Column(
        children: <Widget>[
          if (teklifVar)
            Padding(
              padding: const EdgeInsets.all(12),
              child: buyukButon(
                yazi: '📩 Transfer Teklifleri (${teklifler.length})',
                renk: kTuruncu,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext c) => TransferTeklifleriEkrani(kariyer: widget.kariyer),
                    ),
                  );
                  setState(() {});
                },
              ),
            ),
          Expanded(
            child: m.isEmpty
                ? const Center(child: Text('Henüz mesaj yok', style: TextStyle(fontSize: 20)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: m.length,
                    itemBuilder: (BuildContext context, int i) {
                      final Map<String, dynamic> msg = Map<String, dynamic>.from(m[i] as Map<dynamic, dynamic>);
                      final String kim = (msg['kim'] ?? 'normal') as String;
                      return Card(
                        color: kim == 'Menajer' ? const Color(0xFFE3F2FD) : (kim == 'Teknik Direktör' ? const Color(0xFFE8F5E9) : Colors.white),
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: Icon(ikon(kim), size: 34, color: kim == 'Menajer' ? Colors.blue : (kim == 'Teknik Direktör' ? kYesil : Colors.grey)),
                          title: Text((msg['kimden'] ?? '') as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text((msg['metin'] ?? '') as String, style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------- Transfer Teklifleri (◀ ▶ gezinme, görev barları) ----------

class TransferTeklifleriEkrani extends StatefulWidget {
  final Map<String, dynamic> kariyer;
  const TransferTeklifleriEkrani({super.key, required this.kariyer});

  @override
  State<TransferTeklifleriEkrani> createState() => _TransferTeklifleriEkraniState();
}

class _TransferTeklifleriEkraniState extends State<TransferTeklifleriEkrani> {
  int sayfa = 0;

  double ilerleme(Map<String, dynamic> gorev) {
    final String tip = (gorev['tip'] ?? 'gol') as String;
    final int hedef = ((gorev['hedef'] ?? 1) as num).toInt();
    final Map<String, dynamic> k = widget.kariyer;
    int deger;
    switch (tip) {
      case 'gol':
        deger = kInt(k, 'sezonGol');
        break;
      case 'asist':
        deger = kInt(k, 'sezonAsist');
        break;
      case 'ilk11':
        final int mac = kInt(k, 'sezonMac');
        deger = mac > 0 ? (kInt(k, 'ilk11Mac') * 100 ~/ mac) : 0;
        break;
      case 'rating':
        deger = (ortalamaRating(k) * 10).round();
        break;
      default:
        deger = 0;
    }
    return (deger / hedef).clamp(0.0, 1.0);
  }

  String ilerlemeYazi(Map<String, dynamic> gorev) {
    final String tip = (gorev['tip'] ?? 'gol') as String;
    final int hedef = ((gorev['hedef'] ?? 1) as num).toInt();
    final Map<String, dynamic> k = widget.kariyer;
    switch (tip) {
      case 'gol':
        return '${kInt(k, 'sezonGol')}/$hedef';
      case 'asist':
        return '${kInt(k, 'sezonAsist')}/$hedef';
      case 'ilk11':
        final int mac = kInt(k, 'sezonMac');
        final int y = mac > 0 ? (kInt(k, 'ilk11Mac') * 100 ~/ mac) : 0;
        return '%$y/%$hedef';
      case 'rating':
        return '${(ortalamaRating(k)).toStringAsFixed(1)}/${(hedef / 10).toStringAsFixed(1)}';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> teklifler = kListe(widget.kariyer, 'teklifler');
    if (teklifler.isEmpty) {
      return altEkran(baslik: '📩 Transfer Teklifleri', child: const Center(child: Text('Şu an teklif yok', style: TextStyle(fontSize: 20))));
    }
    sayfa = sayfa.clamp(0, teklifler.length - 1);
    final Map<String, dynamic> t = Map<String, dynamic>.from(teklifler[sayfa] as Map<dynamic, dynamic>);
    final String takimAd = (t['takim'] ?? '') as String;
    final List<dynamic> gorevler = (t['gorevler'] ?? <dynamic>[]) as List<dynamic>;
    final String durum = (t['durum'] ?? 'bekliyor') as String;
    return altEkran(
      baslik: '📩 Transfer Teklifleri',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 32),
                  onPressed: sayfa > 0 ? () => setState(() => sayfa--) : null,
                ),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: <Widget>[
                          rozet(takimAd, 80),
                          const SizedBox(height: 8),
                          Text(takimAd, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('${(t['ulke'] ?? '') as String} 3. Ligi', style: const TextStyle(fontSize: 15, color: Colors.black54)),
                          const SizedBox(height: 12),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('İstekler:', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 6),
                          for (final dynamic gd in gorevler)
                            Builder(
                              builder: (BuildContext c) {
                                final Map<String, dynamic> g = Map<String, dynamic>.from(gd as Map<dynamic, dynamic>);
                                final double p = ilerleme(g);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Expanded(child: Text((g['metin'] ?? '') as String, style: const TextStyle(fontSize: 15))),
                                          Text(ilerlemeYazi(g), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kYesil)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: p,
                                          minHeight: 10,
                                          backgroundColor: Colors.grey.shade300,
                                          valueColor: AlwaysStoppedAnimation<Color>(p >= 1.0 ? kYesil : kTuruncu),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 32),
                  onPressed: sayfa < teklifler.length - 1 ? () => setState(() => sayfa++) : null,
                ),
              ],
            ),
            Text('${sayfa + 1}/${teklifler.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (durum == 'bekliyor')
              Row(
                children: <Widget>[
                  Expanded(
                    child: buyukButon(
                      yazi: '✍ Kabul Et',
                      renk: kYesil,
                      onPressed: () {
                        setState(() {
                          t['durum'] = 'kabul';
                          teklifler[sayfa] = t;
                          widget.kariyer['teklifler'] = teklifler;
                          widget.kariyer['transferTakim'] = takimAd;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sezon sonunda $takimAd takımına transfer olacaksın!')));
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: buyukButon(
                      yazi: '✖ Reddet',
                      renk: Colors.red.shade400,
                      onPressed: () {
                        setState(() {
                          t['durum'] = 'reddedildi';
                          teklifler[sayfa] = t;
                          widget.kariyer['teklifler'] = teklifler;
                        });
                      },
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: durum == 'kabul' ? const Color(0xFFC8E6C9) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  durum == 'kabul' ? '✅ Bu teklifi kabul ettin! Sezon sonunda transfer gerçekleşecek.' : '❌ Bu teklifi reddettin.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------- Puan Durumu ----------

class PuanDurumuEkrani extends StatelessWidget {
  final Map<String, dynamic> kariyer;
  const PuanDurumuEkrani({super.key, required this.kariyer});

  @override
  Widget build(BuildContext context) {
    final String ulke = kStr(kariyer, 'ulke');
    final List<TakimBilgi> lig = ligTakimlari(ulke);
    final List<dynamic> tabloHam = kListe(kariyer, 'tablo');
    final List<Map<String, dynamic>> satirlar = <Map<String, dynamic>>[
      for (final dynamic e in tabloHam) Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
    ];
    satirlar.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final int pa = ((a['p'] ?? 0) as num).toInt();
      final int pb = ((b['p'] ?? 0) as num).toInt();
      if (pa != pb) return pb - pa;
      final int ava = ((a['ag'] ?? 0) as num).toInt() - ((a['yg'] ?? 0) as num).toInt();
      final int avb = ((b['ag'] ?? 0) as num).toInt() - ((b['yg'] ?? 0) as num).toInt();
      return avb - ava;
    });
    final String benimTakim = kStr(kariyer, 'takim');
    return altEkran(
      baslik: '🏆 $ulke 3. Ligi',
      child: ListView(
        padding: const EdgeInsets.all(10),
        children: <Widget>[
          const Row(
            children: <Widget>[
              SizedBox(width: 30, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: Text('Takım', style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 34, child: Text('G', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 34, child: Text('B', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 34, child: Text('M', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 44, child: Text('AV', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 40, child: Text('P', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          const Divider(),
          for (int i = 0; i < satirlar.length; i++)
            Builder(
              builder: (BuildContext c) {
                final Map<String, dynamic> s = satirlar[i];
                final int idx = ((s['i'] ?? 0) as num).toInt().clamp(0, lig.length - 1);
                final String ad = lig[idx].ad;
                final bool ben = ad == benimTakim;
                final int av = ((s['ag'] ?? 0) as num).toInt() - ((s['yg'] ?? 0) as num).toInt();
                return Container(
                  color: ben ? const Color(0xFFFFF9C4) : (i % 2 == 0 ? Colors.white : const Color(0xFFF1F8E9)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: <Widget>[
                      SizedBox(width: 30, child: Text('${i + 1}', style: TextStyle(fontWeight: ben ? FontWeight.bold : FontWeight.normal))),
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            rozet(ad, 26),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(ad, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: ben ? FontWeight.bold : FontWeight.normal)),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 34, child: Text('${(s['g'] ?? 0)}', textAlign: TextAlign.center)),
                      SizedBox(width: 34, child: Text('${(s['b'] ?? 0)}', textAlign: TextAlign.center)),
                      SizedBox(width: 34, child: Text('${(s['m'] ?? 0)}', textAlign: TextAlign.center)),
                      SizedBox(width: 44, child: Text('$av', textAlign: TextAlign.center)),
                      SizedBox(width: 40, child: Text('${(s['p'] ?? 0)}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ---------- Kramponlar (mağaza + çark) ----------

class KramponlarEkrani extends StatefulWidget {
  final Map<String, dynamic> kariyer;
  const KramponlarEkrani({super.key, required this.kariyer});

  @override
  State<KramponlarEkrani> createState() => _KramponlarEkraniState();
}

class _KramponlarEkraniState extends State<KramponlarEkrani> with SingleTickerProviderStateMixin {
  int sekme = 0;
  late final AnimationController carkKontrol;
  double carkAcisi = 0;
  bool carkDonuyor = false;
  String carkSonuc = '';
  RewardedAd? odulluReklam;

  @override
  void initState() {
    super.initState();
    carkKontrol = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
    carkKontrol.addListener(() {
      setState(() {});
    });
    reklamiYukle();
  }

  @override
  void dispose() {
    carkKontrol.dispose();
    odulluReklam?.dispose();
    super.dispose();
  }

  // TODO: Yayın öncesi gerçek rewarded reklam birimi kimliği kullanılmalı (şu an Google test ID'si)
  void reklamiYukle() {
    RewardedAd.load(
      adUnitId: kRewardedReklamId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          odulluReklam = ad;
        },
        onAdFailedToLoad: (LoadAdError e) {
          if (!mounted) return;
          odulluReklam = null;
        },
      ),
    );
  }

  String bugun() {
    final DateTime d = DateTime.now();
    return '${d.year}-${d.month}-${d.day}';
  }

  int carkSayisi() {
    if (kStr(widget.kariyer, 'carkTarih') != bugun()) return 0;
    return kInt(widget.kariyer, 'carkSayi');
  }

  void carkSayiArttir() {
    widget.kariyer['carkTarih'] = bugun();
    widget.kariyer['carkSayi'] = carkSayisi() + 1;
  }

  bool sahipMi(int i) {
    for (final dynamic e in kListe(widget.kariyer, 'kramponlar')) {
      if ((e as num).toInt() == i) return true;
    }
    return false;
  }

  void satinAl(int i) {
    final int fiyat = (kKramponMagaza[i]['fiyat'] as num).toInt();
    final int altin = kInt(widget.kariyer, 'altin');
    if (sahipMi(i)) {
      widget.kariyer['aktifKrampon'] = i;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Krampon giyildi! ⚽')));
      return;
    }
    if (altin < fiyat) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yeterli altının yok! Gol at, asist yap, maç kazan! 💰')));
      return;
    }
    widget.kariyer['altin'] = altin - fiyat;
    final List<dynamic> env = kListe(widget.kariyer, 'kramponlar');
    env.add(i);
    widget.kariyer['kramponlar'] = env;
    widget.kariyer['aktifKrampon'] = i;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${kKramponMagaza[i]['ad']} satın alındı ve giyildi! 👟')));
  }

  void carkCevir() {
    if (carkDonuyor) return;
    if (carkSayisi() >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Günlük 10 çevirme hakkını doldurdun! Yarın tekrar gel.')));
      return;
    }
    final Random rr = Random();
    final int kazanan = rr.nextInt(kKramponMagaza.length);
    carkSayiArttir();
    setState(() {
      carkDonuyor = true;
      carkSonuc = '';
    });
    // Gösterge üstte (-pi/2). CarkPainter'da dilim i'nin merkezi: (i/n)*2π - π/2 + π/n + açı.
    // Kazanan dilimin merkezi göstergeye denk gelsin: açı ≡ -kazanan*dilim - dilim/2 (mod 2π)
    final double dilimBoyu = 2 * pi / kKramponMagaza.length;
    final double baslangic = carkAcisi % (2 * pi);
    final double hedefAci = (-kazanan * dilimBoyu - dilimBoyu / 2) % (2 * pi);
    final double kalan = (hedefAci - baslangic) % (2 * pi);
    carkKontrol.reset();
    final Animation<double> anim = Tween<double>(begin: baslangic, end: baslangic + 5 * 2 * pi + kalan).animate(CurvedAnimation(parent: carkKontrol, curve: Curves.decelerate));
    anim.addListener(() {
      carkAcisi = anim.value;
    });
    carkKontrol.forward().then((_) {
      if (!mounted) return;
      setState(() {
        carkDonuyor = false;
        final List<dynamic> env = kListe(widget.kariyer, 'kramponlar');
        if (!sahipMi(kazanan)) {
          env.add(kazanan);
          widget.kariyer['kramponlar'] = env;
        }
        carkSonuc = '🎉 ${kKramponMagaza[kazanan]['ad']} kazandın!';
      });
    });
  }

  void reklamlaCevir() {
    if (carkSayisi() >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Günlük 10 çevirme hakkını doldurdun!')));
      return;
    }
    final RewardedAd? ad = odulluReklam;
    if (ad == null) {
      reklamiYukle();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reklam şu an yüklenemedi, biraz sonra tekrar dene.')));
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd a) {
        a.dispose();
        if (!mounted) return;
        odulluReklam = null;
        reklamiYukle();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd a, AdError e) {
        a.dispose();
        if (!mounted) return;
        odulluReklam = null;
        reklamiYukle();
      },
    );
    ad.show(onUserEarnedReward: (AdWithoutView a, RewardItem r) {
      if (!mounted) return;
      carkCevir();
    });
  }

  @override
  Widget build(BuildContext context) {
    final int aktif = kInt(widget.kariyer, 'aktifKrampon', -1);
    return altEkran(
      baslik: '👟 Kramponlar',
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sekme == 0 ? kYesil : Colors.white,
                      foregroundColor: sekme == 0 ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => setState(() => sekme = 0),
                    child: const Text('🛒 Krampon Satın Al', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sekme == 1 ? kYesil : Colors.white,
                      foregroundColor: sekme == 1 ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => setState(() => sekme = 1),
                    child: const Text('🎡 Çark Çevir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: sekme == 0 ? magaza(aktif) : cark()),
        ],
      ),
    );
  }

  Widget magaza(int aktif) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              const Icon(Icons.monetization_on, color: kAltin, size: 30),
              const SizedBox(width: 6),
              Text('${kInt(widget.kariyer, 'altin')}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: kKramponMagaza.length,
            itemBuilder: (BuildContext context, int i) {
              final Map<String, dynamic> krampon = kKramponMagaza[i];
              final int guc = (krampon['guc'] as num).toInt();
              final bool sahip = sahipMi(i);
              final bool giyili = aktif == i;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: giyili ? const BorderSide(color: kYesil, width: 3) : BorderSide.none),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(color: Color((krampon['renk'] as num).toInt()), shape: BoxShape.circle),
                        child: const Center(child: Text('👟', style: TextStyle(fontSize: 30))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('${krampon['ad']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: LinearProgressIndicator(
                                      value: guc / 27,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey.shade300,
                                      valueColor: const AlwaysStoppedAnimation<Color>(kTuruncu),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('⚡$guc', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTuruncu)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: giyili ? kYesil : (sahip ? Colors.blueGrey : kTuruncu),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => satinAl(i),
                        child: Text(giyili ? 'Giyili ✓' : (sahip ? 'Giy' : '💰${krampon['fiyat']}'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget cark() {
    final int kalan = 10 - carkSayisi();
    final bool bedavaVar = carkSayisi() == 0;
    return Column(
      children: <Widget>[
        const SizedBox(height: 8),
        Text('Bugünkü çevirme: ${carkSayisi()}/10', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Expanded(
          child: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: CustomPaint(
                painter: CarkPainter(acisi: carkAcisi),
              ),
            ),
          ),
        ),
        if (carkSonuc.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(carkSonuc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kYesil)),
          ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (bedavaVar)
                buyukButon(yazi: carkDonuyor ? '🎡 Dönüyor...' : '🎁 Ücretsiz Çevir (günde 1)', renk: kYesil, onPressed: carkDonuyor ? () {} : carkCevir)
              else if (kalan > 0)
                buyukButon(yazi: carkDonuyor ? '🎡 Dönüyor...' : '📺 Bir kez daha çevir (reklam izle)', renk: kTuruncu, onPressed: carkDonuyor ? () {} : reklamlaCevir)
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(14)),
                  child: const Text('Bugünlük hakkın bitti! Yarın tekrar gel. 😊', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class CarkPainter extends CustomPainter {
  final double acisi;
  CarkPainter({required this.acisi});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset merkez = Offset(size.width / 2, size.height / 2);
    final double yaricap = size.width / 2 - 8;
    final int n = kKramponMagaza.length;
    final Rect rect = Rect.fromCircle(center: merkez, radius: yaricap);
    canvas.save();
    canvas.translate(merkez.dx, merkez.dy);
    canvas.rotate(acisi);
    canvas.translate(-merkez.dx, -merkez.dy);
    for (int i = 0; i < n; i++) {
      final double bas = (i / n) * 2 * pi - pi / 2;
      final Paint p = Paint()..color = Color((kKramponMagaza[i]['renk'] as num).toInt());
      canvas.drawArc(rect, bas, 2 * pi / n, true, p);
      // dilim adı
      final double orta = bas + pi / n;
      final TextPainter tp = TextPainter(
        text: TextSpan(text: '${kKramponMagaza[i]['ad']}'.split(' ')[0], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, shadows: <Shadow>[Shadow(blurRadius: 3, color: Colors.black)])),
        textDirection: TextDirection.ltr,
      )..layout();
      final Offset pos = merkez + Offset(cos(orta) * yaricap * 0.65, sin(orta) * yaricap * 0.65);
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
    canvas.restore();
    // çerçeve + gösterge
    canvas.drawCircle(merkez, yaricap, Paint()..color = Colors.white ..style = PaintingStyle.stroke ..strokeWidth = 6);
    final Path ok = Path()
      ..moveTo(merkez.dx - 12, 4)
      ..lineTo(merkez.dx + 12, 4)
      ..lineTo(merkez.dx, 30)
      ..close();
    canvas.drawPath(ok, Paint()..color = kTuruncu);
  }

  @override
  bool shouldRepaint(covariant CarkPainter oldDelegate) => true;
}

// ---------- Özellikler ----------

class OzelliklerEkrani extends StatefulWidget {
  final Map<String, dynamic> kariyer;
  const OzelliklerEkrani({super.key, required this.kariyer});

  @override
  State<OzelliklerEkrani> createState() => _OzelliklerEkraniState();
}

class _OzelliklerEkraniState extends State<OzelliklerEkrani> {
  Map<String, dynamic> ozMap(String kod) {
    final Map<String, dynamic> oz = Map<String, dynamic>.from((widget.kariyer['ozellikler'] ?? <String, dynamic>{}) as Map<dynamic, dynamic>);
    return Map<String, dynamic>.from((oz[kod] ?? <String, dynamic>{'t': 60, 'e': 0}) as Map<dynamic, dynamic>);
  }

  void yazOz(String kod, Map<String, dynamic> o) {
    final Map<String, dynamic> oz = Map<String, dynamic>.from((widget.kariyer['ozellikler'] ?? <String, dynamic>{}) as Map<dynamic, dynamic>);
    oz[kod] = o;
    widget.kariyer['ozellikler'] = oz;
  }

  void arttir(String kod) {
    if (kInt(widget.kariyer, 'antPuani') <= 0) return;
    final Map<String, dynamic> o = ozMap(kod);
    final int t = ((o['t'] ?? 60) as num).toInt();
    final int e = ((o['e'] ?? 0) as num).toInt();
    if (t + e >= 99) return;
    o['e'] = e + 1;
    yazOz(kod, o);
    widget.kariyer['antPuani'] = kInt(widget.kariyer, 'antPuani') - 1;
    setState(() {});
  }

  void azalt(String kod) {
    final Map<String, dynamic> o = ozMap(kod);
    final int e = ((o['e'] ?? 0) as num).toInt();
    if (e <= 0) return; // tabanın altına inemez
    o['e'] = e - 1;
    yazOz(kod, o);
    widget.kariyer['antPuani'] = kInt(widget.kariyer, 'antPuani') + 1;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return altEkran(
      baslik: '💪 Özellikler',
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                const Icon(Icons.fitness_center, color: kYesil, size: 28),
                const SizedBox(width: 6),
                Text('Antrenman Puanı: ${kInt(widget.kariyer, 'antPuani')}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: <Widget>[
                for (final MapEntry<String, List<List<String>>> kat in kOzellikler.entries) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(kat.key, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kYesil)),
                  ),
                  for (final List<String> o in kat.value) ozellikSatir(o[0], o[1]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget ozellikSatir(String kod, String ad) {
    final Map<String, dynamic> o = ozMap(kod);
    final int t = ((o['t'] ?? 60) as num).toInt();
    final int e = ((o['e'] ?? 0) as num).toInt();
    final int deger = t + e;
    final bool puanVar = kInt(widget.kariyer, 'antPuani') > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red, size: 34),
              onPressed: e > 0 ? () => azalt(kod) : null,
            ),
            SizedBox(
              width: 44,
              child: Text('$deger', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: deger >= 75 ? kYesil : Colors.black87)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(ad, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: deger / 99,
                      minHeight: 7,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(deger >= 75 ? kYesil : kTuruncu),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: puanVar ? kYesil : Colors.grey, size: 34),
              onPressed: puanVar ? () => arttir(kod) : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Bilgiler ----------

class BilgilerEkrani extends StatefulWidget {
  final Map<String, dynamic> kariyer;
  const BilgilerEkrani({super.key, required this.kariyer});

  @override
  State<BilgilerEkrani> createState() => _BilgilerEkraniState();
}

class _BilgilerEkraniState extends State<BilgilerEkrani> {
  void formaNoDegistir() {
    int secili = kInt(widget.kariyer, 'formaNo', 99);
    showDialog<void>(
      context: context,
      builder: (BuildContext c) {
        return StatefulBuilder(
          builder: (BuildContext c, void Function(void Function()) setD) {
            return AlertDialog(
              title: const Text('👕 Forma Numarası'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('$secili', style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: kYesil)),
                  Slider(
                    value: secili.toDouble(),
                    min: 1,
                    max: 99,
                    divisions: 98,
                    activeColor: kTuruncu,
                    onChanged: (double v) => setD(() => secili = v.round()),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.pop(c), child: const Text('Vazgeç', style: TextStyle(fontSize: 18))),
                ElevatedButton(
                  onPressed: () {
                    widget.kariyer['formaNo'] = secili;
                    setState(() {});
                    Navigator.pop(c);
                  },
                  child: const Text('Kaydet', style: TextStyle(fontSize: 18)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget satir(String emoji, String baslik, String deger) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 28)),
        title: Text(baslik, style: const TextStyle(fontSize: 15, color: Colors.black54)),
        subtitle: Text(deger, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kariyer;
    return altEkran(
      baslik: 'ℹ️ Bilgiler',
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          satir('🧒', 'Oyuncu', '${kStr(k, 'ad')} ${kStr(k, 'soyad')}'),
          satir('🎂', 'Yaş', '${kInt(k, 'yas', 18)}'),
          satir('🌍', 'Ülke / Lig', '${kStr(k, 'ulke')} • ${kStr(k, 'lig')}'),
          satir('🛡', 'Takım', kStr(k, 'takim')),
          satir('🎯', 'Mevki', 'Santrafor'),
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Text('👕', style: TextStyle(fontSize: 28)),
              title: const Text('Forma Numarası', style: TextStyle(fontSize: 15, color: Colors.black54)),
              subtitle: Text('#${kInt(k, 'formaNo', 99)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kTuruncu, foregroundColor: Colors.white),
                onPressed: formaNoDegistir,
                child: const Text('Değiştir', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          satir('⚽', 'Gol (kariyer / sezon)', '${kInt(k, 'gol')} / ${kInt(k, 'sezonGol')}'),
          satir('👟', 'Asist (kariyer / sezon)', '${kInt(k, 'asist')} / ${kInt(k, 'sezonAsist')}'),
          satir('🏟', 'Maç (kariyer / sezon)', '${kInt(k, 'macSayisi')} / ${kInt(k, 'sezonMac')}'),
          satir('⭐', 'Reyting Ortalaması', ortalamaRating(k).toStringAsFixed(1)),
          satir('💰', 'Altın', '${kInt(k, 'altin')}'),
          satir('💪', 'Antrenman Puanı', '${kInt(k, 'antPuani')}'),
          satir('💼', 'Menajer', '${kStr(k, 'menajerAd')} (${kStr(k, 'menajerCinsiyet')})'),
        ],
      ),
    );
  }
}

// ---------- Maç Günü: Kadrolar ----------

class MacGunuEkrani extends StatelessWidget {
  final Map<String, dynamic> kariyer;
  final TakimBilgi rakip;
  final VoidCallback macaGec;
  const MacGunuEkrani({super.key, required this.kariyer, required this.rakip, required this.macaGec});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> ark = kListe(kariyer, 'arkadaslar');
    final List<String> benimIsimler = <String>[
      kStr(kariyer, 'ad'),
      for (final dynamic e in ark) e as String,
    ];
    final List<String> rakipIsimler = rakipOyunculari(rakip);
    final int benimNo = kInt(kariyer, 'formaNo', 99);
    final Random rr = Random(rakip.ad.length * 31 + kInt(kariyer, 'hafta', 1));
    final Set<int> rakipNoSet = <int>{...<int>[for (int i = 0; i < 11; i++) 1 + rr.nextInt(40)]};
    while (rakipNoSet.length < 11) {
      rakipNoSet.add(1 + rr.nextInt(50));
    }
    final List<int> rakipNolar = rakipNoSet.toList();
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              color: kYesil,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: const Center(child: Text('🏟 Maç Günü — Kadrolar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))),
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  // Kendi takımı
                  Expanded(
                    child: Container(
                      color: const Color(0xFFC8E6C9),
                      child: Column(
                        children: <Widget>[
                          const SizedBox(height: 8),
                          rozet(kStr(kariyer, 'takim'), 60),
                          Text(kStr(kariyer, 'takim'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: ListView.builder(
                              itemCount: 11,
                              itemBuilder: (BuildContext c, int i) {
                                final bool ben = i == 0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: ben ? kAltin : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        SizedBox(width: 34, child: Text('#${ben ? benimNo : i + 1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                                        Expanded(
                                          child: Text(benimIsimler[i], style: TextStyle(fontSize: 15, fontWeight: ben ? FontWeight.bold : FontWeight.normal)),
                                        ),
                                        if (ben) const Text('⭐ ST', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTuruncu)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Rakip takım
                  Expanded(
                    child: Container(
                      color: const Color(0xFFFFCDD2),
                      child: Column(
                        children: <Widget>[
                          const SizedBox(height: 8),
                          rozet(rakip.ad, 60),
                          Text(rakip.ad, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: ListView.builder(
                              itemCount: 11,
                              itemBuilder: (BuildContext c, int i) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                                    child: Row(
                                      children: <Widget>[
                                        SizedBox(width: 34, child: Text('#${rakipNolar[i]}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                                        Expanded(child: Text(rakipIsimler[i], style: const TextStyle(fontSize: 15))),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.black26,
              padding: const EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  Expanded(child: buyukButon(yazi: '← Geri', renk: const Color(0xFF546E7A), onPressed: () => Navigator.pop(context))),
                  const SizedBox(width: 10),
                  Expanded(child: buyukButon(yazi: 'Maça Geç →', renk: kYesil, onPressed: macaGec)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<String> rakipOyunculari(TakimBilgi rakip) {
  final List<String> havuz = List<String>.from(kOyuncuIsimleri[rakip.ulke] ?? kOyuncuIsimleri['Türkiye']!);
  final Random rr = Random(rakip.ad.hashCode ^ DateTime.now().millisecondsSinceEpoch);
  havuz.shuffle(rr);
  return havuz.take(11).toList();
}

// ---------- 2D Maç ----------

// ---------- 2D Mac: Yayin kamerasi, yatay saha, eklemli futbolcular ----------
// (Bu bolge sifirdan yazilmistir: kod ile cizim, sprite/asset YOK)

class MacEkrani extends StatefulWidget {
  final Map<String, dynamic> kariyer;
  final TakimBilgi rakip;
  final String zorluk;
  final void Function(Map<String, dynamic>) bitti;
  const MacEkrani({super.key, required this.kariyer, required this.rakip, required this.zorluk, required this.bitti});

  @override
  State<MacEkrani> createState() => _MacEkraniState();
}

// Konfeti parcacigi (gol kutlamasi)
class Konfeti {
  Offset p;
  Offset v;
  final Color c;
  double omur;
  final double boyut;
  Konfeti(this.p, this.v, this.c, this.omur, this.boyut);
}

// Kaleci dalisi / dusus toz parcacigi
class Toz {
  Offset p;
  Offset v;
  double omur;
  Toz(this.p, this.v, this.omur);
}

// Mikro sonuc karti (floating text)
class MikroKart {
  final String yazi;
  final Color renk;
  final bool buyuk;
  double t; // 0 -> 1 yasam
  MikroKart(this.yazi, this.renk, {this.buyuk = false}) : t = 0;
}

// Eklemli futbolcu figurunun saha durumu
class Futbolcu {
  Offset pos; // saha orani (0..1), x: 0=bizim kale (sol), 1=rakip kale (sag)
  final Offset ev; // dizilis (ev) pozisyonu
  double faz; // kosma cevrimi fazi
  double hizAni; // anlik hareket hizi (kosma animi icin)
  final int no;
  final bool kaleci;
  final int takim; // 0 = biz, 1 = rakip
  double sutT = 99; // sut animasyonu yasi (sn), 0..0.35 aktif
  double dalisT = 99; // kaleci dalis animasyonu yasi
  double dalisYon = 0; // -1 = ust kose, +1 = alt kose
  double sevincT = 99; // gol sevinci (diz ustu kayma) yasi
  double kolT = 99; // kol kaldirma sevinci (takim arkadasi)
  Futbolcu(this.pos, this.ev, this.no, this.kaleci, this.takim) : faz = 0, hizAni = 0;
}

class _MacEkraniState extends State<MacEkrani> {
  final Random r = Random();
  Timer? timer;
  Timer? secimTimer;
  Timer? sonucTimer;
  double dakika = 0;
  int hiz = 1;
  int skorBiz = 0;
  int skorRakip = 0;
  int gol = 0;
  int asist = 0;
  int pas = 0;
  int sut = 0;
  final List<String> spiker = <String>[];
  double spikerT = 99; // daktilo efekti: son satirin yasi (sn)
  final Map<int, int> sablonSayi = <int, int>{}; // ayni sablon mac basina max 2
  String fase = 'oyun'; // oyun, devre, sonuc, panel, roportaj
  bool devreYapildi = false;
  double devreT = 0; // devre karti sayac animasyonu
  double panelT = 0; // mac sonu karti flip animasyonu
  double panoZaman = 0; // LED pano donusu icin gercek zaman (sn)
  String roportajSoru = '';
  List<List<String>> roportajCevaplar = <List<String>>[];
  String roportajEtki = '';
  late final List<String> benimIsimler;
  late final List<String> rakipIsimler;
  late final TakimBilgi benimTakim;

  // --- Saha simulasyonu (yatay: x 0=bizim kale sol, 1=rakip kale sag) ---
  final List<Futbolcu> futbolcular = <Futbolcu>[];
  Offset top = const Offset(0.5, 0.5);
  int topTakim = 0; // 0 = biz, 1 = rakip
  int topOyuncu = 0; // topa sahip oyuncu indeksi (kendi listesi icinde)
  double pasSayac = 2.0;
  double sonrakiPozisyonDk = 9;
  bool macDurdu = false; // interaktif pozisyon / sinematik sirasinda saat durur

  // --- Top ucus animasyonu (sonuc ancak top hedefe varinca aciklanir) ---
  bool topUcuyor = false;
  double ucusT = 0;
  double ucusSure = 0.9; // sn (1x)
  double ucusZ = 0.0; // parabolik yukseklik zirvesi (px cinsinden oran)
  double ucusFalso = 0; // bezier orta nokta yanal ofseti
  Offset ucusBas = const Offset(0.5, 0.5);
  Offset ucusBit = const Offset(0.5, 0.5);
  VoidCallback? ucusSonu;
  double topZ = 0; // anlik yerden yukseklik (px)
  double topDonme = 0;
  final List<Offset> topTrail = <Offset>[];
  double ziplamaT = 99; // yere dusus sonrasi kucuk sekme

  // --- Kamera (yayin kamerasi: topu takip + pozisyon zoomu) ---
  double kameraPan = 0.5; // topun x'ine lerp ile kayar
  double kameraZoom = 1.0; // interaktifte 1.6
  double zoomHedef = 1.0;

  // --- Interaktif pozisyon ---
  bool interaktif = false;
  double uyariT = 0; // ATAK GELIYOR uyarisi kalan sure
  bool nisanAktif = false;
  double guc = 0; // 0..1 (ekran uzerinden asagi cekme)
  double falso = 0; // -1..1 (yatay kaydirma)
  bool surukluyor = false;
  double surukBasY = 0;
  double surukBasX = 0;
  double kaleciTatliYon = 0; // tatli nokta: kalecinin kayacagi yon (-1/1)
  Offset? nisanPasHedef; // pas oku hedefi (takim arkadasi)
  int nisanPasOyuncu = 0;
  bool interaktifPasMi = false; // secim: pas mi sut mu (release aninda belli)
  Offset nisanSutHedef = const Offset(1, 0.5);
  bool sonSansVerildi = false;

  // --- Sinematik / efekt ---
  double golSineT = 0; // GOOOL sinematigi kalan sure
  String golcuAdi = '';
  String asistAdi = '';
  double agEsneSol = 0;
  double agEsneSag = 0;
  double tribunZip = 0;
  double skorFlash = 0;
  int combo = 0;
  bool formdaRozet = false;
  double formdaT = 0;
  double oyuncuGlow = 0;
  bool g1 = false; // gorev: ilk sut
  bool g2 = false; // gorev: 2 isabetli pas
  bool g3 = false; // gorev: combo x3
  int isabetliPasSayisi = 0;
  final List<Konfeti> konfeti = <Konfeti>[];
  final List<Toz> tozlar = <Toz>[];
  final List<MikroKart> mikroKartlar = <MikroKart>[];

  static const List<Color> kKonfetiRenkler = <Color>[
    Color(0xFFE63946), Color(0xFFFFD54F), Color(0xFF57CC99),
    Color(0xFF4CC9F0), Color(0xFFFF70A6), Colors.white,
  ];

  static const Color kEvRenk = Color(0xFFE63946); // ev sahibi forma: kirmizi
  static const Color kRakipRenk = Color(0xFF1D3557); // rakip forma: lacivert
  static const Color kKaleciRenk = Color(0xFF57CC99); // fistik yesili

  @override
  void initState() {
    super.initState();
    benimTakim = takimBul(kStr(widget.kariyer, 'takim'));
    final List<String> havuz = List<String>.from(kOyuncuIsimleri[benimTakim.ulke] ?? kOyuncuIsimleri['Türkiye']!);
    havuz.shuffle(Random(kInt(widget.kariyer, 'hafta', 1) * 77 + 5));
    benimIsimler = havuz.take(11).toList();
    rakipIsimler = rakipOyunculari(widget.rakip);
    dizilisKur();
    spikerEkle('Hakem başlama düdüğünü çaldı! ${benimTakim.ad} sağa doğru hücum ediyor.');
    timer = Timer.periodic(const Duration(milliseconds: 40), (_) => tick());
  }

  // 4-4-2 dizilisi, YATAY saha: kaleci solda, forvetler saga yakin
  void dizilisKur() {
    futbolcular.clear();
    const List<Offset> evBiz = <Offset>[
      Offset(0.05, 0.50), // kaleci
      Offset(0.20, 0.18), Offset(0.20, 0.40), Offset(0.20, 0.60), Offset(0.20, 0.82), // defans
      Offset(0.42, 0.15), Offset(0.40, 0.38), Offset(0.40, 0.62), Offset(0.42, 0.85), // orta saha
      Offset(0.60, 0.35), Offset(0.60, 0.65), // forvet (0 = bizim oyuncumuz, ST)
    ];
    final Set<int> nolar = <int>{};
    final Random rr = Random(11);
    while (nolar.length < 11) {
      nolar.add(1 + rr.nextInt(40));
    }
    final List<int> noList = nolar.toList();
    final int benimNo = kInt(widget.kariyer, 'formaNo', 9);
    for (int i = 0; i < 11; i++) {
      futbolcular.add(Futbolcu(evBiz[i], evBiz[i], i == 10 ? benimNo : noList[i], i == 0, 0));
    }
    for (int i = 0; i < 11; i++) {
      final Offset e = Offset(1 - evBiz[i].dx, 1 - evBiz[i].dy);
      futbolcular.add(Futbolcu(e, e, 1 + r.nextInt(40), i == 0, 1));
    }
    // Bizim oyuncumuz (ST) listede index 10
    topOyuncu = 10;
    topTakim = 0;
    top = futbolcular[10].pos;
  }

  @override
  void dispose() {
    timer?.cancel();
    secimTimer?.cancel();
    sonucTimer?.cancel();
    super.dispose();
  }

  // ---------- Spiker: 15 sablon, mac basina max 2 tekrar ----------
  static const List<String> kSablonlar = <String>[
    '{t} topu orta sahada dolaştırıyor.',
    '{o} güzel bir çalımla rakibini geçti!',
    '{r} savunması yerinde, pozisyon vermiyorlar.',
    'Tribünler coşkuyla takımını destekliyor!',
    '{o} ara pası düşündü ama savunma araya girdi.',
    'Orta sahada büyük bir mücadele var.',
    '{t} kanatlardan yüklenmeye çalışıyor.',
    'Hakem oyunu devam ettirdi, tempo artıyor!',
    '{r} kontratak arıyor, dikkatli olmak lazım.',
    '{o} şık bir topuk pası yaptı, tribünler ayakta!',
    'Yağmur başladı, zemin ağırlaşıyor.',
    'Yedek kulübesinde hareketlenme var.',
    '{t} oyunun kontrolünü elinde tutuyor.',
    'Kaleciler bugün formda görünüyor.',
    'Maçın son bölümüne girilirken heyecan dorukta!',
  ];

  void spikerEkle(String s) {
    if (!mounted) return;
    setState(() {
      spiker.add(s);
      if (spiker.length > 3) spiker.removeAt(0);
      spikerT = 0;
    });
  }

  void spikerSablon() {
    final List<int> uygun = <int>[
      for (int i = 0; i < kSablonlar.length; i++)
        if ((sablonSayi[i] ?? 0) < 2) i,
    ];
    if (uygun.isEmpty) return;
    final int i = uygun[r.nextInt(uygun.length)];
    sablonSayi[i] = (sablonSayi[i] ?? 0) + 1;
    final String oyuncu = r.nextBool() ? benimIsimler[10] : benimIsimler[1 + r.nextInt(9)];
    spikerEkle(kSablonlar[i]
        .replaceAll('{t}', benimTakim.ad)
        .replaceAll('{r}', widget.rakip.ad)
        .replaceAll('{o}', oyuncu));
  }

  void mikro(String yazi, Color renk, {bool buyuk = false}) {
    if (mikroKartlar.length >= 5) mikroKartlar.removeAt(0);
    mikroKartlar.add(MikroKart(yazi, renk, buyuk: buyuk));
  }

  // ---------- Ana dongu: 40ms ----------
  void tick() {
    if (!mounted) return;
    const double dt = 0.04;
    setState(() {
      // Efekt yaslandirma
      spikerT += dt;
      panoZaman += dt;
      if (skorFlash > 0) skorFlash = (skorFlash - dt * 2).clamp(0.0, 1.0);
      if (tribunZip > 0) tribunZip = (tribunZip - dt * 1.4).clamp(0.0, 1.0);
      if (agEsneSol > 0) agEsneSol = (agEsneSol - dt * 1.8).clamp(0.0, 1.0);
      if (agEsneSag > 0) agEsneSag = (agEsneSag - dt * 1.8).clamp(0.0, 1.0);
      if (formdaT > 0) formdaT = (formdaT - dt * 0.5).clamp(0.0, 1.0);
      if (oyuncuGlow > 0) oyuncuGlow = (oyuncuGlow - dt * 0.8).clamp(0.0, 1.0);
      for (final MikroKart m in mikroKartlar) {
        m.t += dt * 0.9;
      }
      mikroKartlar.removeWhere((MikroKart m) => m.t >= 1);
      // Parcaciklar (max 30)
      for (final Konfeti k in konfeti) {
        k.p += k.v * dt; // mantiksal koordinat (0..1)
        k.v = Offset(k.v.dx * 0.985, k.v.dy + 0.55 * dt);
        k.omur -= dt;
      }
      konfeti.removeWhere((Konfeti k) => k.omur <= 0);
      for (final Toz t2 in tozlar) {
        t2.p += t2.v * dt;
        t2.v = Offset(t2.v.dx, t2.v.dy + 0.4 * dt);
        t2.omur -= dt;
      }
      if (ziplamaT < 1) ziplamaT += dt; // yere dusus sonrasi kucuk sekme
      tozlar.removeWhere((Toz t2) => t2.omur <= 0);
      if (konfeti.length > 24) konfeti.removeRange(0, konfeti.length - 24);
      if (tozlar.length > 6) tozlar.removeRange(0, tozlar.length - 6);

      // Futbolcu animasyon yaslari
      for (final Futbolcu f in futbolcular) {
        if (f.sutT < 1) f.sutT += dt;
        if (f.dalisT < 2) f.dalisT += dt;
        if (f.sevincT < 2) f.sevincT += dt;
        if (f.kolT < 2) f.kolT += dt;
      }

      // Kamera: topun x'ine yumusak lerp + zoom lerp
      final double hedefPan = topUcuyor ? top.dx : (0.5 + (top.dx - 0.5) * 1.0);
      kameraPan += (hedefPan.clamp(0.2, 0.8) - kameraPan) * (dt * 3.2);
      kameraZoom += (zoomHedef - kameraZoom) * (dt * 4.0);

      // GOOOL sinematigi
      if (golSineT > 0) {
        golSineT -= dt;
        if (golSineT <= 0) {
          golSineT = 0;
          macDurdu = false;
          zoomHedef = 1.0;
          kickoffDiz();
        }
        topTrailGuncelle();
        return;
      }

      // Devre / mac sonu
      if (fase == 'devre' || fase == 'panel' || fase == 'roportaj' || fase == 'sonuc') {
        if (fase == 'devre') devreT += dt;
        if (fase == 'panel') panelT += dt;
        return;
      }

      // Interaktif pozisyon uyari fazi
      if (interaktif) {
        if (uyariT > 0) {
          uyariT -= dt;
          if (uyariT <= 0) {
            uyariT = 0;
            nisanAktif = true;
          }
        }
        // saat durmus durumda; oyuncular yerinde nefes alir
        topTrailGuncelle();
        return;
      }

      // Top ucusu
      if (topUcuyor) {
        final double hizCarpan = (hiz == 10) ? 2.2 : (hiz == 2 ? 1.4 : 1.0);
        ucusT += dt * hizCarpan / ucusSure;
        if (ucusT >= 1) {
          ucusT = 1;
        }
        // Bezier: falso orta nokta ofseti
        final Offset orta = Offset(
          (ucusBas.dx + ucusBit.dx) / 2,
          (ucusBas.dy + ucusBit.dy) / 2 + ucusFalso * 0.18,
        );
        final double t = ucusT;
        final double mt = 1 - t;
        top = Offset(
          mt * mt * ucusBas.dx + 2 * mt * t * orta.dx + t * t * ucusBit.dx,
          mt * mt * ucusBas.dy + 2 * mt * t * orta.dy + t * t * ucusBit.dy,
        );
        topZ = 4 * t * (1 - t) * ucusZ; // parabolik z (zirve mesafe/4 px)
        topDonme += dt * 14;
        if (ucusT >= 1) {
          topUcuyor = false;
          ziplamaT = 0;
          final VoidCallback? cb = ucusSonu;
          ucusSonu = null;
          cb?.call(); // SONUC ancak top varinca aciklanir
        }
        topTrailGuncelle();
        oyuncuHedefleri(dt, false);
        return;
      }

      // Mac saati: 1x = 1.2 sn/dk
      if (!macDurdu) {
        // Skora gore tempo
        double tempo = 1.0;
        final int fark = skorBiz - skorRakip;
        if (fark < 0 && dakika >= 60) tempo = 1.8; // yenik 60'+ hizli
        if (fark > 0 && dakika >= 80) tempo = 0.7; // onde 80'+ yavas
        if (fark.abs() >= 3) tempo = 1.6; // formalite
        dakika += (hiz / 30.0) * tempo;
        topDonme += dt * 3 * hiz;
      }

      if (!devreYapildi && dakika >= 45) {
        devreYapildi = true;
        dakika = 45;
        fase = 'devre';
        devreT = 0;
        spikerEkle('İlk yarı sona erdi! Takımlar soyunma odasında.');
        return;
      }
      if (dakika >= 90) {
        dakika = 90;
        macBitti();
        return;
      }

      // Genel oyun: pas sayaci
      pasSayac -= dt * (hiz == 10 ? 6 : (hiz == 2 ? 2 : 1));
      if (pasSayac <= 0 && !macDurdu) {
        genelPas();
      }

      // Pozisyon eventi 6-14 dk araliginda
      if (dakika >= sonrakiPozisyonDk) {
        sonrakiPozisyonDk = dakika + 6 + r.nextDouble() * 8;
        pozisyonYarat();
      }

      // Top tasinmasi (sahip oyuncu hafif ilerler)
      final Futbolcu sahip = futbolcular[topTakim * 11 + topOyuncu];
      top = sahip.pos + Offset(topTakim == 0 ? 0.008 : -0.008, 0);
      oyuncuHedefleri(dt, true);
      topTrailGuncelle();

      // Ara sira atmosfer spikeri
      if (r.nextDouble() < 0.0012 * hiz) spikerSablon();
    });
  }

  void topTrailGuncelle() {
    topTrail.add(Offset(top.dx, top.dy));
    if (topTrail.length > 8) topTrail.removeAt(0);
  }

  // Oyunculari ev/hedef kurallarina gore hareket ettir
  void oyuncuHedefleri(double dt, bool kosma) {
    final double adim = dt * (hiz == 10 ? 2.2 : 1.0) * 0.16;
    final Futbolcu sahip = futbolcular[topTakim * 11 + topOyuncu];
    for (int i = 0; i < 22; i++) {
      final Futbolcu f = futbolcular[i];
      Offset hedef = f.ev;
      final bool topTakimi = (i ~/ 11) == topTakim;
      if (f.kaleci) {
        hedef = f.ev + Offset(0, (top.dy - 0.5) * 0.12);
      } else if (i == topTakim * 11 + topOyuncu) {
        // Top sahibi rakip kaleye ilerler
        final double ileri = topTakim == 0 ? 0.06 : -0.06;
        hedef = (f.pos + Offset(ileri, (0.5 - f.pos.dy) * 0.2)).clamp01();
      } else {
        // En yakin 2 pres/destek
        final List<int> sirali = <int>[
          for (int j = (i ~/ 11) * 11; j < (i ~/ 11) * 11 + 11; j++) j,
        ]..sort((int a, int b) => (futbolcular[a].pos - top).distance.compareTo((futbolcular[b].pos - top).distance));
        final int sira = sirali.indexOf(i);
        if (sira >= 0 && sira < 2 && !topTakimi) {
          hedef = top; // pres
        } else if (sira >= 0 && sira < 2 && topTakimi) {
          hedef = (top + Offset(topTakim == 0 ? 0.06 : -0.06, (i.isEven ? 1 : -1) * 0.08)).clamp01(); // destek
        } else {
          // ev + top ofseti, evden max %25 uzaklasma
          final Offset o = f.ev + Offset((top.dx - 0.5) * 0.22, (top.dy - 0.5) * 0.25);
          final Offset fark = o - f.ev;
          final double m = fark.distance;
          hedef = m > 0.25 ? f.ev + fark * (0.25 / m) : o;
        }
      }
      final Offset d = hedef - f.pos;
      final double mes = d.distance;
      if (mes > 0.004) {
        final double k = mes < adim ? mes : adim;
        f.pos += d / mes * k;
        f.hizAni = kosma ? (k / dt).clamp(0.0, 1.0) : 0.3;
      } else {
        f.hizAni = 0;
      }
      f.faz += dt * (4 + f.hizAni * 9);
    }
    sahip.hizAni = max(sahip.hizAni, 0.35);
  }

  // Genel paslasma (dusuk z, hizli duz top)
  void genelPas() {
    pasSayac = 1.2 + r.nextDouble() * 1.8;
    final int base = topTakim * 11;
    int hedef = r.nextInt(11);
    if (hedef == topOyuncu) hedef = (hedef + 3) % 11;
    final Futbolcu h = futbolcular[base + hedef];
    // Kisa top kaybi sansi
    final bool kayip = r.nextDouble() < (topTakim == 0 ? 0.10 : 0.16);
    topUcusuBasla(
      futbolcular[base + topOyuncu].pos,
      h.pos,
      sure: 0.5,
      z: 6,
      sonuc: () {
        if (kayip) {
          topTakim = 1 - topTakim;
          topOyuncu = r.nextInt(11);
          if (topTakim == 1 && r.nextDouble() < 0.35) mikro('TOP KAYBI!', const Color(0xFFFF8A80));
        } else {
          topOyuncu = hedef;
        }
      },
    );
  }

  void topUcusuBasla(Offset bas, Offset bit, {required double sure, required double z, double falso = 0, VoidCallback? sonuc}) {
    topUcuyor = true;
    ucusT = 0;
    ucusSure = sure;
    ucusZ = z;
    ucusFalso = falso;
    ucusBas = bas;
    ucusBit = bit;
    ucusSonu = sonuc;
    topTrail.clear();
  }

  // ---------- Pozisyon eventleri ----------
  void pozisyonYarat() {
    if (interaktif || topUcuyor || golSineT > 0) return;
    // SON SANS: 88'+ fark <= 1, garanti interaktif
    final bool sonSans = !sonSansVerildi && dakika >= 88 && (skorBiz - skorRakip).abs() <= 1;
    if (sonSans) sonSansVerildi = true;
    final bool interaktifMi = sonSans || r.nextDouble() < 0.40;
    if (interaktifMi && topTakim == 0) {
      interaktifBaslat(sonSans: sonSans);
    } else {
      aiPozisyon();
    }
  }

  // %60 AI pozisyon: top animasyonuyla oynatilir, sonuc top varinca
  void aiPozisyon() {
    final int gucluZorluk = widget.zorluk == 'Kolay' ? -8 : (widget.zorluk == 'Zor' ? 8 : 0);
    final int benimGuc = ozellik(widget.kariyer, 'sut') + kramponGucu(widget.kariyer) - gucluZorluk;
    final bool bizAtak = topTakim == 0 ? r.nextDouble() < 0.62 : r.nextDouble() < 0.35;
    if (bizAtak) {
      // Bizim takim pozisyonu: sut veya ara pasi
      final Futbolcu atici = futbolcular[1 + r.nextInt(10)];
      final bool sutMu = r.nextDouble() < 0.5;
      atici.sutT = 0;
      if (sutMu) {
        final Offset hedef = Offset(0.995, 0.5 + (r.nextDouble() - 0.5) * 0.30);
        final double basari = (benimGuc / 100.0) * 0.55 + r.nextDouble() * 0.5;
        futbolcular[11].dalisT = 0; // rakip kaleci dalis
        futbolcular[11].dalisYon = r.nextBool() ? -1 : 1;
        topUcusuBasla(atici.pos, hedef, sure: 0.7, z: 14 + (hedef - atici.pos).distance * 60, sonuc: () {
          if (atici.no == kInt(widget.kariyer, 'formaNo', 9) || atici == futbolcular[10]) {
            sut++;
            if (!g1) g1 = true;
          }
          if (basari > 0.72) {
            golAt(true, atici);
          } else if (basari > 0.60) {
            mikro('KALECİ ÇIKARDI!', const Color(0xFF4CC9F0));
            spikerEkle('${aticiIsim(atici)} vurdu, kaleci köşeden çıkardı!');
            tozSerp(hedef);
            rakipTopaBasla();
          } else if (basari > 0.52) {
            mikro('DİREK!', kAltin, buyuk: true);
            spikerEkle('Top direkten döndü! İnanılmaz bir an!');
            rakipTopaBasla();
          } else {
            mikro('DIŞARI!', const Color(0xFFFF8A80));
            spikerEkle('${aticiIsim(atici)} şutunu çekti ama top auta gidiyor.');
            combo = 0;
            rakipTopaBasla();
          }
        });
      } else {
        // Ara pasi: isabet sayilir
        final Futbolcu h = futbolcular[9 + r.nextInt(2)];
        topUcusuBasla(atici.pos, h.pos, sure: 0.5, z: 8, sonuc: () {
          if (r.nextDouble() < 0.7) {
            isabetliPasKaydet(false);
          } else {
            rakipTopaBasla();
          }
        });
      }
    } else {
      // Rakip atak
      final Futbolcu atici = futbolcular[11 + 1 + r.nextInt(10)];
      atici.sutT = 0;
      final Offset hedef = Offset(0.005, 0.5 + (r.nextDouble() - 0.5) * 0.30);
      futbolcular[0].dalisT = 0; // bizim kaleci
      futbolcular[0].dalisYon = r.nextBool() ? -1 : 1;
      topUcusuBasla(atici.pos, hedef, sure: 0.8, z: 16 + (hedef - atici.pos).distance * 55, sonuc: () {
        final double savunma = 0.55 + (ozellik(widget.kariyer, 'def') / 100.0) * 0.2 - gucluZorluk / 300.0;
        if (r.nextDouble() > savunma) {
          golAt(false, atici);
        } else {
          mikro('KALECİ ÇIKARDI!', const Color(0xFF4CC9F0));
          spikerEkle('Kalecimiz harika bir kurtarış yaptı!');
          tozSerp(hedef);
          bizTopaBasla();
        }
      });
    }
  }

  String aticiIsim(Futbolcu f) => f.takim == 0 ? benimIsimler[futbolcular.indexOf(f)] : rakipIsimler[futbolcular.indexOf(f) - 11];

  void rakipTopaBasla() {
    topTakim = 1;
    topOyuncu = r.nextInt(11);
  }

  void bizTopaBasla() {
    topTakim = 0;
    topOyuncu = 10;
  }

  void isabetliPasKaydet(bool oyuncudan) {
    pas++;
    isabetliPasSayisi++;
    if (isabetliPasSayisi >= 2 && !g2) g2 = true;
    combo++;
    if (combo >= 3 && !g3) {
      g3 = true;
      formdaRozet = true;
      formdaT = 3.0;
      oyuncuGlow = 3.0;
      mikro('FORMDAYIM x3 🔥', kAltin, buyuk: true);
    }
    if (oyuncudan) mikro('İSABET! +10', kYesil);
  }

  // ---------- Interaktif atak ----------
  void interaktifBaslat({bool sonSans = false}) {
    interaktif = true;
    macDurdu = true;
    uyariT = 1.5;
    nisanAktif = false;
    guc = 0;
    falso = 0;
    surukluyor = false;
    zoomHedef = 1.6;
    // Atak bolgesi: topu bizim ST'ye ver, pozisyonu ileri tasimadan (kamera zoomuyla)
    topTakim = 0;
    topOyuncu = 10;
    futbolcular[10].pos = Offset(0.72, 0.5);
    top = futbolcular[10].pos;
    // Pas hedefi: en yakin forvet/ortasaha
    nisanPasOyuncu = 8 + r.nextInt(2);
    final Futbolcu h = futbolcular[nisanPasOyuncu];
    h.pos = Offset(0.80, h.pos.dy < 0.5 ? 0.32 : 0.68);
    nisanPasHedef = h.pos;
    // Tatli nokta: kaleci bir koseye kayar, diger kose yesil
    kaleciTatliYon = r.nextBool() ? -1 : 1;
    HapticFeedback.mediumImpact();
    spikerEkle(sonSans
        ? 'SON ŞANS! ${benimIsimler[10]} topun başında... Bu an maçı değiştirebilir!'
        : 'ATAK GELİYOR! ${benimIsimler[10]} tehlikeli bölgede!');
    secimTimer?.cancel();
    secimTimer = Timer(const Duration(seconds: 6), () {
      if (interaktif && nisanAktif && mounted) {
        // 6sn otomatik: rastgele guc ile sut
        guc = 0.45 + r.nextDouble() * 0.4;
        interaktifSerbest(false, Offset(0.995, kaleciTatliYon > 0 ? 0.38 : 0.62));
      }
    });
  }

  // Parmak surukleme: asagi = guc, yatay = falso
  void surukBasla(DragStartDetails d) {
    if (!nisanAktif || topUcuyor) return;
    surukluyor = true;
    surukBasY = d.localPosition.dy;
    surukBasX = d.localPosition.dx;
  }

  void surukGuncelle(DragUpdateDetails d, double ekranYukseklik) {
    if (!surukluyor || !nisanAktif || topUcuyor) return;
    setState(() {
      guc = ((d.localPosition.dy - surukBasY) / (ekranYukseklik * 0.45)).clamp(0.0, 1.0);
      falso = ((d.localPosition.dx - surukBasX) / 160).clamp(-1.0, 1.0);
    });
  }

  void surukBitir(DragEndDetails d) {
    if (!surukluyor) return;
    surukluyor = false;
    if (!nisanAktif || topUcuyor) return;
    if (guc < 0.08) {
      guc = 0;
      falso = 0;
      return; // cok kisa cekis: iptal
    }
    // Guc az ise pas kabul, coksa sut (hedef: tatli koselerden biri, guc fazlaysa kale ustune)
    final bool sutMu = guc > 0.45;
    final Offset hedef = sutMu
        ? Offset(0.995, kaleciTatliYon > 0 ? 0.40 : 0.60)
        : (nisanPasHedef ?? const Offset(0.8, 0.5));
    interaktifSerbest(!sutMu, hedef);
  }

  // Sonuc top varmadan ASLA aciklanmaz
  void interaktifSerbest(bool pasMi, Offset hedef) {
    if (topUcuyor) return;
    secimTimer?.cancel();
    nisanAktif = false;
    interaktif = false; // top ucarken mac devam eder; sonuc varista aciklanir
    macDurdu = false;
    uyariT = 0;
    interaktifPasMi = pasMi;
    nisanSutHedef = hedef;
    final Futbolcu ben = futbolcular[10];
    ben.sutT = 0;
    zoomHedef = 1.0;
    final int pasGuc = ozellik(widget.kariyer, 'pas');
    final int sutGuc = ozellik(widget.kariyer, 'sut') + kramponGucu(widget.kariyer);
    // Tatli nokta: ideal guc sari bolge (0.55-0.85)
    final bool tatli = guc >= 0.55 && guc <= 0.85;
    if (pasMi) {
      final double isabetSansi = 0.55 + pasGuc / 200.0 + (tatli ? 0.15 : 0) - falso.abs() * 0.1;
      final double mesafe = (hedef - ben.pos).distance;
      topUcusuBasla(ben.pos, hedef, sure: 0.45 + mesafe * 0.5, z: 6, falso: falso * 0.4, sonuc: () {
        interaktifKapat();
        if (r.nextDouble() < isabetSansi) {
          isabetliPasKaydet(true);
          if (tatli) mikro('MÜKEMMEL ZAMANLAMA!', kAltin);
          // Asist sansi: pas forvete giderse takim arkadasi tamamlar
          if (tatli && r.nextDouble() < 0.45) {
            final Futbolcu ark = futbolcular[nisanPasOyuncu];
            ark.sutT = 0;
            asistAdi = benimIsimler[10];
            topUcusuBasla(ark.pos, Offset(0.995, 0.5 + (r.nextDouble() - 0.5) * 0.2), sure: 0.5, z: 18, sonuc: () {
              if (r.nextDouble() < 0.8) {
                asist++;
                golAt(true, ark, asistVar: true);
              } else {
                mikro('KALECİ ÇIKARDI!', const Color(0xFF4CC9F0));
                rakipTopaBasla();
              }
            });
          } else {
            spikerEkle('${benimIsimler[10]} isabetli pas attı, atak sürüyor.');
          }
        } else {
          mikro('TOP KAYBI!', const Color(0xFFFF8A80));
          combo = 0;
          spikerEkle('Pas isabetsiz, rakip topu kaptı.');
          rakipTopaBasla();
        }
      });
    } else {
      // SUT: guc cubuguna gore hiz ve z
      sut++;
      if (!g1) g1 = true;
      final double kalite = sutGuc / 100.0 + (tatli ? 0.25 : 0) - (guc > 0.85 ? 0.15 : 0) - falso.abs() * 0.06;
      final double mesafe = (hedef - ben.pos).distance;
      final bool kaleciDogruda = r.nextDouble() < 0.5;
      final Futbolcu k = futbolcular[11]; // rakip kaleci
      k.dalisT = 0;
      k.dalisYon = hedef.dy < 0.5 ? -1 : 1;
      final double zirve = 10 + guc * 26 + mesafe * 30;
      topUcusuBasla(ben.pos, hedef, sure: (0.85 - guc * 0.4).clamp(0.35, 0.9), z: zirve, falso: falso, sonuc: () {
        interaktifKapat();
        if (guc > 0.92) {
          mikro('DIŞARI! Fazla yüklendi!', const Color(0xFFFF8A80));
          spikerEkle('${benimIsimler[10]} topa çok sert vurdu, top üstten auta!');
          combo = 0;
          rakipTopaBasla();
          return;
        }
        final double sans = kalite + r.nextDouble() * 0.45;
        if (sans > 0.78 || (tatli && !kaleciDogruda && sans > 0.6)) {
          combo++;
          if (combo >= 3 && !g3) {
            g3 = true;
            formdaRozet = true;
            formdaT = 3.0;
            oyuncuGlow = 3.0;
          }
          golAt(true, ben);
        } else if (sans > 0.62) {
          mikro('KALECİ ÇIKARDI!', const Color(0xFF4CC9F0), buyuk: true);
          spikerEkle('${benimIsimler[10]} vurdu, kaleci harika uzandı!');
          tozSerp(hedef);
          isabetliPasKaydet(false);
          combo = max(combo, 1);
          rakipTopaBasla();
        } else if (sans > 0.50) {
          mikro('DİREK!', kAltin, buyuk: true);
          spikerEkle('Top direkten döndü! Şanssızlık!');
          rakipTopaBasla();
        } else {
          mikro('DIŞARI!', const Color(0xFFFF8A80));
          spikerEkle('Şut az farkla yandan auta gitti.');
          combo = 0;
          rakipTopaBasla();
        }
      });
    }
  }

  void interaktifKapat() {
    interaktif = false;
    macDurdu = false;
    uyariT = 0;
    nisanAktif = false;
    guc = 0;
    falso = 0;
    zoomHedef = 1.0;
  }

  // ---------- Gol ----------
  void golAt(bool bizim, Futbolcu atici, {bool asistVar = false}) {
    if (bizim) {
      skorBiz++;
      if (atici.takim == 0 && futbolcular.indexOf(atici) == 10) gol++;
    } else {
      skorRakip++;
    }
    golcuAdi = aticiIsim(atici);
    if (!asistVar) asistAdi = '';
    // Sinematik
    golSineT = 2.2;
    macDurdu = true;
    zoomHedef = 1.25;
    skorFlash = 1.0;
    tribunZip = 1.0;
    if (bizim) {
      agEsneSag = 1.0;
    } else {
      agEsneSol = 1.0;
    }
    // Konfeti (24)
    for (int i = 0; i < 24; i++) {
      konfeti.add(Konfeti(
        Offset(0.3 + r.nextDouble() * 0.4, 0.05),
        Offset((r.nextDouble() - 0.5) * 0.30, -0.10 - r.nextDouble() * 0.22),
        kKonfetiRenkler[r.nextInt(kKonfetiRenkler.length)],
        1.6 + r.nextDouble() * 0.9,
        4 + r.nextDouble() * 5,
      ));
    }
    // Golcu koseye kosar + diz ustu kayma; 2 takim arkadasi kol kaldirir
    atici.sevincT = 0;
    int say = 0;
    for (final Futbolcu f in futbolcular) {
      if (f.takim == atici.takim && f != atici && !f.kaleci && say < 2) {
        f.kolT = 0;
        say++;
      }
    }
    HapticFeedback.heavyImpact();
    spikerEkle(bizim
        ? 'GOOOL! $golcuAdi topu ağlara gönderdi! Skor $skorBiz-$skorRakip!'
        : 'Rakip golü buldu... $golcuAdi skoru $skorBiz-$skorRakip yaptı.');
  }

  void kickoffDiz() {
    // Kickoff dizilisi: herkes evine, top orta noktada
    for (final Futbolcu f in futbolcular) {
      f.pos = f.ev + Offset((r.nextDouble() - 0.5) * 0.03, (r.nextDouble() - 0.5) * 0.03);
    }
    topTakim = 0;
    topOyuncu = 10;
    top = const Offset(0.5, 0.5);
    topTrail.clear();
  }

  void tozSerp(Offset nerede) {
    for (int i = 0; i < 2; i++) {
      tozlar.add(Toz(nerede, Offset((r.nextDouble() - 0.5) * 0.08, -0.04 - r.nextDouble() * 0.05), 0.7));
    }
  }

  // ---------- Mac akisi ----------
  void devreyiGec() {
    fase = 'oyun';
    kickoffDiz();
    spikerEkle('İkinci yarı başladı! ${benimTakim.ad} galibiyet için sahada.');
  }

  void macBitti() {
    fase = 'panel';
    panelT = 0;
    final String sonucYazi = skorBiz > skorRakip
        ? 'Muhteşem galibiyet! ${benimTakim.ad} sahadan 3 puanla ayrılıyor!'
        : (skorBiz == skorRakip ? 'Maç berabere bitti, puanlar paylaşıldı.' : 'Maalesef mağlubiyet... Önümüzdeki maçlara bakacağız.');
    spikerEkle('Maç sona erdi! $sonucYazi');
  }

  double rating() {
    final bool galibiyet = skorBiz > skorRakip;
    final bool berabere = skorBiz == skorRakip;
    double rt = 6.0 + gol * 1.2 + asist * 0.9 + pas * 0.05 + (galibiyet ? 0.7 : (berabere ? 0.2 : -0.6));
    return rt.clamp(1.0, 10.0);
  }

  void roportajHazirla() {
    final bool iyi = rating() >= 7.5;
    final bool kotu = rating() < 5.0;
    if (gol >= 2) {
      roportajSoru = 'Muhteşem goller attın! Bu formun sırrı ne?';
    } else if (gol == 1) {
      roportajSoru = 'Bugün güzel bir gol attın. Maç hakkında ne söylersin?';
    } else if (iyi) {
      roportajSoru = 'Takımına büyük katkı sağladın. Nasıl hissediyorsun?';
    } else if (kotu) {
      roportajSoru = 'Bugün zor bir maçtı. Ne söylemek istersin?';
    } else {
      roportajSoru = 'Maç hakkında düşüncelerin neler?';
    }
    roportajCevaplar = <List<String>>[
      <String>['Takım arkadaşlarım olmadan başaramazdım, bu sonuç hepimizin! 🤝', 'Takım +10 · Taraftar +5 · Teknik Direktör +10'],
      <String>['Ben bu takımın yıldızıyım, daha çok gol atacağım! 😎', 'Takım −5 · Taraftar +10 · Teknik Direktör −5'],
      <String>['Daha çok çalışmam gerektiğini biliyorum, söz veriyorum! 💪', 'Takım +5 · Taraftar −5 · Teknik Direktör +10'],
    ];
    fase = 'roportaj';
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    String kisalt(String ad) => ad.length <= 3 ? ad.toUpperCase() : ad.substring(0, 3).toUpperCase();
    final bool hizliOzet = hiz == 10 && fase == 'oyun' && !interaktif && golSineT <= 0;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // --- Yayin tarzi skor bug + gorev cipleri ---
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFF0A1622), Color(0xFF0D1B2A)],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: kEvRenk, borderRadius: BorderRadius.circular(6)),
                        child: Text(kisalt(benimTakim.ad), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color.lerp(Colors.black.withOpacity(0.75), kAltin.withOpacity(0.9), skorFlash * 0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text('$skorBiz - $skorRakip', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: kRakipRenk, borderRadius: BorderRadius.circular(6)),
                        child: Text(kisalt(widget.rakip.ad), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                        child: Text("${dakika.floor()}'", style: const TextStyle(color: kAltin, fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                      // Hiz secimi 1x/2x/10x
                      for (final int hz in <int>[1, 2, 10])
                        GestureDetector(
                          onTap: () => setState(() => hiz = hz),
                          child: Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: hiz == hz ? kYesil : Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${hz}x', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Gorev cipleri + FORMDAYIM rozeti
                  Row(
                    children: <Widget>[
                      gorevCip('İlk şut', g1),
                      gorevCip('2 isabetli pas', g2),
                      gorevCip('Combo x3', g3),
                      if (formdaRozet)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: kAltin.withOpacity(0.25 + 0.5 * formdaT.clamp(0.0, 1.0)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: kAltin),
                          ),
                          child: const Text('🔥 FORMDAYIM x3', style: TextStyle(color: kAltin, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // --- Saha (portrede ekranin orta bandi) ---
            Expanded(
              child: fase == 'oyun'
                  ? (hizliOzet ? hizliOzetPanel() : sahaAlani())
                  : (fase == 'devre' ? devreKarti() : (fase == 'panel' ? macSonuKarti() : (fase == 'roportaj' ? roportajKarti() : sonucKarti()))),
            ),
            // --- Spiker seridi (daktilo efekti) ---
            Container(
              width: double.infinity,
              color: const Color(0xFF0A1622),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (int i = 0; i < spiker.length; i++)
                    Text(
                      i == spiker.length - 1 ? daktiloMetni(spiker[i]) : spiker[i],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: i == spiker.length - 1 ? Colors.white : Colors.white38,
                        fontSize: i == spiker.length - 1 ? 13 : 11,
                        fontWeight: i == spiker.length - 1 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String daktiloMetni(String s) {
    final int n = (spikerT / 0.02).floor(); // 20ms / harf
    return n >= s.length ? s : s.substring(0, n.clamp(0, s.length));
  }

  Widget gorevCip(String yazi, bool tamam) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tamam ? kYesil.withOpacity(0.35) : Colors.white10,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tamam ? kYesil : Colors.white24),
      ),
      child: Text('${tamam ? '✅' : '⬜'} $yazi', style: TextStyle(color: tamam ? Colors.white : Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  // 10x: karanlik hizli-ozet modu (spiker + dk + skor)
  Widget hizliOzetPanel() {
    return Container(
      color: const Color(0xFF070F18),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('⚡ HIZLI ÖZET', style: TextStyle(color: kAltin, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 4)),
            const SizedBox(height: 14),
            Text("${dakika.floor()}'", style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900)),
            Text('$skorBiz - $skorRakip', style: const TextStyle(color: kAltin, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (spiker.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(spiker.last, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ),
          ],
        ),
      ),
    );
  }

  Widget sahaAlani() {
    return LayoutBuilder(
      builder: (BuildContext ctx, BoxConstraints cons) {
        final Size boyut = Size(cons.maxWidth, cons.maxHeight);
        return GestureDetector(
          onPanStart: surukBasla,
          onPanUpdate: (DragUpdateDetails d) => surukGuncelle(d, cons.maxHeight),
          onPanEnd: surukBitir,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // Statik katman: cim + cizgiler + tribun + pano (ayri RepaintBoundary)
              RepaintBoundary(
                child: CustomPaint(
                  painter: ZeminPainter(
                    zip: tribunZip,
                    panoT: panoZaman,
                    agEsneSol: agEsneSol,
                    agEsneSag: agEsneSag,
                    pan: kameraPan,
                    zoom: kameraZoom,
                  ),
                ),
              ),
              // Dinamik katman: oyuncular + top + efektler
              CustomPaint(
                painter: SahaPainter(
                  s: this,
                  pan: kameraPan,
                  zoom: kameraZoom,
                  boyut: boyut,
                ),
              ),
              // Mikro kartlar
              for (int i = 0; i < mikroKartlar.length; i++) mikroKartWidget(mikroKartlar[i], i, cons.maxWidth),
              // ATAK GELIYOR uyarisi
              if (interaktif && uyariT > 0)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.9), borderRadius: BorderRadius.circular(14)),
                    child: const Text('⚠ ATAK GELİYOR!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ),
                ),
              // Guc cubugu (interaktif)
              if (interaktif && nisanAktif) gucCubugu(),
              // GOOOL sinematigi
              if (golSineT > 0) gooolKatmani(),
            ],
          ),
        );
      },
    );
  }

  Widget mikroKartWidget(MikroKart m, int i, double genislik) {
    final double op = (m.t < 0.15 ? m.t / 0.15 : (1 - m.t) / 0.25).clamp(0.0, 1.0);
    return Positioned(
      top: 30 + i * 34.0 + m.t * 30,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Opacity(
          opacity: op,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), borderRadius: BorderRadius.circular(12)),
              child: Text(m.yazi, style: TextStyle(color: m.renk, fontSize: m.buyuk ? 20 : 15, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ),
    );
  }

  Widget gucCubugu() {
    // yesil / sari (ideal) / kirmizi
    return Positioned(
      left: 16,
      top: 0,
      bottom: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('GÜÇ', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              width: 18,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFFE63946), Color(0xFFFFD54F), Color(0xFF2E7D32)],
                  stops: <double>[0.0, 0.45, 1.0],
                ),
                border: Border.all(color: Colors.white54),
              ),
              child: Align(
                alignment: Alignment(0, -1 + guc * 2),
                child: Container(width: 26, height: 4, color: Colors.white),
              ),
            ),
            const SizedBox(height: 4),
            Text(falso == 0 ? '' : (falso > 0 ? '↩ falso' : '↪ falso'), style: const TextStyle(color: kAltin, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget gooolKatmani() {
    final double gecen = 2.2 - golSineT;
    final double girisK = (gecen / 0.4).clamp(0.0, 1.0);
    final double overshoot = Curves.elasticOut.transform(girisK);
    final double op = (golSineT / 0.5).clamp(0.0, 1.0);
    return IgnorePointer(
      child: Opacity(
        opacity: op,
        child: Center(
          child: Transform.scale(
            scale: overshoot,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    Text(
                      'GOOOL!',
                      style: TextStyle(
                        fontSize: 64,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w900,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 4
                          ..color = kEvRenk,
                      ),
                    ),
                    const Text(
                      'GOOOL!',
                      style: TextStyle(fontSize: 64, fontStyle: FontStyle.italic, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    asistAdi.isNotEmpty ? '⚽ $golcuAdi   🎯 ASIST: $asistAdi' : '⚽ $golcuAdi',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (asistAdi.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('ASIST!', style: TextStyle(color: kAltin, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 3)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Devre / sonuc kartlari ----------
  Widget devreKarti() {
    final double k = (devreT / 1.2).clamp(0.0, 1.0);
    int say(double hedef) => (hedef * Curves.easeOut.transform(k)).round();
    return Container(
      color: const Color(0xFF0A1622),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF12263A), borderRadius: BorderRadius.circular(20), border: Border.all(color: kAltin.withOpacity(0.4))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('⏸ DEVRE ARASI', style: TextStyle(color: kAltin, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3)),
              const SizedBox(height: 12),
              Text('$skorBiz - $skorRakip', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  istatKutu('Şut', say(sut.toDouble())),
                  istatKutu('İsabetli Pas', say(pas.toDouble())),
                  istatKutu('Gol', say(gol.toDouble())),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: buyukButon(yazi: '▶ 2. Yarıya Başla', renk: kYesil, onPressed: () => setState(devreyiGec)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget istatKutu(String ad, int deger) {
    return Column(
      children: <Widget>[
        Text('$deger', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
        Text(ad, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget macSonuKarti() {
    final double k = (panelT / 0.8).clamp(0.0, 1.0);
    final double flip = sin(k * pi); // flip hissi
    final String baslik = skorBiz > skorRakip ? '🏆 GALİBİYET!' : (skorBiz == skorRakip ? '🤝 BERABERLİK' : '😞 MAĞLUBİYET');
    final Color renk = skorBiz > skorRakip ? kAltin : (skorBiz == skorRakip ? Colors.white70 : const Color(0xFFFF8A80));
    return Container(
      color: const Color(0xFF0A1622),
      child: Center(
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX((1 - k) * pi / 2),
          child: Opacity(
            opacity: (0.2 + flip).clamp(0.0, 1.0),
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF12263A), borderRadius: BorderRadius.circular(20), border: Border.all(color: renk.withOpacity(0.5))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('MAÇ SONUCU', style: TextStyle(color: renk, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 5)),
                  const SizedBox(height: 10),
                  Text(baslik, style: TextStyle(color: renk, fontSize: 26, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('${benimTakim.ad} $skorBiz - $skorRakip ${widget.rakip.ad}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  Text('⚽ Gol: $gol   🎯 Asist: $asist   👟 İsabetli Pas: $pas', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text('⭐ Maç Reytingin: ${rating().toStringAsFixed(1)}', style: const TextStyle(color: kTuruncu, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: buyukButon(yazi: '🎤 Röportaja Geç', renk: kYesil, onPressed: () => setState(roportajHazirla)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget roportajKarti() {
    return Container(
      color: const Color(0xFF0A1622),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF12263A), borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('🎤 MAÇ SONU RÖPORTAJI', style: TextStyle(color: kAltin, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 14),
              Text(roportajSoru, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 17, fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),
              if (roportajEtki.isEmpty)
                for (final List<String> c in roportajCevaplar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: buyukButon(
                        yazi: c[0],
                        renk: const Color(0xFF1D3557),
                        onPressed: () => setState(() => roportajEtki = c[1]),
                      ),
                    ),
                  )
              else ...<Widget>[
                Text(roportajEtki, textAlign: TextAlign.center, style: const TextStyle(color: kAltin, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: buyukButon(yazi: 'Devam →', renk: kYesil, onPressed: () => setState(() => fase = 'sonuc')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget sonucKarti() {
    return Container(
      color: const Color(0xFF0A1622),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF12263A), borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('📋 MAÇ ÖZETİ', style: TextStyle(color: kAltin, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3)),
              const SizedBox(height: 12),
              Text('${benimTakim.ad} $skorBiz - $skorRakip ${widget.rakip.ad}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('⚽ $gol gol  ·  🎯 $asist asist  ·  👟 $pas isabetli pas  ·  🥅 $sut şut', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 6),
              Text('⭐ Reyting: ${rating().toStringAsFixed(1)}', style: const TextStyle(color: kTuruncu, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: buyukButon(
                  yazi: '🏠 Kariyere Dön',
                  renk: kYesil,
                  onPressed: () {
                    sonucTimer?.cancel();
                    sonucTimer = null;
                    widget.bitti(<String, dynamic>{
                      'gol': gol,
                      'asist': asist,
                      'pas': pas,
                      'rating': rating(),
                      'skorBiz': skorBiz,
                      'skorRakip': skorRakip,
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Yardimci uzantilar / projeksiyon ----------
extension _OffsetX on Offset {
  Offset clamp01() => Offset(dx.clamp(0.0, 1.0), dy.clamp(0.0, 1.0));
}

// Yayin kamerasi projeksiyonu: yatay yamuk saha (ust kenar %78, alt %100)
// Saha ekran genisliginden %15 daha genis cizilir; kamera topun x'ine kayar.
class MacKamera {
  static const double genislikPayi = 1.15; // pan payi
  static const double tribunOran = 0.16; // saha alaninin ustunde tribun bandi

  static Rect sahaRect(Size s) => Rect.fromLTWH(0, s.height * tribunOran, s.width, s.height * (1 - tribunOran));

  static Offset proje(Offset p, Size s, double pan, double zoom) {
    final Rect r = sahaRect(s);
    final double sahaW = s.width * genislikPayi;
    final double gevsek = sahaW - s.width;
    final double kamSol = (pan * sahaW - s.width / 2).clamp(0.0, gevsek);
    double bx = p.dx * sahaW - kamSol;
    final double by = r.top + p.dy * r.height;
    final double wf = 0.78 + 0.22 * p.dy; // yamuk: uzak kenar %78
    bx = s.width / 2 + (bx - s.width / 2) * wf;
    final Offset odak = Offset(s.width * 0.5, r.top + r.height * 0.55);
    return odak + (Offset(bx, by) - odak) * zoom;
  }

  static Offset tersProje(Offset ekran, Size s, double pan, double zoom) {
    final Rect r = sahaRect(s);
    final Offset odak = Offset(s.width * 0.5, r.top + r.height * 0.55);
    final Offset b = odak + (ekran - odak) / zoom;
    final double dy = ((b.dy - r.top) / r.height).clamp(0.0, 1.0);
    final double wf = 0.78 + 0.22 * dy;
    double bx = s.width / 2 + (b.dx - s.width / 2) / wf;
    final double sahaW = s.width * genislikPayi;
    final double gevsek = sahaW - s.width;
    final double kamSol = (pan * sahaW - s.width / 2).clamp(0.0, gevsek);
    return Offset(((bx + kamSol) / sahaW).clamp(0.0, 1.0), dy);
  }
}

// ---------- STATIK KATMAN: cim + cizgiler + tribun + LED pano + kaleler ----------
class ZeminPainter extends CustomPainter {
  final double zip; // tribun ziplamasi (golde)
  final double panoT; // LED pano donusu (dk)
  final double agEsneSol;
  final double agEsneSag;
  final double pan;
  final double zoom;
  ZeminPainter({required this.zip, required this.panoT, required this.agEsneSol, required this.agEsneSag, required this.pan, required this.zoom});

  static const List<String> kMarkalar = <String>['CEA GAMES', 'YILDIZ SPOR', 'KRAMPO MAX'];

  @override
  void paint(Canvas canvas, Size size) {
    final Rect sr = MacKamera.sahaRect(size);
    // Gece gokyuzu / cevre
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF07131F));
    _tribun(canvas, size);
    // Yamuk patika
    final Path yamuk = Path()
      ..moveTo(size.width * 0.11, sr.top)
      ..lineTo(size.width * 0.89, sr.top)
      ..lineTo(size.width, sr.bottom)
      ..lineTo(0, sr.bottom)
      ..close();
    canvas.save();
    canvas.clipPath(yamuk);
    // Cim: 10 bicilmis serit (cift ton yesil)
    final double seritW = size.width / 10;
    for (int i = 0; i < 10; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * seritW, sr.top, seritW + 1, sr.height),
        Paint()..color = i.isEven ? const Color(0xFF2F9E44) : const Color(0xFF37B24D),
      );
    }
    // Diyagonal isik deseni
    final Paint isik = Paint()..color = Colors.white.withOpacity(0.03);
    for (double x = -size.height; x < size.width + size.height; x += 46) {
      canvas.drawPath(
        Path()
          ..moveTo(x, sr.bottom)
          ..lineTo(x + sr.height, sr.top)
          ..lineTo(x + sr.height + 14, sr.top)
          ..lineTo(x + 14, sr.bottom)
          ..close(),
        isik,
      );
    }
    // Projektor isik havuzlari
    for (final double cx in <double>[size.width * 0.3, size.width * 0.7]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, sr.top + sr.height * 0.4), width: size.width * 0.55, height: sr.height * 0.8),
        Paint()..color = Colors.white.withOpacity(0.05),
      );
    }
    // Vignette (kenar karartmasi)
    final Rect tum = Offset.zero & size;
    canvas.drawRect(
      tum,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[Colors.transparent, Colors.black.withOpacity(0.35)],
          stops: const <double>[0.75, 1.0],
          radius: 1.1,
        ).createShader(tum),
    );
    _cizgiler(canvas, size);
    canvas.restore();
    _kale(canvas, size, true, agEsneSol);
    _kale(canvas, size, false, agEsneSag);
  }

  void _cizgiler(Canvas canvas, Size size) {
    Offset pr(double x, double y) => MacKamera.proje(Offset(x, y), size, pan, zoom);
    final Paint cizgi = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke;
    void cizgiKal(double y) => cizgi.strokeWidth = 1.0 + y * 1.6; // derinlikle incelen
    // Dis sinir
    final Path sinir = Path()
      ..moveTo(pr(0, 0).dx, pr(0, 0).dy)
      ..lineTo(pr(1, 0).dx, pr(1, 0).dy)
      ..lineTo(pr(1, 1).dx, pr(1, 1).dy)
      ..lineTo(pr(0, 1).dx, pr(0, 1).dy)
      ..close();
    cizgi.strokeWidth = 2.2;
    canvas.drawPath(sinir, cizgi);
    // Orta cizgi
    cizgiKal(0.5);
    canvas.drawLine(pr(0.5, 0), pr(0.5, 1), cizgi);
    // Orta yuvarlak
    final Path yuvarlak = Path();
    for (int i = 0; i <= 40; i++) {
      final double a = i / 40 * 2 * pi;
      final Offset p = pr(0.5 + cos(a) * 0.09, 0.5 + sin(a) * 0.14);
      if (i == 0) {
        yuvarlak.moveTo(p.dx, p.dy);
      } else {
        yuvarlak.lineTo(p.dx, p.dy);
      }
    }
    cizgi.strokeWidth = 1.8;
    canvas.drawPath(yuvarlak, cizgi);
    canvas.drawCircle(pr(0.5, 0.5), 2.4, Paint()..color = Colors.white.withOpacity(0.85));
    // Ceza sahalari + kale sahalari + korner yaylari
    for (final bool sol in <bool>[true, false]) {
      final double xs = sol ? 0.0 : 1.0;
      final double is = sol ? 1.0 : -1.0;
      final List<Offset> ceza = <Offset>[
        Offset(xs, 0.22), Offset(xs + is * 0.16, 0.22), Offset(xs + is * 0.16, 0.78), Offset(xs, 0.78),
      ];
      final Path p1 = Path()..moveTo(ceza[0].dx, 0);
      final List<Offset> pj = ceza.map((Offset o) => pr(o.dx, o.dy)).toList();
      p1
        ..moveTo(pj[0].dx, pj[0].dy)
        ..lineTo(pj[1].dx, pj[1].dy)
        ..lineTo(pj[2].dx, pj[2].dy)
        ..lineTo(pj[3].dx, pj[3].dy);
      cizgi.strokeWidth = 1.8;
      canvas.drawPath(p1, cizgi);
      final List<Offset> alti = <Offset>[
        Offset(xs, 0.38), Offset(xs + is * 0.06, 0.38), Offset(xs + is * 0.06, 0.62), Offset(xs, 0.62),
      ];
      final List<Offset> aj = alti.map((Offset o) => pr(o.dx, o.dy)).toList();
      final Path p2 = Path()
        ..moveTo(aj[0].dx, aj[0].dy)
        ..lineTo(aj[1].dx, aj[1].dy)
        ..lineTo(aj[2].dx, aj[2].dy)
        ..lineTo(aj[3].dx, aj[3].dy);
      cizgi.strokeWidth = 1.6;
      canvas.drawPath(p2, cizgi);
      // Penalti noktasi
      canvas.drawCircle(pr(xs + is * 0.11, 0.5), 2.0, Paint()..color = Colors.white.withOpacity(0.85));
      // Korner yaylari
      for (final double ky in <double>[0.0, 1.0]) {
        final Path yay = Path();
        for (int i = 0; i <= 8; i++) {
          final double a = i / 8 * pi / 2;
          final Offset o = Offset(xs + is * sin(a) * 0.015, ky + (ky == 0 ? 1 : -1) * cos(a) * 0.022);
          final Offset p = pr(o.dx, o.dy);
          if (i == 0) {
            yay.moveTo(p.dx, p.dy);
          } else {
            yay.lineTo(p.dx, p.dy);
          }
        }
        cizgi.strokeWidth = 1.4;
        canvas.drawPath(yay, cizgi);
      }
    }
  }

  // 3D kutu kale (direk + crossbar + arkaya daralan yamuk ag)
  void _kale(Canvas canvas, Size size, bool sol, double esneme) {
    final Offset ust = MacKamera.proje(Offset(sol ? 0 : 1, 0.44), size, pan, zoom);
    final Offset alt = MacKamera.proje(Offset(sol ? 0 : 1, 0.56), size, pan, zoom);
    final double derin = (alt.dy - ust.dy).abs();
    final double kaleYukseklik = 26 + derin * 0.18;
    final double geriye = (sol ? -1 : 1) * (14 + derin * 0.22); // ag derinligi (disa dogru)
    final Paint direk = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    // Direkler + crossbar
    canvas.drawLine(ust, ust - Offset(0, kaleYukseklik), direk);
    canvas.drawLine(alt, alt - Offset(0, kaleYukseklik), direk);
    canvas.drawLine(ust - Offset(0, kaleYukseklik), alt - Offset(0, kaleYukseklik), direk);
    // Ag: arkaya daralan yamuk orgu, golde iceri esner
    final double esn = esneme * (sol ? 1 : -1) * -14; // gol yonune (saha icine) esneme
    final Offset arkaUst = ust - Offset(0, kaleYukseklik) + Offset(geriye + esn * 0.3, -4);
    final Offset arkaAlt = alt - Offset(0, kaleYukseklik * 0.4) + Offset(geriye + esn, 6);
    final Paint agCizgi = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 0.8;
    for (int i = 0; i <= 6; i++) {
      final double t = i / 6;
      canvas.drawLine(Offset.lerp(ust - Offset(0, kaleYukseklik), alt - Offset(0, kaleYukseklik * 0.4), t)!,
          Offset.lerp(arkaUst, arkaAlt, t)!, agCizgi);
    }
    for (int i = 0; i <= 4; i++) {
      final double t = i / 4;
      canvas.drawLine(Offset.lerp(ust - Offset(0, kaleYukseklik), arkaUst, t)!,
          Offset.lerp(alt - Offset(0, kaleYukseklik * 0.4), arkaAlt, t)!, agCizgi);
    }
  }

  // Tribun: koyu koltuk bloklari + 350 renkli nokta + LED pano
  void _tribun(Canvas canvas, Size size) {
    final double ledH = size.height * 0.05;
    final double koltukH = MacKamera.sahaRect(size).top - ledH;
    // Koltuk bloklari
    canvas.drawRect(Rect.fromLTWH(0, ledH, size.width, koltukH), Paint()..color = const Color(0xFF101820));
    final Random tr = Random(42);
    final Paint nokta = Paint();
    for (int i = 0; i < 350; i++) {
      final double x = tr.nextDouble() * size.width;
      final double satir = tr.nextDouble();
      final double zipla = zip > 0 ? -tr.nextDouble() * 6 * zip : 0;
      nokta.color = HSVColor.fromAHSV(1, tr.nextDouble() * 360, 0.5, 0.75).toColor();
      canvas.drawCircle(Offset(x, ledH + 4 + satir * (koltukH - 8) + zipla), 1.4, nokta);
    }
    // LED pano: 3 marka 6 sn'de doner
    final int marka = (panoT / 6).floor() % kMarkalar.length;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, ledH), Paint()..color = const Color(0xFF0A0F16));
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: (kMarkalar[marka] + '   ★   ' * 8).padRight(60),
        style: TextStyle(color: kAltin.withOpacity(0.9), fontSize: ledH * 0.55, fontWeight: FontWeight.w900, letterSpacing: 3),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: size.width);
    tp.paint(canvas, Offset(10, ledH * 0.22));
  }

  @override
  bool shouldRepaint(ZeminPainter eski) =>
      eski.zip != zip || (eski.panoT / 6).floor() != (panoT / 6).floor() ||
      eski.agEsneSol != agEsneSol || eski.agEsneSag != agEsneSag || eski.pan != pan || eski.zoom != zoom;
}

// ---------- DINAMIK KATMAN: eklemli futbolcular + top + efektler ----------
class SahaPainter extends CustomPainter {
  final _MacEkraniState s;
  final double pan;
  final double zoom;
  final Size boyut;
  SahaPainter({required this.s, required this.pan, required this.zoom, required this.boyut});

  static final Map<String, TextPainter> _noCache = <String, TextPainter>{};

  static const Color kTen = Color(0xFFF1C27D);
  static const Color kSac = Color(0xFF3B2A20);

  Offset pr(Offset p, Size size) => MacKamera.proje(p, size, pan, zoom);

  @override
  void paint(Canvas canvas, Size size) {
    // Nisan oklari (interaktif)
    if (s.nisanAktif) _nisanlar(canvas, size);
    // Oyuncular: derinlik siralamasi (y'ye gore)
    final List<Futbolcu> sirali = List<Futbolcu>.from(s.futbolcular)..sort((Futbolcu a, Futbolcu b) => a.pos.dy.compareTo(b.pos.dy));
    for (final Futbolcu f in sirali) {
      _futbolcuCiz(canvas, size, f);
    }
    _topCiz(canvas, size);
    // Konfeti
    final Paint kp = Paint();
    for (final Konfeti k in s.konfeti) {
      kp.color = k.c.withOpacity(k.omur.clamp(0.0, 1.0));
      canvas.drawRect(Rect.fromCenter(center: pr(k.p, size), width: k.boyut, height: k.boyut * 0.6), kp);
    }
    // Toz
    for (final Toz t in s.tozlar) {
      canvas.drawCircle(pr(t.p, size), 4 * t.omur + 2, Paint()..color = Colors.brown.withOpacity(0.3 * t.omur));
    }
  }

  // ===== EKLEMLI FUTBOLCU (pelvis koklu, 2 parcali bacak/kol) =====
  void _futbolcuCiz(Canvas canvas, Size size, Futbolcu f) {
    final Offset taban = pr(f.pos, size);
    final double h = 55 + 30 * f.pos.dy; // 55-85 px, derinlik olcekli
    final bool sagaBak = f.takim == 0; // biz saga hucum
    final double yon = sagaBak ? 1.0 : -1.0;
    final Color forma = f.kaleci
        ? _MacEkraniState.kKaleciRenk
        : (f.takim == 0 ? _MacEkraniState.kEvRenk : _MacEkraniState.kRakipRenk);
    // Golge: pelvis altina derinlik olcekli yumusak elips
    canvas.drawOval(
      Rect.fromCenter(center: taban + Offset(0, 2), width: h * 0.42, height: h * 0.12),
      Paint()..color = Colors.black.withOpacity(0.30),
    );
    // FORMDAYIM glow
    final bool yildiz = f.takim == 0 && s.futbolcular.indexOf(f) == 10;
    if (yildiz && s.oyuncuGlow > 0) {
      canvas.drawCircle(taban - Offset(0, h * 0.45), h * 0.55, Paint()..color = kAltin.withOpacity(0.18 * s.oyuncuGlow.clamp(0.0, 1.0)));
    }
    // Diz ustu kayma sevinci: govde arkaya yatik, bacaklar one uzanmis
    if (f.sevincT < 0.9) {
      _sevincCiz(canvas, taban, h, yon, forma, f.sevincT);
      return;
    }
    // Kaleci dalisi: tum govde yatay doner, parabolik ucus
    double dalisRot = 0;
    Offset dalisOfset = Offset.zero;
    if (f.dalisT < 0.8) {
      final double t = f.dalisT / 0.8;
      final double kavis = sin(t * pi); // parabolik
      dalisRot = f.dalisYon * 1.3 * (t < 0.5 ? t * 2 : 1);
      dalisOfset = Offset(0, f.dalisYon * h * 0.45 * kavis - h * 0.1 * kavis);
    }
    canvas.save();
    canvas.translate(taban.dx + dalisOfset.dx, taban.dy + dalisOfset.dy);
    if (dalisRot != 0) canvas.rotate(dalisRot);
    final Offset pelvis = Offset(0, -h * 0.42);
    // Kosma govde egimi ~10°
    final double egim = 0.17 * yon * (0.4 + 0.6 * f.hizAni.clamp(0.0, 1.0));
    Offset omuz = pelvis + Offset(egim * h * 0.28, -h * 0.30);
    // Sut animasyonunda govde one yigilir
    double sutBacakAcisi = double.nan;
    double sutDiz = 0;
    if (f.sutT < 0.35) {
      final double t = f.sutT;
      omuz += Offset(yon * h * 0.06, h * 0.02);
      if (t < 0.15) {
        final double k = t / 0.15;
        sutBacakAcisi = -1.0 * k;
        sutDiz = 1.2 * k;
      } else if (t < 0.25) {
        final double k = (t - 0.15) / 0.10;
        sutBacakAcisi = -1.0 + 2.2 * k; // yildirim gibi one savrulma
        sutDiz = 1.2 * (1 - k);
      } else {
        final double k = (t - 0.25) / 0.10;
        sutBacakAcisi = 1.2 - 0.6 * k; // takip sallanmasi
        sutDiz = 0.2 * (1 - k);
      }
    }
    // --- BACAKLAR (2 parcali: kalca+diz+ayak) ---
    final double uylukL = h * 0.17;
    final double kavalL = h * 0.16;
    final Paint bacakBoya = Paint()
      ..strokeWidth = h * 0.075
      ..strokeCap = StrokeCap.round;
    for (int b = 0; b < 2; b++) {
      final double faz = f.faz + b * pi;
      final Offset kalca = pelvis + Offset(0, (b == 0 ? -1 : 1) * h * 0.03);
      double a1;
      double dizBukum;
      if (b == 0 && !sutBacakAcisi.isNaN) {
        a1 = sutBacakAcisi * yon;
        dizBukum = sutDiz;
      } else {
        a1 = sin(faz) * 0.7 * yon;
        dizBukum = max(0.0, -sin(faz)) * 1.1; // ayak gerideyken diz bukulur
      }
      final Offset diz = kalca + Offset(sin(a1) * uylukL, cos(a1) * uylukL);
      final double a2 = a1 + dizBukum * yon;
      final Offset ayak = diz + Offset(sin(a2) * kavalL, cos(a2) * kavalL);
      // Uyluk: sort rengi (formanin koyusu)
      bacakBoya.color = Color.lerp(forma, Colors.black, 0.35)!;
      canvas.drawLine(kalca, diz, bacakBoya);
      // Kaval: corap (forma) + ayak koyu elips
      bacakBoya.color = forma;
      canvas.drawLine(diz, ayak, bacakBoya);
      canvas.drawOval(Rect.fromCenter(center: ayak + Offset(yon * 2, 0), width: h * 0.11, height: h * 0.055), Paint()..color = const Color(0xFF212529));
    }
    // --- GOVDE (formali, hafif egimli) ---
    final Paint govde = Paint()
      ..color = forma
      ..strokeWidth = h * 0.17
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pelvis, omuz, govde);
    // Forma no: govdenin arkasina kucuk koyu rakam (cache)
    if (_noCache.length > 60) _noCache.clear();
    final TextPainter tp = _noCache.putIfAbsent(
      '${f.no}',
      () => TextPainter(
        text: TextSpan(text: '${f.no}', style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
    tp.paint(canvas, Offset.lerp(pelvis, omuz, 0.45)! - Offset(tp.width / 2 - yon * 3, tp.height / 2));
    // --- KOLLAR (2 parcali, bacaklarla ters faz) ---
    final double ustKolL = h * 0.13;
    final double onKolL = h * 0.12;
    final Paint kolBoya = Paint()
      ..strokeWidth = h * 0.055
      ..strokeCap = StrokeCap.round;
    final bool dalis = f.dalisT < 0.8;
    final bool kolKaldiriyor = f.kolT < 1.6;
    for (int k2 = 0; k2 < 2; k2++) {
      final Offset omuzN = omuz + Offset(0, (k2 == 0 ? -1 : 1) * h * 0.045);
      double kolA;
      double dirsek = 0.5;
      if (dalis) {
        kolA = f.dalisYon * 1.4; // kollar topa uzanir
        dirsek = 0.1;
      } else if (kolKaldiriyor) {
        kolA = -2.6; // havaya kalkik
        dirsek = 0.3;
      } else {
        kolA = -sin(f.faz + k2 * pi) * 0.6 * yon;
      }
      final Offset dirsekN = omuzN + Offset(sin(kolA) * ustKolL, cos(kolA) * ustKolL);
      final Offset el = dirsekN + Offset(sin(kolA - dirsek * yon) * onKolL, cos(kolA - dirsek * yon) * onKolL);
      kolBoya.color = forma;
      canvas.drawLine(omuzN, dirsekN, kolBoya);
      kolBoya.color = kTen;
      canvas.drawLine(dirsekN, el, kolBoya);
      // Kaleci eldiveni
      if (f.kaleci) {
        canvas.drawCircle(el, h * 0.045, Paint()..color = Colors.white);
      }
    }
    // --- KAFA (ten daire + sac yayi, hafif one egik) ---
    final Offset kafa = omuz + Offset(egim * h * 0.10 + yon * h * 0.015, -h * 0.10);
    canvas.drawCircle(kafa, h * 0.085, Paint()..color = kTen);
    final Path sac = Path()
      ..addArc(Rect.fromCircle(center: kafa, radius: h * 0.085), pi, pi);
    canvas.drawPath(sac, Paint()
      ..color = kSac
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.05
      ..strokeCap = StrokeCap.round);
    canvas.restore();
  }

  // Gol sevinci: diz ustu kayma (0.8 sn), koseye dogru kayar
  void _sevincCiz(Canvas canvas, Offset taban, double h, double yon, Color forma, double t) {
    final double k = (t / 0.8).clamp(0.0, 1.0);
    final Offset kayma = Offset(yon * 26 * k, 0);
    canvas.save();
    canvas.translate(taban.dx + kayma.dx, taban.dy);
    canvas.rotate(0.55 * yon * k); // govde arkaya yatik
    final Offset pelvis = Offset(0, -h * 0.20);
    final Offset omuz = pelvis + Offset(0, -h * 0.30);
    // Bacaklar one uzanmis
    final Paint p = Paint()
      ..strokeWidth = h * 0.075
      ..strokeCap = StrokeCap.round
      ..color = forma;
    for (int b = 0; b < 2; b++) {
      final Offset kalca = pelvis + Offset(0, (b == 0 ? -1 : 1) * h * 0.03);
      final Offset diz = kalca + Offset(yon * h * 0.16, h * 0.05);
      final Offset ayak = diz + Offset(yon * h * 0.14, h * 0.02);
      canvas.drawLine(kalca, diz, p);
      canvas.drawLine(diz, ayak, p);
    }
    final Paint g = Paint()
      ..color = forma
      ..strokeWidth = h * 0.17
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pelvis, omuz, g);
    // Kollar havada
    final Paint kp = Paint()
      ..strokeWidth = h * 0.055
      ..strokeCap = StrokeCap.round
      ..color = forma;
    canvas.drawLine(omuz, omuz + Offset(-yon * h * 0.10, -h * 0.16), kp);
    canvas.drawLine(omuz, omuz + Offset(yon * h * 0.06, -h * 0.18), kp);
    final Offset kafa = omuz + Offset(0, -h * 0.10);
    canvas.drawCircle(kafa, h * 0.085, Paint()..color = kTen);
    canvas.restore();
  }

  // ===== TOP: beyaz daire + donen siyah besgen, z yuksekligi, trail =====
  void _topCiz(Canvas canvas, Size size) {
    // Trail: son 8 konum, incelen yarim seffaf
    if (s.topTrail.length > 1) {
      final Paint tr = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (int i = 1; i < s.topTrail.length; i++) {
        tr
          ..color = Colors.white.withOpacity(0.10 * (i / s.topTrail.length))
          ..strokeWidth = 1 + i * 0.4;
        canvas.drawLine(pr(s.topTrail[i - 1], size), pr(s.topTrail[i], size), tr);
      }
    }
    final Offset zemin = pr(s.top, size);
    // Golge: z*0.5 altinda, z ile kuculur/solar
    final double golgeK = (1 - s.topZ / 90).clamp(0.35, 1.0);
    canvas.drawOval(
      Rect.fromCenter(center: zemin + Offset(0, s.topZ * 0.5), width: 12 * golgeK, height: 4.5 * golgeK),
      Paint()..color = Colors.black.withOpacity(0.3 * golgeK),
    );
    final double ziplama = s.ziplamaT < 0.5 ? sin(s.ziplamaT / 0.5 * pi) * 5 * (1 - s.ziplamaT) : 0;
    final Offset merkez = zemin - Offset(0, s.topZ + ziplama);
    final double rTop = 5.5 + 2.5 * s.top.dy;
    canvas.drawCircle(merkez, rTop, Paint()..color = Colors.white);
    canvas.drawCircle(merkez, rTop, Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
    // Donen siyah besgen
    final Path besgen = Path();
    for (int i = 0; i < 5; i++) {
      final double a = s.topDonme + i / 5 * 2 * pi;
      final Offset p = merkez + Offset(cos(a) * rTop * 0.45, sin(a) * rTop * 0.45);
      if (i == 0) {
        besgen.moveTo(p.dx, p.dy);
      } else {
        besgen.lineTo(p.dx, p.dy);
      }
    }
    besgen.close();
    canvas.drawPath(besgen, Paint()..color = const Color(0xFF212529));
  }

  // ===== Nisan oklari + tatli nokta + kaleci kaymasi =====
  void _nisanlar(Canvas canvas, Size size) {
    final Offset topEkran = pr(s.top, size);
    void ok(Offset hedef, Color renk, String etiket) {
      final Offset h = pr(hedef, size);
      final Paint p = Paint()
        ..color = renk
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final Offset yon2 = (h - topEkran);
      final Offset birim = yon2 / yon2.distance;
      final Offset bitis = h - birim * 14;
      canvas.drawLine(topEkran, bitis, p);
      // Ok ucu
      final Offset dik = Offset(-birim.dy, birim.dx);
      canvas.drawPath(
        Path()
          ..moveTo(h.dx, h.dy)
          ..lineTo(bitis.dx + dik.dx * 6, bitis.dy + dik.dy * 6)
          ..lineTo(bitis.dx - dik.dx * 6, bitis.dy - dik.dy * 6)
          ..close(),
        Paint()..color = renk,
      );
      final TextPainter tp = TextPainter(
        text: TextSpan(text: etiket, style: TextStyle(color: renk, fontSize: 13, fontWeight: FontWeight.w900, backgroundColor: Colors.black54)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, h + Offset(-tp.width / 2, -26));
    }

    // Sut oklari: kale sol/sag kose (tatli nokta: kalecinin kaymadigi kose yesil)
    final double tatliKoseY = s.kaleciTatliYon > 0 ? 0.42 : 0.58;
    final double digerKoseY = s.kaleciTatliYon > 0 ? 0.58 : 0.42;
    ok(Offset(0.99, tatliKoseY), const Color(0xFF57CC99), 'ŞUT 🎯');
    ok(Offset(0.99, digerKoseY), Colors.white70, 'ŞUT');
    // Pas oku: arkadas
    if (s.nisanPasHedef != null) ok(s.nisanPasHedef!, kAltin, 'PAS 👟');
    // Tatli nokta gostergesi: kaleci kayma yonu
    final Offset kEkran = pr(const Offset(0.96, 0.5), size);
    final TextPainter kt = TextPainter(
      text: TextSpan(text: s.kaleciTatliYon > 0 ? '⬇ kaleci kayıyor' : '⬆ kaleci kayıyor', style: const TextStyle(color: Color(0xFF4CC9F0), fontSize: 12, fontWeight: FontWeight.bold, backgroundColor: Colors.black54)),
      textDirection: TextDirection.ltr,
    )..layout();
    kt.paint(canvas, kEkran + Offset(-kt.width / 2, 14));
    // Falso gostergesi
    if (s.falso != 0) {
      final TextPainter ft = TextPainter(
        text: TextSpan(text: 'Falso: ${(s.falso * 100).round()}%', style: const TextStyle(color: kAltin, fontSize: 12, fontWeight: FontWeight.bold, backgroundColor: Colors.black54)),
        textDirection: TextDirection.ltr,
      )..layout();
      ft.paint(canvas, Offset(size.width / 2 - ft.width / 2, size.height * 0.2));
    }
  }

  @override
  bool shouldRepaint(SahaPainter eski) => true;
}
