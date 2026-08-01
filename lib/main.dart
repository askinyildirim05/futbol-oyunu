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
  static ui.Image? saha; // saha_zemin.jpg
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

// Kaleci dalisi toz parcacigi
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

class _MacEkraniState extends State<MacEkrani> {
  final Random r = Random();
  Timer? timer;
  Timer? overlayTimer;
  Timer? secimTimer;
  Timer? sonucTimer; // hata #10: mac sonu timer'i alanda tutulur, dispose'da iptal
  double dakika = 0;
  int hiz = 1;
  int skorBiz = 0;
  int skorRakip = 0;
  int gol = 0;
  int asist = 0;
  int pas = 0;
  int sut = 0;
  final List<String> spiker = <String>[];
  double spikerT = 99; // yazi makinesi efekti: son satirin yasi (sn)
  final Map<int, int> sablonSayi = <int, int>{}; // ayni sablon mac basina max 2 kez
  String fase = 'oyun'; // oyun, devre, sonuc, panel, roportaj
  String overlay = '';
  Color overlayRenk = kAltin;
  bool devreYapildi = false;
  double devreT = 0; // devre karti sayac animasyonu
  double panelT = 0; // mac sonu karti flip animasyonu
  String roportajSoru = '';
  List<List<String>> roportajCevaplar = <List<String>>[];
  String roportajEtki = '';
  late final List<String> benimIsimler;
  late final List<String> rakipIsimler;
  late final TakimBilgi benimTakim;

  // --- Canli saha simulasyonu ---
  late final List<Offset> benimPos; // saha orani (0..1), y=0 ust = rakip kalesi
  late final List<Offset> rakipPos;
  late final List<Offset> benimGez;
  late final List<Offset> rakipGez;
  Offset top = const Offset(0.5, 0.42);
  int topTakim = 0; // 0 = biz, 1 = rakip
  int topOyuncu = 0;
  int topGiden = 0;
  double pasSayac = 1.5;
  double sonrakiPozisyonDk = 9;

  // --- Top ucus animasyonu (sonuc ancak top hedefe ulasinca aciklanir) ---
  bool topUcuyor = false;
  double ucusT = 0; // 0..1
  double ucusSure = 0.9; // saniye (1x hizinda)
  double ucusKavis = 0.5; // yukseklik miktari
  bool ucusYavas = false; // slow-motion karar anlari
  Offset ucusBas = const Offset(0.5, 0.42);
  Offset ucusBit = const Offset(0.5, 0.42);
  VoidCallback? ucusSonu;
  double topYukseklik = 0; // 0..1 (yerden yukseklik hissi)
  double topSpin = 0; // top dikis yaylarinin donusu
  double sonGuc = 0.55; // son vurus gucu (trail rengi icin)

  // --- Gol efektleri / sinematigi ---
  double sarsinti = 0; // 1 -> 0 azalan ekran sarsintisi
  final List<Konfeti> konfeti = <Konfeti>[];
  final List<Toz> toz = <Toz>[];
  final List<Offset> topIz = <Offset>[]; // top ucus izi (trail, ring buffer 8)
  double animT = 0; // gorsel zaman (slow-mo'da yavaslar)
  double agUst = 0; // ust kale aginda esneme suresi
  double agAlt = 0; // alt kale aginda esneme suresi
  String mesafeYazi = ''; // vurus mesafesi kutusu
  double overlayBoyut = 44;
  String overlayAlt = ''; // gol atanin adi (GOOOL alt yazisi)
  double overlayT = 1; // overlay giris animasyonu 0..1
  double golSineT = 0; // gol sinematigi kalan sure (2.2 -> 0)
  double tribunZipla = 0; // golde tribun ziplama dalgasi
  double skorFlash = 0; // golde skorboard flas
  // Kaleci kurtaris dalisi
  double dalisT = 0; // kalan sure (0.8 -> 0)
  int dalisTakim = -1; // 0 = bizim kaleci, 1 = rakip kaleci
  double dalisYon = 1; // -1 sol, +1 sag
  // Sut savurma + sevinc animasyonlari
  double sutT = 0; // 0.3 -> 0 bacak savurma
  String sutAnahtar = '';
  double sevincT = 0; // 1.2 -> 0 kollar V + ziplama
  String sevincAnahtar = '';

  // --- Interaktif pozisyon ---
  bool interaktif = false;
  Offset? nisan; // saha orani
  bool nisanCekiliyor = false;
  bool gucCekiliyor = false;
  double guc = 0;
  String hedefTip = 'sut'; // sut, pas
  int hedefIndex = -1;
  String hedefKose = 'sol';
  Size sahaSize = const Size(100, 100);
  double interaktifT = 0; // kaleci kayma animasyonu zamani

  // --- Game-feel: mikro kartlar, tehlike, combo, gorevler, hiz ---
  final List<MikroKart> kartlar = <MikroKart>[];
  bool sonrakiInteraktif = false; // siradaki pozisyon interaktif mi (onceden belli)
  bool tehlikeGosterildi = false;
  bool ekstraPozisyonVerildi = false; // 88'+ garanti interaktif
  int combo = 0; // ust uste basarili aksiyon (FORMDAYIM)
  final List<int> gorevIlerleme = <int>[0, 0, 0]; // ilk sut, 2 isabetli pas, combo x3
  final List<bool> gorevBitti = <bool>[false, false, false];
  double hizEtiketT = 0; // hiz degisimi etiketi (1 sn)
  String hizEtiket = '';

  // Dizilis konumlari (4-4-2): x, y oranlari
  static const List<List<double>> kDizilis = <List<double>>[
    <double>[0.50, 0.42], // 0: kullanici ST
    <double>[0.30, 0.50],
    <double>[0.18, 0.62], <double>[0.40, 0.66], <double>[0.60, 0.66], <double>[0.82, 0.62],
    <double>[0.15, 0.80], <double>[0.38, 0.84], <double>[0.62, 0.84], <double>[0.85, 0.80],
    <double>[0.50, 0.96], // kaleci
  ];

  static const List<Color> kKonfetiRenkler = <Color>[
    Color(0xFFFF5252), Color(0xFFFFD740), Color(0xFF69F0AE), Color(0xFF40C4FF),
    Color(0xFFE040FB), Color(0xFFFF9800), Color(0xFFFFFFFF), Color(0xFF76FF03),
  ];

  // Spiker sablonlari (15 adet, {OYUNCU} degiskenli)
  static const List<String> kSablonlar = <String>[
    'Büyük fırsat! {OYUNCU} topu kaptı!',
    'Kaleci müthiş çıkardı! 🧤',
    'Top direkten döndü! 😱',
    'GOOOL! {OYUNCU} sahneye çıkıyor! ⚽',
    'Tribünler ayakta! 📣',
    'Son dakikalar! Her dokunuş altın değerinde.',
    'Teknik direktör kenarda çıldırıyor!',
    'Savunma duvar gibi, geçit yok.',
    'Uzatma dakikaları... kalpler ağızda!',
    'Orta sahada büyük mücadele var!',
    'Taraftarlar coşkuyla takımını destekliyor! 🎺',
    '{OYUNCU} boş koşu yapıyor, topu istiyor!',
    'Tempo giderek artıyor! ⚡',
    '{OYUNCU} pres yapıyor, rakip zorlanıyor.',
    'Maç formaliteye döndü, tribünler şov yapıyor. 🎆',
  ];

  // Painter'lar state'i referans alir; boylece instance alanlari (kosma fazi,
  // TextPainter cache) her frame sifirlanmaz (hata #11).
  late final ZeminPainter zeminPainter = ZeminPainter(this);
  late final SahaPainter sahaPainter = SahaPainter(this);

  @override
  void initState() {
    super.initState();
    benimTakim = takimBul(kStr(widget.kariyer, 'takim'));
    benimIsimler = <String>[kStr(widget.kariyer, 'ad'), for (final dynamic e in kListe(widget.kariyer, 'arkadaslar')) e as String];
    rakipIsimler = rakipOyunculari(widget.rakip);
    benimPos = <Offset>[for (int i = 0; i < 11; i++) Offset(kDizilis[i][0], kDizilis[i][1])];
    rakipPos = <Offset>[for (int i = 0; i < 11; i++) Offset(kDizilis[i][0], 1 - kDizilis[i][1])];
    benimGez = List<Offset>.from(benimPos);
    rakipGez = List<Offset>.from(rakipPos);
    spikerEkle('Maç başladı! ${benimTakim.ad} v ${widget.rakip.ad}. Bol gollü bir maç olsun! 📣');
    // Gercek resim varliklari: async yukle, yuklenince yeniden ciz (fallback: kod-cizim)
    Resimler.yukle().then((_) {
      if (mounted) setState(() {});
    });
    timer = Timer.periodic(const Duration(milliseconds: 40), (Timer t) => tik());
  }

  @override
  void dispose() {
    timer?.cancel();
    overlayTimer?.cancel();
    secimTimer?.cancel();
    sonucTimer?.cancel();
    super.dispose();
  }

  void spikerEkle(String s) {
    spiker.add(s);
    spikerT = 0; // yazi makinesi yeniden baslar
    while (spiker.length > 5) {
      spiker.removeAt(0);
    }
  }

  // Sablonlu yorum: ayni sablon mac basina max 2 kez
  void sablonSoyle(int i, {String oyuncu = ''}) {
    final int kullanim = sablonSayi[i] ?? 0;
    if (kullanim >= 2) return;
    sablonSayi[i] = kullanim + 1;
    spikerEkle(kSablonlar[i].replaceAll('{OYUNCU}', oyuncu));
  }

  void mikroKartEkle(String yazi, Color renk, {bool buyuk = false}) {
    kartlar.add(MikroKart(yazi, renk, buyuk: buyuk));
    if (kartlar.length > 6) kartlar.removeAt(0);
  }

  void comboVur(bool basari) {
    if (basari) {
      combo++;
    } else {
      combo = 0;
    }
    gorevKontrol();
  }

  void gorevKontrol() {
    gorevIlerleme[0] = sut.clamp(0, 1);
    gorevIlerleme[1] = pas.clamp(0, 2);
    gorevIlerleme[2] = combo.clamp(0, 3);
    final List<int> hedefler = <int>[1, 2, 3];
    for (int i = 0; i < 3; i++) {
      if (!gorevBitti[i] && gorevIlerleme[i] >= hedefler[i]) {
        gorevBitti[i] = true;
        mikroKartEkle('+15', kYesil);
      }
    }
  }

  Offset yakla(Offset a, Offset b, double adim) {
    final Offset f = b - a;
    final double d = f.distance;
    if (d <= adim || d == 0) return b;
    return a + f * (adim / d);
  }

  static double aral(double a, double b, double t) => a + (b - a) * t;

  void tik() {
    if (!mounted) return;
    // Interaktif modda kaleci sol-sag kayar (hiz zorluga gore), zaman ilerlemez
    if (interaktif && fase == 'oyun') {
      setState(() {
        interaktifT += 0.04;
        spikerT += 0.04;
        final double kh = widget.zorluk == 'Kolay' ? 1.5 : (widget.zorluk == 'Zor' ? 3.2 : 2.3);
        rakipPos[10] = Offset(0.5 + 0.085 * sin(interaktifT * kh), 0.045);
        kartGuncelle(0.04);
      });
      return;
    }
    if (fase != 'oyun') {
      // Sonuc/devre ekranlarinda da giris animasyonlari ilerlesin
      if (overlay.isNotEmpty && overlayT < 1) setState(() => overlayT = (overlayT + 0.13).clamp(0.0, 1.0));
      if (fase == 'devre' && devreT < 2) setState(() => devreT += 0.04);
      if (fase == 'panel' && panelT < 1) setState(() => panelT = (panelT + 0.05).clamp(0.0, 1.0));
      return;
    }
    setState(() {
      final double dt = 0.04 * hiz; // saniye (hiz carpani ile)
      // Gol sinematigi: ilk 400 ms gorsel zaman x0.25 (fizik state korunur)
      final bool slowmo = golSineT > 1.8;
      animT += dt * (slowmo ? 0.25 : 1.0);
      spikerT += dt;
      if (golSineT > 0) golSineT = (golSineT - dt).clamp(0.0, 2.2);
      if (tribunZipla > 0) tribunZipla = (tribunZipla - dt / 1.4).clamp(0.0, 1.0);
      if (skorFlash > 0) skorFlash = (skorFlash - dt * 1.4).clamp(0.0, 1.0);
      if (hizEtiketT > 0) hizEtiketT = (hizEtiketT - dt).clamp(0.0, 1.0);
      if (sutT > 0) sutT = (sutT - dt).clamp(0.0, 0.3);
      if (sevincT > 0) sevincT = (sevincT - dt).clamp(0.0, 1.2);
      if (agUst > 0) agUst = (agUst - dt).clamp(0.0, 1.0);
      if (agAlt > 0) agAlt = (agAlt - dt).clamp(0.0, 1.0);
      if (dalisT > 0) {
        final int dt2 = dalisTakim;
        dalisT = (dalisT - dt).clamp(0.0, 1.0);
        if (dalisT <= 0 && dt2 >= 0) {
          // Kaleci yere dustu: 2 toz parcacigi (butce: konfeti+toz <= 30)
          final Offset kp = dt2 == 0 ? benimPos[10] : rakipPos[10];
          final Offset ekran = SahaPainter.proje(kp, sahaSize);
          toz.add(Toz(ekran + const Offset(-6, 4), const Offset(-22, -30), 0.5));
          toz.add(Toz(ekran + const Offset(6, 4), const Offset(22, -30), 0.5));
          parcButce();
          dalisTakim = -1;
        }
      }
      if (overlay.isNotEmpty && overlayT < 1) overlayT = (overlayT + dt * 3.2).clamp(0.0, 1.0);
      kartGuncelle(dt);
      tozGuncelle(dt);
      dakika += dt / 1.2; // 1x hizinda ~1.2 sn = 1 oyun dakikasi
      // 88'+ ve fark <= 1 ise en az 1 ekstra interaktif pozisyon garanti
      if (!ekstraPozisyonVerildi && dakika >= 88 && (skorBiz - skorRakip).abs() <= 1) {
        ekstraPozisyonVerildi = true;
        sonrakiInteraktif = true;
        if (sonrakiPozisyonDk > dakika + 1.5) sonrakiPozisyonDk = dakika + 1.5;
      }
      // Tehlike uyarisi: interaktif pozisyondan ~1.5 sn (1.3 oyun dk) once
      if (sonrakiInteraktif && !tehlikeGosterildi && !topUcuyor && sonrakiPozisyonDk - dakika <= 1.3) {
        tehlikeGosterildi = true;
        HapticFeedback.mediumImpact();
        final bool sonSans = dakika >= 88 && (skorBiz - skorRakip).abs() <= 1;
        mikroKartEkle(sonSans ? 'SON ŞANS!' : 'ATAK GELİYOR!', sonSans ? kAltin : const Color(0xFFFF7043), buyuk: true);
      }
      if (!topUcuyor && dakika >= sonrakiPozisyonDk) pozisyonDusur();
      simule(dt);
      konfetiGuncelle(dt);
      if (sarsinti > 0) sarsinti = (sarsinti - dt * 1.1).clamp(0.0, 1.0);
      // Rastgele spiker yorumu (sablon sistemi, max 2 tekrar)
      if (!topUcuyor && r.nextDouble() < 0.006 * dt * 25) {
        final bool formalite = (skorBiz - skorRakip).abs() >= 3;
        final List<int> adaylar = formalite
            ? <int>[14, 14, 4, 10]
            : (dakika >= 85 ? <int>[5, 8, 4, 12] : <int>[4, 6, 7, 9, 10, 11, 12, 13]);
        final String oy = r.nextBool()
            ? benimIsimler[r.nextInt(benimIsimler.length)]
            : rakipIsimler[r.nextInt(rakipIsimler.length)];
        sablonSoyle(adaylar[r.nextInt(adaylar.length)], oyuncu: oy);
      }
      if (dakika >= 45 && !devreYapildi && !topUcuyor) {
        devreYapildi = true;
        devreT = 0;
        fase = 'devre';
        spikerEkle('İlk yarı sona erdi! Devre arası. ⏸');
      }
      // hata #9: kullanici nisan alirken (interaktif) mac bitmesin
      if (dakika >= 90 && !topUcuyor && !interaktif) {
        dakika = 90;
        macBitti();
      }
    });
  }

  void kartGuncelle(double dt) {
    for (final MikroKart k in kartlar) {
      k.t += dt;
    }
    kartlar.removeWhere((MikroKart k) => k.t >= 1.0);
  }

  void parcButce() {
    while (konfeti.length + toz.length > 30) {
      if (konfeti.isNotEmpty) {
        konfeti.removeAt(0);
      } else {
        toz.removeAt(0);
      }
    }
  }

  // Pozisyon eventleri: interaktif olup olmayacagi onceden belli (tehlike uyarisi icin)
  void pozisyonDusur() {
    // Skora gore tempo: yenik takim 60'+ daha sik atak bulur, onde olan 80'+ yavaslar
    double aralik = 6 + r.nextDouble() * 8;
    if (skorBiz < skorRakip && dakika >= 60) aralik /= 1.8;
    if (skorBiz > skorRakip && dakika >= 80) aralik *= 1.5;
    sonrakiPozisyonDk = dakika + aralik;
    tehlikeGosterildi = false;
    if (sonrakiInteraktif) {
      sonrakiInteraktif = false;
      interaktifBaslat();
      return;
    }
    final double z = r.nextDouble();
    if (z < 0.5) {
      rakipAtak();
    } else {
      arkadasAtak();
    }
    // Siradaki pozisyonun turu simdi belli olsun (uyari icin)
    sonrakiInteraktif = r.nextDouble() < 0.40;
  }

  void simule(double dt) {
    const double hizK = 0.10; // saha orani / saniye
    for (int t = 0; t < 2; t++) {
      final List<Offset> pos = t == 0 ? benimPos : rakipPos;
      final List<Offset> gez = t == 0 ? benimGez : rakipGez;
      final bool hucum = topTakim == t;
      final double yon = t == 0 ? -1.0 : 1.0; // biz yukari, rakip asagi hucum eder
      // Topa en yakin iki oyuncu (top sahibi haric)
      int enYakin = -1;
      int ikinci = -1;
      double d1 = 1e9;
      double d2 = 1e9;
      for (int i = 0; i < 11; i++) {
        if (t == topTakim && i == topOyuncu && !topUcuyor) continue;
        final double d = (pos[i] - top).distance;
        if (d < d1) {
          d2 = d1;
          ikinci = enYakin;
          d1 = d;
          enYakin = i;
        } else if (d < d2) {
          d2 = d;
          ikinci = i;
        }
      }
      for (int i = 0; i < 11; i++) {
        Offset hedef;
        double carp = 0.55;
        if (!topUcuyor && t == topTakim && i == topOyuncu) {
          hedef = top;
          carp = 0.9;
        } else if (i == enYakin && (topUcuyor || t != topTakim)) {
          hedef = top;
          carp = 1.35; // topa kos
        } else if (i == ikinci && t != topTakim && !topUcuyor) {
          hedef = top;
          carp = 1.15;
        } else {
          final Offset baz = Offset(kDizilis[i][0], t == 0 ? kDizilis[i][1] : 1 - kDizilis[i][1]);
          final double kayma = (hucum ? 0.10 : -0.04) * yon;
          if ((gez[i] - pos[i]).distance < 0.012 || r.nextDouble() < 0.02 * dt) {
            gez[i] = Offset(
              (baz.dx + (r.nextDouble() - 0.5) * 0.10).clamp(0.05, 0.95),
              (baz.dy + kayma + (r.nextDouble() - 0.5) * 0.08).clamp(0.04, 0.97),
            );
          }
          hedef = gez[i];
        }
        pos[i] = yakla(pos[i], hedef, hizK * carp * dt);
      }
    }
    // Top: ucus animasyonu ya da sahibinin ayaginda
    if (topUcuyor) {
      ucusT += (dt * (ucusYavas ? 0.6 : 1.0)) / ucusSure;
      final double t = ucusT.clamp(0.0, 1.0);
      top = Offset(aral(ucusBas.dx, ucusBit.dx, t), aral(ucusBas.dy, ucusBit.dy, t));
      topYukseklik = sin(pi * t) * ucusKavis;
      topSpin += dt * 9; // dikis yaylari spin ile doner
      // Trail ring-buffer: son 8 konum
      topIz.add(top);
      if (topIz.length > 8) topIz.removeAt(0);
      if (ucusT >= 1) {
        topUcuyor = false;
        top = ucusBit;
        topYukseklik = 0;
        topIz.clear();
        final VoidCallback? cb = ucusSonu;
        ucusSonu = null;
        cb?.call(); // SONUC ancak simdi aciklanir
      }
    } else {
      final List<Offset> pos = topTakim == 0 ? benimPos : rakipPos;
      top = pos[topOyuncu] + Offset(0, topTakim == 0 ? -0.015 : 0.015);
      topSpin += dt * 1.5;
      pasSayac -= dt;
      if (pasSayac <= 0) {
        pasSayac = 0.9 + r.nextDouble() * 1.8;
        takimIciPas();
      }
    }
  }

  // Topu havalandir: golge yerde kalir, top buyuyup kuculur, sonuc hedefe varinca
  void topaUcus(Offset bit, {double sure = 0.9, double kavis = 0.5, bool yavas = false, VoidCallback? sonu}) {
    ucusBas = top;
    ucusBit = bit;
    ucusT = 0;
    ucusSure = sure;
    ucusKavis = kavis;
    ucusYavas = yavas;
    ucusSonu = sonu;
    topIz.clear();
    topUcuyor = true;
  }

  // Takim ici rastgele paslasma; bazen rakip araya girip topu kapar
  void takimIciPas() {
    if (r.nextDouble() < 0.16) {
      topTakim = 1 - topTakim;
      topGiden = r.nextInt(10);
    } else {
      int j = r.nextInt(10);
      if (j == topOyuncu) j = (j + 1) % 10;
      topGiden = j;
    }
    final List<Offset> pos = topTakim == 0 ? benimPos : rakipPos;
    final Offset hedef = pos[topGiden];
    topaUcus(hedef, sure: 0.55, kavis: 0.30, sonu: () {
      topOyuncu = topGiden;
    });
  }

  // ---- Gol efektleri ----

  void konfetiSac(Offset ekran) {
    for (int i = 0; i < 24; i++) {
      final double aci = r.nextDouble() * 2 * pi;
      final double h = 70 + r.nextDouble() * 200;
      konfeti.add(Konfeti(
        ekran,
        Offset(cos(aci) * h, sin(aci) * h - 170),
        kKonfetiRenkler[r.nextInt(kKonfetiRenkler.length)],
        1.2 + r.nextDouble() * 0.6, // ~1.8 sn donen konfeti
        4 + r.nextDouble() * 5,
      ));
    }
    parcButce();
  }

  void konfetiGuncelle(double dt) {
    for (final Konfeti k in konfeti) {
      k.p += k.v * dt;
      k.v += const Offset(0, 320) * dt;
      k.omur -= dt;
    }
    konfeti.removeWhere((Konfeti k) => k.omur <= 0);
  }

  void tozGuncelle(double dt) {
    for (final Toz t in toz) {
      t.p += t.v * dt;
      t.v += const Offset(0, 160) * dt;
      t.omur -= dt;
    }
    toz.removeWhere((Toz t) => t.omur <= 0);
  }

  void golEfekt(bool ustKale, String yazi, Color renk, {String alt = '', String? sevincKim}) {
    sarsinti = 1;
    golSineT = 2.2; // gol sinematigi (slow-mo + zoom + GOOOL + konfeti)
    tribunZipla = 1;
    skorFlash = 1;
    // Top kale agina carpar ve 1 sn elastik sonumle esner
    if (ustKale) {
      agUst = 1.0;
    } else {
      agAlt = 1.0;
    }
    if (sevincKim != null) {
      sevincT = 1.2;
      sevincAnahtar = sevincKim;
    }
    final Offset k = SahaPainter.proje(Offset(0.5, ustKale ? 0.0 : 1.0), sahaSize);
    konfetiSac(k);
    goster(yazi, renk, boyut: yazi.contains('GOOOL') ? 64 : 44, alt: alt);
  }

  // ---- Yapay zeka ataklari (once top ucusu, sonra sonuc) ----

  void rakipAtak() {
    final int idx = r.nextInt(rakipIsimler.length);
    final String oyuncu = rakipIsimler[idx];
    topTakim = 1;
    topOyuncu = idx < 11 ? idx : 10;
    // Sutcu rakip bizim kaleye (alt tarafa) yakinlasir
    final Offset sutYeri = Offset(0.30 + r.nextDouble() * 0.40, 0.78 + r.nextDouble() * 0.06);
    if (topOyuncu < 11) rakipPos[topOyuncu] = sutYeri;
    top = sutYeri;
    spikerEkle('$oyuncu tehlikeli bir noktada topla buluştu! Vuruşunu yapıyor... 😰');
    final bool golOlur = r.nextDouble() < 0.45;
    final Offset hedef;
    if (golOlur) {
      hedef = Offset(0.42 + r.nextDouble() * 0.16, 1.01); // aglara
    } else if (r.nextDouble() < 0.5) {
      hedef = Offset(0.42 + r.nextDouble() * 0.16, 0.985); // kaleci kurtarisi
    } else {
      hedef = Offset(0.30 + r.nextDouble() * 0.40, 0.96); // aut
    }
    topaUcus(hedef, sure: 0.85, kavis: 0.55, yavas: true, sonu: () {
      if (golOlur) {
        skorRakip++;
        spikerEkle('$oyuncu vurdu ve gol! ${widget.rakip.ad} skoru değiştiriyor. 😟');
        comboVur(false);
        golEfekt(false, 'RAKİP GOL 😟', Colors.red.shade300);
      } else if ((hedef.dy - 0.985).abs() < 0.01) {
        dalisT = 0.8;
        dalisTakim = 0; // bizim kaleci dalıyor
        dalisYon = hedef.dx < 0.5 ? -1 : 1;
        sablonSoyle(1);
        spikerEkle('$oyuncu şutunu çekti ama kaleci harika kurtardı! 🧤');
      } else {
        spikerEkle('$oyuncu topu auta gönderdi! Derin bir nefes aldık.');
      }
    });
  }

  void arkadasAtak() {
    final int ai = 1 + r.nextInt(benimIsimler.length - 1);
    final String ark = benimIsimler[ai];
    topTakim = 0;
    final Offset sutYeri = Offset(0.32 + r.nextDouble() * 0.36, 0.16 + r.nextDouble() * 0.05);
    if (ai < 11) {
      benimPos[ai] = sutYeri;
      topOyuncu = ai;
    }
    top = sutYeri;
    spikerEkle('$ark ceza sahası içinde boş durumda! Vuruyor... ⚡');
    topaUcus(Offset(0.40 + r.nextDouble() * 0.20, -0.01), sure: 0.85, kavis: 0.55, yavas: true, sonu: () {
      skorBiz++;
      comboVur(true);
      sablonSoyle(3, oyuncu: ark);
      golEfekt(true, 'GOOOL!', kAltin, alt: 'HARİKA GOL! ⚽ $ark', sevincKim: '0-$ai');
    });
  }

  void goster(String yazi, Color renk, {double boyut = 44, String alt = ''}) {
    overlayTimer?.cancel();
    setState(() {
      overlay = yazi;
      overlayRenk = renk;
      overlayBoyut = boyut;
      overlayAlt = alt;
      overlayT = 0;
    });
    overlayTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => overlay = '');
    });
  }

  // ---- Interaktif pozisyon ----

  void interaktifBaslat() {
    // 10x hizli ozetten dramatik kesintiyle sahaya don + otomatik 1x
    if (hiz == 10) hizAyarla(1);
    interaktif = true;
    nisan = null;
    guc = 0;
    nisanCekiliyor = false;
    gucCekiliyor = false;
    hedefTip = 'sut';
    hedefIndex = -1;
    hedefKose = 'sol';
    topTakim = 0;
    topOyuncu = 0;
    topUcuyor = false;
    ucusSonu = null;
    interaktifT = r.nextDouble() * 6;
    benimPos[0] = const Offset(0.5, 0.20);
    top = const Offset(0.5, 0.215);
    for (int i = 1; i <= 3; i++) {
      benimPos[i] = Offset(0.14 + 0.24 * (i - 1), 0.30 + 0.04 * (i % 2));
    }
    for (int i = 0; i < 4; i++) {
      rakipPos[i] = Offset(0.28 + 0.15 * i, 0.12 + 0.05 * (i % 2));
    }
    rakipPos[10] = const Offset(0.5, 0.045); // kaleci
    sablonSoyle(0, oyuncu: benimIsimler[0]);
    spikerEkle('${benimIsimler[0]} büyük bir pozisyon yakaladı! Oku sürükle, hedefi seç ve gücü ayarla! 🎯');
    secimTimer?.cancel();
    secimTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && interaktif) vurusYap(otomatik: true);
    });
  }

  void hizAyarla(int h) {
    hiz = h;
    hizEtiketT = 1;
    hizEtiket = h == 1 ? '▶ 1x' : (h == 2 ? '▶▶ 2x' : '▶▶▶ 10x');
  }

  void panBaslat(DragStartDetails d) {
    if (!interaktif || fase != 'oyun') return;
    if (d.localPosition.dy < 64) {
      gucCekiliyor = true;
      guc = 0;
    } else {
      nisanCekiliyor = true;
      nisanGuncelle(d.localPosition);
    }
    setState(() {});
  }

  void panGuncelle(DragUpdateDetails d) {
    if (!interaktif) return;
    setState(() {
      if (gucCekiliyor) {
        guc = (d.localPosition.dy / 190).clamp(0.0, 1.0);
      } else if (nisanCekiliyor) {
        nisanGuncelle(d.localPosition);
      }
    });
  }

  void panBitir(DragEndDetails d) {
    if (!interaktif) return;
    if (gucCekiliyor) {
      gucCekiliyor = false;
      vurusYap();
    } else {
      nisanCekiliyor = false;
    }
  }

  void nisanGuncelle(Offset p) {
    // Ekran noktasini perspektiften saha koordinatina cevir
    nisan = SahaPainter.tersProje(p, sahaSize);
    final Offset n = nisan!;
    if (n.dy < 0.10 && (n.dx - 0.5).abs() < 0.25) {
      hedefTip = 'sut';
      hedefIndex = -1;
      hedefKose = n.dx < 0.5 ? 'sol' : 'sağ';
      return;
    }
    int en = -1;
    double enD = 1e9;
    for (int i = 1; i < 11; i++) {
      final double dd = (benimPos[i] - n).distance;
      if (dd < enD) {
        enD = dd;
        en = i;
      }
    }
    if (enD < 0.12) {
      hedefTip = 'pas';
      hedefIndex = en;
    } else {
      hedefTip = 'sut';
      hedefIndex = -1;
      hedefKose = n.dx < 0.5 ? 'sol' : 'sağ';
    }
  }

  void vurusYap({bool otomatik = false}) {
    secimTimer?.cancel();
    final double g = (otomatik || guc <= 0.02) ? 0.55 : guc;
    final String tip = hedefTip;
    final int hi = hedefIndex;
    final String kose = hedefKose;
    setState(() {
      interaktif = false;
      nisan = null;
      guc = 0;
      gucCekiliyor = false;
      nisanCekiliyor = false;
      sonGuc = g;
      // Sut savurma animasyonu (300 ms geri-ileri + after-image)
      sutT = 0.3;
      sutAnahtar = '0-0';
    });
    if (tip == 'pas' && hi > 0) {
      pasSonuc(g, hi);
    } else {
      sutSonuc(g, kose);
    }
  }

  // ---- Vurus sonuclari: once top ucusu, karar top hedefe ULASINCA aciklanir ----

  void sutSonuc(double g, String kose) {
    sut++;
    gorevKontrol();
    final String ad = benimIsimler[0];
    final double kx = kose == 'sol' ? 0.42 : 0.58;
    final String sonuc;
    final Offset hedef;
    double kavis = 0.55;
    // Tatli nokta: birakma aninda kaleci hangi tarafta?
    final String kaleciTaraf = rakipPos[10].dx < 0.5 ? 'sol' : 'sağ';
    if (g < 0.25) {
      sonuc = 'zayif';
      hedef = Offset(0.5 + (r.nextDouble() - 0.5) * 0.08, 0.14); // kalenin onunde olecek
      kavis = 0.25;
    } else if (g > 0.90) {
      sonuc = 'sert';
      hedef = Offset(kx + (r.nextDouble() - 0.5) * 0.06, -0.12); // ustten aut
    } else {
      final int sutOz = ozellik(widget.kariyer, 'sut');
      final int bitOz = ozellik(widget.kariyer, 'bit');
      double p = 0.24 + (sutOz - 58) * 0.006 + (bitOz - 58) * 0.004 + kramponGucu(widget.kariyer) * 0.008;
      if (g >= 0.45 && g <= 0.75) {
        p += 0.08; // ideal sari bolge
        mikroKartEkle('MÜKEMMEL ZAMANLAMA!', kAltin);
      }
      // Kaleci konumu sonucu etkiler: kalecinin oldugu koseye vurmak riskli
      if (kose == kaleciTaraf) {
        p -= 0.12;
      } else {
        p += 0.05; // ters kose = tatli nokta
      }
      if (widget.zorluk == 'Kolay') p += 0.08;
      if (widget.zorluk == 'Zor') p -= 0.08;
      if (r.nextDouble() < p.clamp(0.05, 0.85)) {
        sonuc = 'gol';
        hedef = Offset(kx, -0.015); // aglara
      } else {
        final double z2 = r.nextDouble();
        if (z2 < 0.35) {
          sonuc = 'kurtaris';
          hedef = Offset(kx, 0.028);
        } else if (z2 < 0.55) {
          sonuc = 'direk';
          hedef = Offset(kose == 'sol' ? 0.38 : 0.62, -0.005);
        } else {
          sonuc = 'aut';
          hedef = Offset(kx + (r.nextDouble() < 0.5 ? -0.14 : 0.14), -0.05);
        }
      }
    }
    spikerEkle('$ad vuruşunu yaptı! Top havalandı...');
    // Vuruş mesafesi göstergesi (saha ~105 m varsayımı)
    final double mesafe = (top - const Offset(0.5, 0.0)).distance * 105;
    mesafeYazi = '${mesafe.toStringAsFixed(1).replaceAll('.', ',')} m';
    topaUcus(hedef, sure: 0.9, kavis: kavis, yavas: true, sonu: () => sutBitti(sonuc, ad, kose));
  }

  void sutBitti(String sonuc, String ad, String kose) {
    mesafeYazi = '';
    switch (sonuc) {
      case 'zayif':
        spikerEkle('$ad vurdu ama top çok zayıf! Kalenin önünde kaldı. 🐌');
        mikroKartEkle('DIŞARI!', Colors.redAccent);
        comboVur(false);
        break;
      case 'sert':
        spikerEkle('$ad çok sert vurdu! Top üstten auta çıktı! 🚀');
        mikroKartEkle('DIŞARI!', Colors.redAccent);
        comboVur(false);
        break;
      case 'gol':
        gol++;
        skorBiz++;
        comboVur(true);
        sablonSoyle(3, oyuncu: ad);
        spikerEkle('$ad $kose köşeye vurdu ve GOL! ${benimTakim.ad} ${skorBiz > skorRakip ? 'öne geçiyor' : 'skoru değiştiriyor'}! ⚽🎉');
        golEfekt(true, 'GOOOL!', kAltin, alt: '⚽ $ad', sevincKim: '0-0');
        break;
      case 'kurtaris':
        dalisT = 0.8;
        dalisTakim = 1; // rakip kaleci dalıyor
        dalisYon = kose == 'sol' ? -1 : 1;
        sablonSoyle(1);
        spikerEkle('$ad $kose köşeye vurdu ama kaleci harika kurtardı! 🧤');
        mikroKartEkle('KALECİ ÇIKARDI!', Colors.redAccent);
        comboVur(false);
        break;
      case 'direk':
        sablonSoyle(2);
        spikerEkle('$ad vurdu, top direkten döndü! 😱');
        mikroKartEkle('DİREK!', Colors.orangeAccent);
        comboVur(false);
        break;
      default:
        spikerEkle('$ad vurdu ama top az farkla auta gitti!');
        mikroKartEkle('DIŞARI!', Colors.redAccent);
        comboVur(false);
    }
  }

  void pasSonuc(double g, int hi) {
    final String ark = benimIsimler[hi];
    final int pasOz = ozellik(widget.kariyer, 'pas');
    final String ad = benimIsimler[0];
    if (g < 0.25) {
      topaUcus(benimPos[hi] + (top - benimPos[hi]) * 0.5, sure: 0.5, kavis: 0.2, sonu: () {
        spikerEkle('$ad pası kısa düştü, top kaybı! 🐌');
        mikroKartEkle('PAS HATASI!', Colors.redAccent);
        comboVur(false);
      });
      return;
    }
    if (g > 0.92) {
      topaUcus(Offset((benimPos[hi].dx + 0.3).clamp(0.0, 1.0), (benimPos[hi].dy + 0.25).clamp(0.0, 1.0)), sure: 0.6, kavis: 0.35, sonu: () {
        spikerEkle('$ad pası çok sert gönderdi, top taca çıktı!');
        mikroKartEkle('PAS HATASI!', Colors.redAccent);
        comboVur(false);
      });
      return;
    }
    final double p = 0.45 + (pasOz - 58) * 0.006 + kramponGucu(widget.kariyer) * 0.004;
    final bool basarili = r.nextDouble() < p.clamp(0.1, 0.95);
    final bool asistOlur = basarili && r.nextDouble() < 0.35 + kramponGucu(widget.kariyer) * 0.004;
    final Offset hedef = basarili ? benimPos[hi] : benimPos[hi] + Offset((r.nextDouble() - 0.5) * 0.2, 0.12);
    spikerEkle('$ad pasını çıkardı, top havada...');
    topaUcus(hedef, sure: 0.6, kavis: 0.4, yavas: asistOlur, sonu: () {
      if (!basarili) {
        spikerEkle('$ad pas verdi ama rakip araya girdi! 😕');
        mikroKartEkle('PAS HATASI!', Colors.redAccent);
        comboVur(false);
        return;
      }
      pas++;
      comboVur(true);
      mikroKartEkle('İSABET! +10', kYesil);
      topOyuncu = hi;
      if (!asistOlur) {
        spikerEkle('$ad harika bir pas çıkardı, $ark topla buluştu! 👟');
        return;
      }
      spikerEkle('$ark topla buluştu, vuruşunu yapıyor... ⚡');
      // Asist golu: ikinci ucus kaleye
      topaUcus(Offset(0.40 + r.nextDouble() * 0.20, -0.015), sure: 0.7, kavis: 0.55, yavas: true, sonu: () {
        asist++;
        skorBiz++;
        comboVur(true);
        sablonSoyle(3, oyuncu: ark);
        spikerEkle('$ark, $ad pasında topu ağlara gönderdi! ASİST! 🎯🎉');
        golEfekt(true, 'GOOOL!', kAltin, alt: '👟 ASİST! $ad  •  ⚽ $ark', sevincKim: '0-$hi');
      });
    });
  }

  void macBitti() {
    fase = 'sonuc';
    final bool galibiyet = skorBiz > skorRakip;
    final bool berabere = skorBiz == skorRakip;
    spikerEkle('Maç sona erdi! Skor: $skorBiz v $skorRakip 📣');
    goster(galibiyet ? 'KAZANDIN! 🎉' : (berabere ? 'BERABERLİK 🤝' : 'KAYBETTİN 😞'), galibiyet ? kYesil : (berabere ? Colors.orange : Colors.red));
    // hata #10: timer alanda tutulur, dispose'da iptal edilir
    sonucTimer?.cancel();
    sonucTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() {
        overlay = '';
        panelT = 0; // flip ile acilir
        fase = 'panel';
      });
    });
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
      <String>['Takım arkadaşlarım olmadan başaramazdım, bu galibiyet hepimizin! 🤝', 'Takım +10 · Taraftar +5 · Teknik Direktör +10'],
      <String>['Ben bu takımın yıldızıyım, daha çok gol atacağım! 😎', 'Takım −5 · Taraftar +10 · Teknik Direktör −5'],
      <String>['Daha çok çalışmam gerektiğini biliyorum, söz veriyorum! 💪', 'Takım +5 · Taraftar −5 · Teknik Direktör +10'],
    ];
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final Color rakipRenk = Color(widget.rakip.renk1).value == Color(benimTakim.renk1).value ? Colors.red.shade700 : Color(widget.rakip.renk1);
    String kisalt(String ad) => ad.length <= 3 ? ad.toUpperCase() : ad.substring(0, 3).toUpperCase();
    // Gol sinematigi kamera zoomu: topa 1.18 zoom easeOutCubic + geri
    double zoomK = 0;
    if (golSineT > 0) {
      final double gecen = 2.2 - golSineT;
      zoomK = gecen < 0.4 ? Curves.easeOutCubic.transform(gecen / 0.4) : (golSineT / 1.8).clamp(0.0, 1.0);
    }
    final double kameraScale = (interaktif ? 1.9 : 1.0) * (1 + 0.18 * zoomK);
    Alignment kameraHiza = interaktif ? const Alignment(0, -0.55) : Alignment.center;
    if (!interaktif && zoomK > 0 && sahaSize.width > 1) {
      final Offset tp2 = SahaPainter.proje(top, sahaSize);
      kameraHiza = Alignment(
        ((tp2.dx / sahaSize.width) * 2 - 1).clamp(-0.8, 0.8),
        ((tp2.dy / sahaSize.height) * 2 - 1).clamp(-0.8, 0.8),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Kompakt yayin tarzi skor tabelasi (golde flas)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFF0A1622), Color(0xFF0D1B2A)],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(15)),
                    child: const Text('⚽', style: TextStyle(fontSize: 14)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Color.lerp(Colors.black.withOpacity(0.72), kAltin.withOpacity(0.85), skorFlash * 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kAltin.withOpacity(0.7 + skorFlash * 0.3), width: 1.2 + skorFlash * 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(kisalt(benimTakim.ad), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('$skorBiz - $skorRakip', style: const TextStyle(color: kAltin, fontSize: 19, fontWeight: FontWeight.w900)),
                        ),
                        Text(kisalt(widget.rakip.ad), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(color: kYesil, borderRadius: BorderRadius.circular(7)),
                          child: Text("${dakika.floor()}'", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        if (dakika >= 45)
                          const Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Text('2Y', style: TextStyle(color: kAltin, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  for (final int h in <int>[1, 2, 10])
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: GestureDetector(
                        onTap: () => setState(() => hizAyarla(h)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: hiz == h ? kAltin : Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: hiz == h ? kAltin : Colors.white24),
                          ),
                          child: Text('${h}x',
                              style: TextStyle(color: hiz == h ? Colors.black : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Saha
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints cons) {
                  final Size yeni = Size(cons.maxWidth, cons.maxHeight);
                  // hata #13: build icinde state yazimi yerine post-frame callback
                  if (yeni != sahaSize) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && yeni != sahaSize) setState(() => sahaSize = yeni);
                    });
                  }
                  return Stack(
                    children: <Widget>[
                      // Statik katman: zemin + tribun + pano + cizgiler (ayri RepaintBoundary)
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: CustomPaint(painter: zeminPainter),
                        ),
                      ),
                      // Dinamik katman: oyuncular + top + parcaciklar
                      Transform.translate(
                        offset: Offset(sin(sarsinti * 40) * 6 * sarsinti, cos(sarsinti * 33) * 5 * sarsinti),
                        child: Transform.scale(
                          scale: kameraScale,
                          alignment: kameraHiza,
                          child: SizedBox(
                            width: cons.maxWidth,
                            height: cons.maxHeight,
                            child: GestureDetector(
                              onPanStart: panBaslat,
                              onPanUpdate: panGuncelle,
                              onPanEnd: panBitir,
                              child: CustomPaint(
                                size: yeni,
                                painter: sahaPainter,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Vignette: ayri RepaintBoundary katmani
                      Positioned.fill(
                        child: IgnorePointer(
                          child: RepaintBoundary(
                            child: CustomPaint(painter: VinyetPainter()),
                          ),
                        ),
                      ),
                      // 10x hizli ozet: ekran kararir, sadece spiker + dk + skor akar
                      if (hiz == 10 && fase == 'oyun' && !interaktif)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              color: Colors.black.withOpacity(0.88),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Text('HIZLI ÖZET', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Text("$skorBiz - $skorRakip   ${dakika.floor()}'",
                                      style: const TextStyle(color: kAltin, fontSize: 34, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 8),
                                  if (spiker.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: Text('🎙 ${spikerSonYazi()}',
                                          maxLines: 2,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      // Interaktif bilgi kutusu
                      if (interaktif)
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(14), border: Border.all(color: kAltin)),
                            child: Text(
                              hedefTip == 'pas' && hedefIndex > 0
                                  ? '🎯 Hedef: ${benimIsimler[hedefIndex]} (PAS) — Yukarıdan aşağı çekip bırak: GÜÇ!'
                                  : '🎯 Hedef: Kalenin $hedefKose köşesi (ŞUT) — Yukarıdan aşağı çekip bırak: GÜÇ!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      // Guc gostergesi + tatli nokta cubugu
                      if (interaktif) gucCubugu(),
                      if (interaktif)
                        Positioned(
                          top: 6,
                          left: 8,
                          child: tatliNoktaBar(),
                        ),
                      // Mac ici mini gorev cipleri (sag ust)
                      if (fase == 'oyun')
                        Positioned(
                          top: 8,
                          right: 10,
                          child: gorevCipleri(),
                        ),
                      // FORMDAYIM rozeti (sol ust)
                      if (combo >= 3 && fase == 'oyun')
                        Positioned(
                          top: 8,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFF7043), width: 1.5),
                            ),
                            child: Text('🔥 FORMDAYIM x$combo',
                                style: const TextStyle(color: Color(0xFFFF7043), fontSize: 13, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      // Mikro sonuc kartlari (floating text)
                      for (final MikroKart k in kartlar) mikroKartWidget(k, cons),
                      // Hiz degisim etiketi (1 sn)
                      if (hizEtiketT > 0)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Opacity(
                            opacity: hizEtiketT.clamp(0.0, 1.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10), border: Border.all(color: kAltin)),
                              child: Text(hizEtiket, style: const TextStyle(color: kAltin, fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      // Vuruş mesafesi kutusu
                      if (mesafeYazi.isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: kAltin.withOpacity(0.8), width: 1.2),
                            ),
                            child: Text(mesafeYazi, style: const TextStyle(color: kAltin, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          ),
                        ),
                      // GOOOL banneri (yarim siyah bant + dev yazi)
                      if (overlay.isNotEmpty) golBanneri(),
                      // Devre arası paneli
                      if (fase == 'devre') devrePanel(),
                      // Maç sonu paneli
                      if (fase == 'panel') sonucPanel(),
                      // Röportaj
                      if (fase == 'roportaj') roportajPanel(),
                    ],
                  );
                },
              ),
            ),
            // Alt bar: spiker (max 5 satir, son satir yazi makinesi efektli)
            Container(
              color: Colors.black.withOpacity(0.75),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              height: 96,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  for (int i = 0; i < spiker.length; i++)
                    Text('🎙 ${i == spiker.length - 1 ? spikerSonYazi() : spiker[i]}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: i == spiker.length - 1 ? kAltin : Colors.white70,
                          fontSize: 12,
                          fontWeight: i == spiker.length - 1 ? FontWeight.bold : FontWeight.normal,
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Yazi makinesi efekti: 20 ms/harf pop-in
  String spikerSonYazi() {
    if (spiker.isEmpty) return '';
    final String s = spiker.last;
    final int n = (spikerT / 0.02).floor();
    return n >= s.length ? s : s.substring(0, n.clamp(0, s.length));
  }

  Widget mikroKartWidget(MikroKart k, BoxConstraints cons) {
    final double op = (1 - k.t).clamp(0.0, 1.0);
    final double yuk = k.t * 46; // yukari suzulur
    if (k.buyuk) {
      return Positioned(
        top: cons.maxHeight * 0.30 - yuk,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Opacity(
            opacity: op,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: k.renk, width: 2),
                ),
                child: Text(k.yazi, style: TextStyle(color: k.renk, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ),
          ),
        ),
      );
    }
    final int idx = kartlar.indexOf(k);
    return Positioned(
      top: cons.maxHeight * 0.16 + idx * 30 - yuk,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Opacity(
          opacity: op,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: k.renk.withOpacity(0.9)),
              ),
              child: Text(k.yazi, style: TextStyle(color: k.renk, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget gorevCipleri() {
    const List<String> adlar = <String>['İlk şutunu çek', '2 isabetli pas', 'Combo x3'];
    final List<int> hedefler = <int>[1, 2, 3];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (int i = 0; i < 3; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: gorevBitti[i] ? kYesil.withOpacity(0.9) : Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: gorevBitti[i] ? Colors.white : Colors.white38),
            ),
            child: Text(
              gorevBitti[i] ? '✓ ${adlar[i]}' : '${adlar[i]} ${gorevIlerleme[i]}/${hedefler[i]}',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  // Tatli nokta cubugu: kale genisligi; koseler yesil, kaleci bolgesi kirmizi
  Widget tatliNoktaBar() {
    final double kx = ((rakipPos[10].dx - 0.38) / 0.24).clamp(0.0, 1.0); // kale agzindaki konum
    const double gen = 120;
    const double yuk = 14;
    return Container(
      width: gen,
      height: yuk,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white70, width: 1.2),
        color: Colors.black54,
      ),
      child: Stack(
        children: <Widget>[
          // yesil tatli koseler
          Positioned(left: 0, top: 0, bottom: 0, width: gen * 0.25, child: Container(color: kYesil.withOpacity(0.75))),
          Positioned(right: 0, top: 0, bottom: 0, width: gen * 0.25, child: Container(color: kYesil.withOpacity(0.75))),
          // kaleci kirmizi bolge (kayar)
          Positioned(
            left: (kx * gen - gen * 0.10).clamp(0.0, gen * 0.8),
            top: 0,
            bottom: 0,
            width: gen * 0.20,
            child: Container(color: Colors.redAccent.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }

  // GOOOL / sonuc banneri: yarim siyah bant, overshoot giris, 10° tilt sallanim
  Widget golBanneri() {
    final bool golYazi = overlay.contains('GOOOL');
    return Center(
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: double.infinity,
              color: Colors.black.withOpacity(0.55),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Transform.scale(
                scale: 0.6 + 0.4 * Curves.elasticOut.transform(overlayT),
                child: Transform.rotate(
                  angle: sin(overlayT * 18) * 0.17 * (1 - overlayT), // ~10° tilt sallanim
                  child: Opacity(
                    opacity: (overlayT * 2.5).clamp(0.0, 1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Stack(
                          children: <Widget>[
                            Text(
                              overlay,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: overlayBoyut,
                                fontWeight: FontWeight.w900,
                                fontStyle: golYazi ? FontStyle.italic : FontStyle.normal,
                                letterSpacing: 2,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 4
                                  ..strokeJoin = StrokeJoin.round
                                  ..color = golYazi ? const Color(0xFFE63946) : Colors.black,
                              ),
                            ),
                            Text(
                              overlay,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: golYazi ? Colors.white : overlayRenk,
                                fontSize: overlayBoyut,
                                fontWeight: FontWeight.w900,
                                fontStyle: golYazi ? FontStyle.italic : FontStyle.normal,
                                letterSpacing: 2,
                                shadows: <Shadow>[
                                  Shadow(blurRadius: 26, color: overlayRenk.withOpacity(0.85)),
                                  const Shadow(blurRadius: 6, color: Colors.black),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (overlayAlt.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.78),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: overlayRenk.withOpacity(0.7)),
                            ),
                            child: Text(
                              overlayAlt,
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget gucCubugu() {
    final Color renk = guc < 0.40 ? kYesil : (guc < 0.75 ? Colors.yellow : Colors.red);
    return Positioned(
      top: 6,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 46,
          height: 190,
          alignment: Alignment.topCenter,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: FractionallySizedBox(
            heightFactor: guc <= 0 ? 0.02 : guc,
            widthFactor: 1,
            alignment: Alignment.topCenter,
            child: Container(
              decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }

  Widget devrePanel() {
    final double k = (devreT / 1.2).clamp(0.0, 1.0); // sayac animasyonu
    Widget sayac(String etiket, int deger, String ikon) {
      final int goster = (deger * k).round();
      return Column(
        children: <Widget>[
          Text(ikon, style: const TextStyle(fontSize: 22)),
          Text('$goster', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kYesil)),
          Text(etiket, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      );
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.all(30),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('⏸ DEVRE ARASI', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kYesil, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text('$skorBiz v $skorRakip', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                sayac('Gol', gol, '⚽'),
                const SizedBox(width: 26),
                sayac('Pas', pas, '👟'),
                const SizedBox(width: 26),
                sayac('Şut', sut, '🥅'),
              ],
            ),
            const SizedBox(height: 6),
            Text('Asist: $asist', style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 12),
            buyukButon(
              yazi: '▶ Maça Devam Et',
              renk: kYesil,
              onPressed: () {
                setState(() {
                  fase = 'oyun';
                  spikerEkle('İkinci yarı başladı! 📣');
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget sonucPanel() {
    final bool galibiyet = skorBiz > skorRakip;
    final bool berabere = skorBiz == skorRakip;
    // 1.5 sn bekleme (sonucTimer) sonrasi flip ile acilir
    final double flip = (1 - panelT.clamp(0.0, 1.0)) * pi / 2;
    return Center(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(flip),
        child: Container(
          margin: const EdgeInsets.all(26),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('MAÇ SONUCU', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.black45)),
              const SizedBox(height: 4),
              Text(galibiyet ? '🎉 Kazandın!' : (berabere ? '🤝 Beraberlik' : '😞 Kaybettin'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('$skorBiz v $skorRakip', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
              const Divider(height: 20),
              const Text('📋 Maç Bilgilerin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kYesil)),
              const SizedBox(height: 6),
              Text('⚽ Gol: $gol    🎯 Asist: $asist', style: const TextStyle(fontSize: 19)),
              Text('👟 Pas: $pas    🥅 Şut: $sut', style: const TextStyle(fontSize: 19)),
              const SizedBox(height: 8),
              Text('⭐ Maç Reytingin: ${rating().toStringAsFixed(1)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTuruncu)),
              const SizedBox(height: 12),
              buyukButon(
                yazi: '🎤 Röportaja Git',
                onPressed: () {
                  roportajHazirla();
                  setState(() => fase = 'roportaj');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget roportajPanel() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(22),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('🎤 Maç Sonrası Röportaj', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
              child: Text('🎙 "$roportajSoru"', style: const TextStyle(fontSize: 17, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 10),
            if (roportajEtki.isEmpty)
              for (final List<String> cevap in roportajCevaplar)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F8E9),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => setState(() => roportajEtki = cevap[1]),
                      child: Text(cevap[0], style: const TextStyle(fontSize: 15)),
                    ),
                  ),
                )
            else ...<Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFFFF9C4), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: <Widget>[
                    const Text('📊 Etkisi:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(roportajEtki, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              buyukButon(
                yazi: '🏠 Kariyere Dön',
                renk: kYesil,
                onPressed: () {
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
            ],
          ],
        ),
      ),
    );
  }
}

// ---------- STATIK KATMAN: zemin + tribun + pano + cizgiler ----------
// (ayri RepaintBoundary icinde; sadece tribun ziplamasi / pano donusu degisince yenilenir)
class ZeminPainter extends CustomPainter {
  final _MacEkraniState s;
  ZeminPainter(this.s);

  // Seed'li tribun noktalari (bir kez uretilir, ~400 nokta, 2 katman)
  List<Offset>? _noktalar; // x: 0..1 gen, y: 0..1 tribun derinligi
  List<int>? _renkIdx;
  static const List<Color> kPalet = <Color>[
    Color(0xFFE63946), Color(0xFFF1FA8C), Color(0xFF457B9D), Color(0xFFF4F4F4), Color(0xFF2A9D8F),
  ];
  static const List<String> kMarkalar = <String>['CEA GAMES', 'YILDIZ SPOR', 'KRAMPO MAX'];
  static const List<Color> kMarkaRenk = <Color>[Color(0xFFFFD54F), Color(0xFF64B5F6), Color(0xFFEF5350)];

  void tribunHazirla() {
    if (_noktalar != null) return;
    final Random rr = Random(42);
    _noktalar = <Offset>[];
    _renkIdx = <int>[];
    for (int i = 0; i < 400; i++) {
      _noktalar!.add(Offset(rr.nextDouble(), rr.nextDouble()));
      _renkIdx!.add(rr.nextInt(kPalet.length));
    }
  }

  void yazi(Canvas canvas, String metin, Offset merkez, double boyut, Color renk, {bool kalin = false}) {
    final TextPainter tp = TextPainter(
      text: TextSpan(text: metin, style: TextStyle(color: renk, fontSize: boyut, fontWeight: kalin ? FontWeight.bold : FontWeight.normal)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, merkez - Offset(tp.width / 2, tp.height / 2));
  }

  // Saha icindeki dortgeni (saha koordinatlarindan) ciz
  Path sahaYolu(Size size, double x1, double y1, double x2, double y2) {
    final Offset a = SahaPainter.proje(Offset(x1, y1), size);
    final Offset b = SahaPainter.proje(Offset(x2, y1), size);
    final Offset c = SahaPainter.proje(Offset(x2, y2), size);
    final Offset d = SahaPainter.proje(Offset(x1, y2), size);
    return Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..lineTo(d.dx, d.dy)
      ..close();
  }

  void cizgi(Canvas canvas, Size size, double x1, double y1, double x2, double y2, Paint p) {
    canvas.drawLine(SahaPainter.proje(Offset(x1, y1), size), SahaPainter.proje(Offset(x2, y2), size), p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    tribunHazirla();
    final double w = size.width;
    final double h = size.height;
    final double ustY = h * SahaPainter.ust;
    final double altY = h * SahaPainter.alt;

    // --- Gercek saha fotografi (varsa): cim agirlikli kaynak, ustte tribun biraz gorunur.
    // Resmin cizgileri bizim perspektifle oturmadigindan saha cizgileri / kod tribunu /
    // panolar cizilmez; kale direkleri + ince isik katmani korunur. ---
    final ui.Image? zeminImg = Resimler.saha;
    if (zeminImg != null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF0A140D));
      final Rect dst = Rect.fromLTWH(0, 0, w, h);
      canvas.drawImageRect(zeminImg, coverKaynak(zeminImg, dst, yBas: 0.06), dst, Paint()..filterQuality = FilterQuality.medium);
      // 2 buyuk yumusak projektor isigi elipsi (resmin uzerinde ince katman)
      final Paint isikR = Paint()..color = const Color(0xFFFFF8E1).withOpacity(0.05);
      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.30, h * (SahaPainter.ust + SahaPainter.alt) / 2), width: w * 0.55, height: (altY - ustY) * 0.7), isikR);
      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.72, h * (SahaPainter.ust + SahaPainter.alt) / 2 + 10), width: w * 0.55, height: (altY - ustY) * 0.7), isikR);
      // Kale direkleri (ag dokusu dinamik katmanda)
      final Paint direkR = Paint()
        ..color = Colors.white
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      for (final bool ust in <bool>[true, false]) {
        final double sy = ust ? 0.0 : 1.0;
        final Offset sd = SahaPainter.proje(Offset(0.38, sy), size);
        final Offset sg = SahaPainter.proje(Offset(0.62, sy), size);
        canvas.drawCircle(sd, 3, Paint()..color = Colors.white);
        canvas.drawCircle(sg, 3, Paint()..color = Colors.white);
        canvas.drawLine(sd, sg, direkR);
      }
      return;
    }

    // --- Stadyum zemini (saha disi koyu) ---
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF14261A));

    // --- Tribun: 2 katman, seed'li ~400 nokta; golde 4px ziplama dalgasi ---
    final double tribunAlt = ustY - 16;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, tribunAlt), Paint()..color = const Color(0xFF1C272E));
    // katman ayrimi
    canvas.drawRect(Rect.fromLTWH(0, tribunAlt * 0.5, w, 2), Paint()..color = Colors.black38);
    for (int i = 0; i < _noktalar!.length; i++) {
      final Offset n = _noktalar![i];
      final double nx = n.dx * w;
      final double ny = 3 + n.dy * (tribunAlt - 8);
      // gol ziplamasi: x'e gore dalga, 4 px
      double zip = 0;
      if (s.tribunZipla > 0) {
        zip = -4 * s.tribunZipla * (0.5 + 0.5 * sin(n.dx * 14 + s.tribunZipla * 20));
      }
      canvas.drawCircle(Offset(nx, ny + zip), 1.8, Paint()..color = kPalet[_renkIdx![i]]);
    }

    // --- Reklam panolari: ust kenar boyunca yamuga paralel serit, 3 donen metin ---
    final Offset pSol = SahaPainter.proje(const Offset(0, -0.035), size);
    final Offset pSag = SahaPainter.proje(const Offset(1, -0.035), size);
    final Path pano = Path()
      ..moveTo(pSol.dx, pSol.dy - 6)
      ..lineTo(pSag.dx, pSag.dy - 6)
      ..lineTo(pSag.dx, pSag.dy + 8)
      ..lineTo(pSol.dx, pSol.dy + 8)
      ..close();
    canvas.drawPath(pano, Paint()..color = const Color(0xFF060606));
    final int mi = (s.animT / 6).floor() % kMarkalar.length; // 6 sn'de degisir
    final double panoGen = (pSag.dx - pSol.dx);
    for (int k = 0; k < 4; k++) {
      yazi(canvas, kMarkalar[mi], Offset(pSol.dx + panoGen * (0.14 + 0.24 * k), (pSol.dy + pSag.dy) / 2 + 1), 9, kMarkaRenk[mi], kalin: true);
    }

    // --- Cim: #3E7C43 zemin + 8 dikey bicilmis serit (#4A9152 alfa 0.5) ---
    canvas.drawPath(sahaYolu(size, -0.02, -0.02, 1.02, 1.02), Paint()..color = const Color(0xFF3E7C43));
    for (int i = 0; i < 8; i++) {
      if (i.isOdd) {
        canvas.drawPath(
          sahaYolu(size, i / 8, -0.02, (i + 1) / 8, 1.02),
          Paint()..color = const Color(0xFF4A9152).withOpacity(0.5),
        );
      }
    }
    // --- 2 buyuk yumusak projektor isigi elipsi (#FFF8E1 alfa 0.06) ---
    final Paint isik = Paint()..color = const Color(0xFFFFF8E1).withOpacity(0.06);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.30, h * (SahaPainter.ust + SahaPainter.alt) / 2), width: w * 0.55, height: (altY - ustY) * 0.7), isik);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.72, h * (SahaPainter.ust + SahaPainter.alt) / 2 + 10), width: w * 0.55, height: (altY - ustY) * 0.7), isik);

    // --- Beyaz saha cizgileri ---
    final Paint ciz = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final Path dis = sahaYolu(size, 0, 0, 1, 1);
    canvas.drawPath(dis, ciz);
    cizgi(canvas, size, 0, 0.5, 1, 0.5, ciz);
    // Orta yuvarlak (perspektif elips)
    final Offset oc = SahaPainter.proje(const Offset(0.5, 0.5), size);
    final double g5 = SahaPainter.genOran(0.5);
    canvas.drawOval(
      Rect.fromCenter(center: oc, width: 0.30 * SahaPainter.sahaGen * g5 * w, height: 0.15 * (SahaPainter.alt - SahaPainter.ust) * h),
      ciz,
    );
    canvas.drawCircle(oc, 2.5, Paint()..color = Colors.white);
    // Ceza sahalari + kale alanlari
    for (final List<double> rr in <List<double>>[
      <double>[0.22, 0, 0.78, 0.15],
      <double>[0.22, 0.85, 0.78, 1],
      <double>[0.36, 0, 0.64, 0.055],
      <double>[0.36, 0.945, 0.64, 1],
    ]) {
      canvas.drawPath(sahaYolu(size, rr[0], rr[1], rr[2], rr[3]), ciz);
    }

    // --- Kale direkleri (ag dokusu dinamik katmanda) ---
    final Paint direk = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    for (final bool ust in <bool>[true, false]) {
      final double sy = ust ? 0.0 : 1.0;
      final Offset sd = SahaPainter.proje(Offset(0.38, sy), size);
      final Offset sg = SahaPainter.proje(Offset(0.62, sy), size);
      canvas.drawCircle(sd, 3, Paint()..color = Colors.white);
      canvas.drawCircle(sg, 3, Paint()..color = Colors.white);
      canvas.drawLine(sd, sg, direk);
    }
  }

  @override
  bool shouldRepaint(covariant ZeminPainter oldDelegate) => true;
}

// ---------- VIGNETTE: ayri RepaintBoundary katmani ----------
class VinyetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          radius: 1.15,
          colors: <Color>[Colors.transparent, Colors.black.withOpacity(0.30)],
          stops: const <double>[0.68, 1.0],
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(covariant VinyetPainter oldDelegate) => false;
}

// ---------- DINAMIK KATMAN: oyuncular + top + parcaciklar ----------
class SahaPainter extends CustomPainter {
  final _MacEkraniState s;
  SahaPainter(this.s);

  // hata #11: static YOK — kosma fazlari painter instance alaninda
  final Map<String, Offset> _sonPos = <String, Offset>{};
  final Map<String, double> _kosFaz = <String, double>{};
  final Map<String, double> _yon = <String, double>{}; // sprite yatay flip yonu (1=sol, -1=sag)
  // TextPainter cache (isim/forma no tekrar layout edilmez)
  final Map<String, TextPainter> _tpCache = <String, TextPainter>{};

  // --- Yamuk perspektif projeksiyon (yan TV kamerasi) ---
  // Saha ekranin orta ~%55'inde; alt kenar 1.0x, ust kenar 0.78x genislik.
  static const double ust = 0.20; // h orani (ustte tribun + pano)
  static const double alt = 0.78; // h orani
  static const double ortaX = 0.5;
  static const double ustGen = 0.78; // ust kenar genislik carpani
  static const double sahaGen = 0.96; // taban genisligi (w orani)

  static double genOran(double d) => ustGen + (1 - ustGen) * d;
  static double derinlikOlcek(double d) => 0.62 + 0.38 * d;

  // Saha koordinatini (0..1) ekrana donusturur
  static Offset proje(Offset saha, Size size) {
    final double d = saha.dy;
    final double g = genOran(d);
    return Offset(
      size.width * (ortaX + (saha.dx - 0.5) * sahaGen * g),
      size.height * (ust + d * (alt - ust)),
    );
  }

  // Ekran noktasini saha koordinatina cevirir (nisan icin)
  static Offset tersProje(Offset p, Size size) {
    final double d = ((p.dy / size.height - ust) / (alt - ust)).clamp(0.0, 1.0);
    final double g = genOran(d);
    final double x = (0.5 + (p.dx / size.width - ortaX) / (sahaGen * g)).clamp(0.0, 1.0);
    return Offset(x, d);
  }

  TextPainter tp(String metin, double boyut, Color renk, {bool kalin = false, bool kontur = false}) {
    final String anahtar = '$metin|$boyut|${renk.value}|$kalin|$kontur';
    return _tpCache.putIfAbsent(
      anahtar,
      () => TextPainter(
        text: TextSpan(
          text: metin,
          style: TextStyle(
            color: kontur ? null : renk,
            fontSize: boyut,
            fontWeight: kalin ? FontWeight.bold : FontWeight.normal,
            shadows: kontur ? null : const <Shadow>[Shadow(blurRadius: 2, color: Colors.black)],
            foreground: kontur
                ? (Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2
                  ..color = renk)
                : null,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
  }

  void yazi(Canvas canvas, String metin, Offset merkez, double boyut, Color renk, {bool kalin = false}) {
    final TextPainter t = tp(metin, boyut, renk, kalin: kalin);
    t.paint(canvas, merkez - Offset(t.width / 2, t.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    // --- Kale aglari (6x4 grid, golde top yonunde 8-14px esner + elastik sonum) ---
    kaleAgi(canvas, size, true);
    kaleAgi(canvas, size, false);

    // --- Nisan oku (interaktif modda) ---
    if (s.interaktif && s.nisan != null) {
      final Offset a = proje(s.benimPos[0], size);
      final Offset b = proje(s.nisan!, size);
      final Paint ok = Paint()
        ..color = Colors.yellow
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(a, b, ok);
      final Offset f = b - a;
      if (f.distance > 4) {
        final Offset u = f / f.distance;
        canvas.drawLine(b, Offset(b.dx - u.dx * 14 - u.dy * 7, b.dy - u.dy * 14 + u.dx * 7), ok);
        canvas.drawLine(b, Offset(b.dx - u.dx * 14 + u.dy * 7, b.dy - u.dy * 14 - u.dx * 7), ok);
      }
      if (s.hedefTip == 'sut') {
        final Offset k = proje(Offset(s.hedefKose == 'sol' ? 0.42 : 0.58, 0.0), size);
        canvas.drawCircle(k, 14, Paint()..color = Colors.yellow.withOpacity(0.45));
        canvas.drawCircle(
            k,
            14,
            Paint()
              ..color = Colors.yellow
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
      }
    }

    // --- Golgeler: her oyuncu altinda derinlikle kuculen yassi elips, TEK path ---
    final Path golgeler = Path();
    for (int t = 0; t < 2; t++) {
      final List<Offset> pos = t == 0 ? s.benimPos : s.rakipPos;
      for (int i = 0; i < 11; i++) {
        final Offset g = proje(pos[i], size);
        final double ol = derinlikOlcek(pos[i].dy.clamp(0.0, 1.0));
        final double gh = size.height * 0.11 * ol;
        golgeler.addOval(Rect.fromCenter(center: g + Offset(0, 2), width: gh * 0.52, height: gh * 0.14));
      }
    }
    canvas.drawPath(golgeler, Paint()..color = Colors.black.withOpacity(0.25));

    // --- Oyuncular: uzak (kucuk dy) once cizilir ---
    final List<List<int>> sirali = <List<int>>[];
    for (int t = 0; t < 2; t++) {
      final List<Offset> pos = t == 0 ? s.benimPos : s.rakipPos;
      final List<int> idx = List<int>.generate(11, (int i) => i)..sort((int a, int b) => pos[a].dy.compareTo(pos[b].dy));
      for (final int i in idx) {
        sirali.add(<int>[t, i]);
      }
    }
    sirali.sort((List<int> a, List<int> b) {
      final Offset pa = a[0] == 0 ? s.benimPos[a[1]] : s.rakipPos[a[1]];
      final Offset pb = b[0] == 0 ? s.benimPos[b[1]] : s.rakipPos[b[1]];
      return pa.dy.compareTo(pb.dy);
    });
    final Color rakipRenk = Color(s.widget.rakip.renk1).value == Color(s.benimTakim.renk1).value ? Colors.red.shade700 : Color(s.widget.rakip.renk1);
    for (final List<int> ti in sirali) {
      final int t = ti[0];
      final int i = ti[1];
      if (t == 1) {
        final bool topOnda = !s.topUcuyor && s.topTakim == 1 && s.topOyuncu == i;
        oyuncuCiz(canvas, size, s.rakipPos[i], rakipRenk, Color(s.widget.rakip.renk2), i + 1, s.rakipIsimler[i], false, false, i, kaleci: i == 10, topOnda: topOnda, takim: 1);
      } else {
        final int no = i == 0 ? kInt(s.widget.kariyer, 'formaNo', 99) : i + 1;
        final bool vurgu = s.interaktif && s.hedefTip == 'pas' && s.hedefIndex == i;
        final bool topOnda = !s.topUcuyor && s.topTakim == 0 && s.topOyuncu == i;
        oyuncuCiz(canvas, size, s.benimPos[i], i == 0 ? kAltin : Color(s.benimTakim.renk1), Color(s.benimTakim.renk2), no, s.benimIsimler[i], i == 0, vurgu, i, kaleci: i == 10, topOnda: topOnda, takim: 0);
      }
    }

    // --- Top izi (trail): son 8 konum, incelen krem; guc %80+ ise #FF9F1C ---
    final Color izRenk = s.sonGuc >= 0.8 ? const Color(0xFFFF9F1C) : const Color(0xFFFFF8E1);
    for (int i = 0; i < s.topIz.length; i++) {
      final double t = (i + 1) / s.topIz.length; // eski -> yeni
      final Offset g = proje(s.topIz[i], size);
      canvas.drawCircle(g, 1.5 + 4.5 * t, Paint()..color = izRenk.withOpacity(0.12 + 0.5 * t));
    }

    // --- Top: beyaz + 3 siyah dikis yayi (spin ile doner); golge z*40 ote, top z*60 yukari ---
    final Offset zemin = proje(s.top, size);
    final double z = s.topYukseklik;
    canvas.drawOval(
      Rect.fromCenter(center: zemin + Offset(z * 40 * 0.25, 2 + z * 8), width: 14 - z * 5, height: 5 - z * 2),
      Paint()..color = Colors.black.withOpacity((0.38 - z * 0.18).clamp(0.05, 0.38)),
    );
    final Offset tpc = zemin - Offset(0, z * 60);
    final double tr = 6.5 + z * 4.0;
    if (Resimler.top != null) {
      // Gercek top: ucus sirasinda hafif dondur (spin = mesafe birikimli)
      canvas.save();
      canvas.translate(tpc.dx, tpc.dy);
      canvas.rotate(s.topSpin);
      final ui.Image topImg = Resimler.top!;
      final double tb = tr * 2.15;
      canvas.drawImageRect(
        topImg,
        Rect.fromLTWH(0, 0, topImg.width.toDouble(), topImg.height.toDouble()),
        Rect.fromCenter(center: Offset.zero, width: tb, height: tb),
        Paint()..filterQuality = FilterQuality.low,
      );
      canvas.restore();
    } else {
      canvas.drawCircle(tpc, tr, Paint()..color = Colors.white);
      canvas.drawCircle(
          tpc,
          tr,
          Paint()
            ..color = Colors.black54
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
      // 3 dikis yayi spin ile doner
      final Paint dikis = Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;
      for (int k = 0; k < 3; k++) {
        final double aci = s.topSpin + k * 2 * pi / 3;
        canvas.drawArc(Rect.fromCircle(center: tpc, radius: tr * 0.55), aci, 1.2, false, dikis);
      }
    }

    // --- Gol ani: top agda (esneyen agin icinde) ---
    for (final bool ustKale in <bool>[true, false]) {
      final double ag = ustKale ? s.agUst : s.agAlt;
      if (ag > 0) {
        final Offset merkez = proje(Offset(0.5, ustKale ? 0.0 : 1.0), size);
        final Offset titresim = Offset(sin(ag * 40) * 3 * ag, cos(ag * 33) * 2 * ag);
        final Offset gm = merkez + Offset(0, ustKale ? -8 : 8) + titresim;
        if (Resimler.top != null) {
          final ui.Image topImg = Resimler.top!;
          canvas.drawImageRect(
            topImg,
            Rect.fromLTWH(0, 0, topImg.width.toDouble(), topImg.height.toDouble()),
            Rect.fromCircle(center: gm, radius: 7.5),
            Paint()..filterQuality = FilterQuality.low,
          );
        } else {
          canvas.drawCircle(gm, 7, Paint()..color = Colors.white);
          canvas.drawCircle(
              gm,
              7,
              Paint()
                ..color = Colors.black54
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.4);
        }
      }
    }

    // --- Donen konfeti (24 adet, ~1.8 sn) ---
    for (final Konfeti k in s.konfeti) {
      canvas.save();
      canvas.translate(k.p.dx, k.p.dy);
      canvas.rotate(k.omur * 6 + k.p.dx * 0.05);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: k.boyut, height: k.boyut * 0.6),
        Paint()..color = k.c.withOpacity((k.omur / 1.2).clamp(0.0, 1.0)),
      );
      canvas.restore();
    }
    // --- Toz parcaciklari (kaleci dusus) ---
    for (final Toz t in s.toz) {
      canvas.drawCircle(t.p, 3.5 * t.omur + 1, Paint()..color = const Color(0xFFB0A88F).withOpacity((t.omur * 1.6).clamp(0.0, 0.7)));
    }
  }

  // Kale agi: 6x4 grid; golde top yonunde 8-14 px esner, elastik sonumle geri gelir
  void kaleAgi(Canvas canvas, Size size, bool ustKale) {
    final double sy = ustKale ? 0.0 : 1.0;
    final double yon = ustKale ? -1.0 : 1.0;
    final Offset solDirek = proje(Offset(0.38, sy), size);
    final Offset sagDirek = proje(Offset(0.62, sy), size);
    final double ag = ustKale ? s.agUst : s.agAlt;
    // Elastik sonum: genlik azalarak salinir (8-14 px), topun x yonune dogru
    double esX = 0;
    double esY = 0;
    if (ag > 0) {
      final double k = 1 - ag; // 0 -> 1 (gol anindan itibaren)
      final double genlik = (10 + 4 * sin(s.top.dx * 20)) * ag; // sonumlu
      esX = sin(k * 12) * genlik * (s.top.dx < 0.5 ? -1 : 1);
      esY = sin(k * 12) * genlik * yon;
    }
    const double derinlik = 14;
    final Offset arkaSol = solDirek + Offset((sagDirek.dx - solDirek.dx) * 0.14 + esX, yon * derinlik + esY);
    final Offset arkaSag = sagDirek + Offset((solDirek.dx - sagDirek.dx) * 0.14 + esX, yon * derinlik + esY);
    final Path kutu = Path()
      ..moveTo(solDirek.dx, solDirek.dy)
      ..lineTo(sagDirek.dx, sagDirek.dy)
      ..lineTo(arkaSag.dx, arkaSag.dy)
      ..lineTo(arkaSol.dx, arkaSol.dy)
      ..close();
    canvas.drawPath(kutu, Paint()..color = Colors.white.withOpacity(0.13 + (ag > 0 ? ag * 0.15 : 0)));
    final Paint ip = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = 1;
    // 6 dikey ip
    for (int i = 1; i < 6; i++) {
      final double tt = i / 6;
      final Offset a = Offset(solDirek.dx + (sagDirek.dx - solDirek.dx) * tt, solDirek.dy);
      final Offset b = Offset(arkaSol.dx + (arkaSag.dx - arkaSol.dx) * tt, arkaSol.dy);
      canvas.drawLine(a, b, ip);
    }
    // 4 yatay ip
    for (int i = 1; i < 4; i++) {
      final double tt = i / 4;
      final Offset a = Offset(solDirek.dx + (arkaSol.dx - solDirek.dx) * tt, solDirek.dy + (arkaSol.dy - solDirek.dy) * tt);
      final Offset b = Offset(sagDirek.dx + (arkaSag.dx - sagDirek.dx) * tt, sagDirek.dy + (arkaSag.dy - sagDirek.dy) * tt);
      canvas.drawLine(a, b, ip);
    }
    // arka ust kenar
    canvas.drawLine(
        arkaSol,
        arkaSag,
        Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..strokeWidth = 2);
  }

  // Tam vucut mini adam: kafa (ten #F1C27D + sac), forma govde RRect, 2 kol, 2 bacak,
  // siyah konturlu forma no. Kosma: bacak uclari sin faz farkli, kollar ters faz,
  // govde 6° one egik; gercek harekete bagli (durunca durur).
  void oyuncuCiz(Canvas canvas, Size size, Offset p, Color govde, Color detay, int no, String isim, bool ben, bool vurgu, int idx,
      {bool kaleci = false, bool topOnda = false, int takim = 0}) {
    final String anahtar = '$takim-$idx';
    final Offset g0 = proje(p, size);
    final double d = p.dy.clamp(0.0, 1.0);
    final double ol = derinlikOlcek(d) * (topOnda ? 1.08 : 1.0);
    final double boyH = size.height * 0.11 * ol; // yakin oyuncu ~%11 ekran yuksekligi

    // Hareket hizi -> kosma fazi (instance alani; durunca bacaklar durur)
    final Offset once = _sonPos[anahtar] ?? g0;
    final double hareket = (g0 - once).distance;
    _sonPos[anahtar] = g0;
    final double kosK = (hareket / 1.1).clamp(0.0, 1.0);
    final double faz = (_kosFaz[anahtar] ?? idx * 1.7) + kosK * 0.9;
    _kosFaz[anahtar] = faz;

    final Color forma = kaleci ? (takim == 0 ? const Color(0xFF8BC34A) : const Color(0xFFFF9800)) : govde;
    const Color ten = Color(0xFFF1C27D);
    const Color sac = Color(0xFF3E2723);

    // Kaleci dalisi: figur yataylasir (±1.2 rad), parabolik ucar
    double dalisK = 0;
    if (kaleci && s.dalisTakim == takim && s.dalisT > 0) {
      final double gecen = 0.8 - s.dalisT;
      if (gecen < 0.2) {
        dalisK = Curves.easeOut.transform(gecen / 0.2);
      } else if (gecen < 0.5) {
        dalisK = 1;
      } else {
        dalisK = 1 - (gecen - 0.5) / 0.3;
      }
    }

    // Sevinc: 1.2 sn kollar V + ziplama
    double sevK = 0;
    if (anahtar == s.sevincAnahtar && s.sevincT > 0) {
      sevK = 1 - s.sevincT / 1.2; // 0 -> 1
    }
    // Sut savurma: 300 ms bacak geri-ileri
    double sutK = -1;
    if (anahtar == s.sutAnahtar && s.sutT > 0) {
      sutK = (0.3 - s.sutT) / 0.3; // 0 -> 1
    }

    final double zipla = sevK > 0 ? -sin(sevK * pi) * boyH * 0.30 : 0;
    Offset g = g0 + Offset(0, zipla);
    if (dalisK > 0) {
      g += Offset(s.dalisYon * dalisK * boyH * 0.55, -sin(dalisK * pi) * boyH * 0.35);
    }

    // Vurgu halkasi (pas hedefi)
    if (vurgu) {
      canvas.drawCircle(g - Offset(0, boyH * 0.5), boyH * 0.42, Paint()..color = Colors.yellow.withOpacity(0.35));
      canvas.drawCircle(
          g - Offset(0, boyH * 0.5),
          boyH * 0.42,
          Paint()
            ..color = Colors.yellow
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    }
    // FORMDAYIM glow (kullanicinin oyuncusu, combo >= 3)
    if (ben && s.combo >= 3) {
      canvas.drawCircle(g - Offset(0, boyH * 0.5), boyH * 0.55, Paint()..color = const Color(0xFFFF7043).withOpacity(0.22));
    }
    if (ben || topOnda) {
      canvas.drawCircle(g - Offset(0, boyH * 0.5), boyH * 0.46, Paint()..color = (ben ? kAltin : Colors.white).withOpacity(0.16));
    }
    // Kullanici oyuncu: ayak altinda altin halka
    if (ben) {
      canvas.drawOval(
        Rect.fromCenter(center: g0 + const Offset(0, 2), width: boyH * 0.62, height: boyH * 0.18),
        Paint()
          ..color = kAltin.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Sut after-image: 3 hayalet siluet (alfa 0.25 / 0.15 / 0.08)
    if (sutK >= 0) {
      const List<double> alfalar = <double>[0.25, 0.15, 0.08];
      for (int k = 0; k < 3; k++) {
        final Offset gp = g + Offset(0, 0) + Offset(-(k + 1) * boyH * 0.10, (k + 1) * 1.5);
        final Paint hay = Paint()..color = forma.withOpacity(alfalar[k]);
        canvas.drawCircle(gp - Offset(0, boyH * 0.52), boyH * 0.16, hay);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: gp - Offset(0, boyH * 0.32), width: boyH * 0.30, height: boyH * 0.30), Radius.circular(boyH * 0.05)),
          hay,
        );
      }
    }

    canvas.save();
    canvas.translate(g.dx, g.dy);
    if (dalisK > 0) {
      canvas.rotate(s.dalisYon * dalisK * 1.2); // yatay dalis
    } else if (sevK == 0) {
      // Kosmada govde 6° one egik (hucum yonu: biz yukari, rakip asagi)
      final double yon = takim == 0 ? -1.0 : 1.0;
      canvas.rotate(0.105 * kosK * yon);
    }

    // --- Gercek sprite (varsa): takim1=kirmizi, takim2=mavi, kaleci=kaleci.png.
    // Sprite'lar SOLA kosar; saga hareket ediyorsa yatay flip. Kosarken 1/2 pozlari
    // ~150 ms'de degisir + hafif dikey ziplama; durunca poz1 sabit. ---
    final bool kosuyor = kosK > 0.08;
    final ui.Image? spr = kaleci
        ? Resimler.kaleci
        : (kosuyor && (s.animT / 0.15).floor().isOdd
            ? (takim == 0 ? Resimler.kirmizi2 : Resimler.mavi2)
            : (takim == 0 ? Resimler.kirmizi1 : Resimler.mavi1));
    if (spr != null) {
      final double hareketDx = g0.dx - once.dx;
      if (hareketDx > 0.15) {
        _yon[anahtar] = -1; // saga kosuyor -> flip
      } else if (hareketDx < -0.15) {
        _yon[anahtar] = 1;
      }
      if ((_yon[anahtar] ?? 1) < 0) canvas.scale(-1, 1);
      final double sh2 = boyH * 1.06;
      final double sw2 = sh2 * spr.width / spr.height;
      final double zipY = kosuyor ? 2.5 * (0.5 + 0.5 * sin(faz * 2)) : 0.0;
      canvas.drawImageRect(
        spr,
        Rect.fromLTWH(0, 0, spr.width.toDouble(), spr.height.toDouble()),
        Rect.fromLTWH(-sw2 / 2, -sh2 - zipY, sw2, sh2),
        Paint()..filterQuality = FilterQuality.low,
      );
      canvas.restore();
      // Isim etiketi (kullanici / top sahibi / pas hedefi)
      if (ben || topOnda || vurgu) {
        yazi(canvas, isim, g + Offset(0, boyH * 0.14), 8, Colors.white);
      }
      return;
    }

    final double bacak = boyH * 0.40;
    final double govdeH = boyH * 0.32;
    final double govdeW = boyH * 0.30;
    final double kafaR = boyH * 0.13;

    final Paint uzuv = Paint()
      ..strokeWidth = boyH * 0.055
      ..strokeCap = StrokeCap.round;

    // --- 2 bacak: kosarken sin(10t) faz farkli uclar, durunca sabit ---
    final double sal = sin(faz) * boyH * 0.16 * kosK;
    final double kalcaY = -bacak;
    Offset ayak1 = Offset(-govdeW * 0.22 + sal, 0);
    Offset ayak2 = Offset(govdeW * 0.22 - sal, 0);
    if (sutK >= 0) {
      // Sut: sag bacak once geri, sonra ileri savrulur
      final double sw = sin(sutK * pi) * boyH * 0.30;
      ayak2 = Offset(govdeW * 0.22 + sw, -sw * 0.35);
    }
    if (sevK > 0) {
      ayak1 = Offset(-govdeW * 0.30, 0);
      ayak2 = Offset(govdeW * 0.30, 0);
    }
    uzuv.color = Colors.black87; // corap/bacak
    canvas.drawLine(Offset(-govdeW * 0.18, kalcaY), ayak1, uzuv);
    canvas.drawLine(Offset(govdeW * 0.18, kalcaY), ayak2, uzuv);

    // --- Govde: forma RRect ---
    final Rect govdeRect = Rect.fromCenter(center: Offset(0, kalcaY - govdeH / 2 + 2), width: govdeW, height: govdeH);
    canvas.drawRRect(RRect.fromRectAndRadius(govdeRect, Radius.circular(govdeW * 0.22)), Paint()..color = forma);
    canvas.drawRRect(
      RRect.fromRectAndRadius(govdeRect, Radius.circular(govdeW * 0.22)),
      Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    // Forma detay seridi (ikinci renk)
    canvas.drawRect(
      Rect.fromLTWH(govdeRect.left, govdeRect.center.dy - 1.5, govdeRect.width, 3),
      Paint()..color = detay.withOpacity(0.9),
    );

    // --- 2 kol: kosarken bacaklarla TERS faz; sevincte V seklinde yukari ---
    final double omuzY = kalcaY - govdeH * 0.78;
    final double kolBoy = govdeH * 0.85;
    uzuv.color = forma;
    if (sevK > 0) {
      // V: iki kol yukari acilir
      canvas.drawLine(Offset(-govdeW * 0.5, omuzY), Offset(-govdeW * 0.5 - kolBoy * 0.45, omuzY - kolBoy * 0.85), uzuv);
      canvas.drawLine(Offset(govdeW * 0.5, omuzY), Offset(govdeW * 0.5 + kolBoy * 0.45, omuzY - kolBoy * 0.85), uzuv);
      canvas.drawCircle(Offset(-govdeW * 0.5 - kolBoy * 0.45, omuzY - kolBoy * 0.85), boyH * 0.035, Paint()..color = ten);
      canvas.drawCircle(Offset(govdeW * 0.5 + kolBoy * 0.45, omuzY - kolBoy * 0.85), boyH * 0.035, Paint()..color = ten);
    } else {
      final double kolSal = sin(faz) * boyH * 0.13 * kosK; // bacaklarla ters faz (isaret ters)
      canvas.drawLine(Offset(-govdeW * 0.5, omuzY), Offset(-govdeW * 0.5 - kolSal, omuzY + kolBoy), uzuv);
      canvas.drawLine(Offset(govdeW * 0.5, omuzY), Offset(govdeW * 0.5 + kolSal, omuzY + kolBoy), uzuv);
      canvas.drawCircle(Offset(-govdeW * 0.5 - kolSal, omuzY + kolBoy), boyH * 0.035, Paint()..color = ten);
      canvas.drawCircle(Offset(govdeW * 0.5 + kolSal, omuzY + kolBoy), boyH * 0.035, Paint()..color = ten);
    }

    // --- Kafa: ten + sac ---
    final Offset kafa = Offset(0, omuzY - kafaR * 0.9);
    canvas.drawCircle(kafa, kafaR, Paint()..color = ten);
    canvas.drawArc(Rect.fromCircle(center: kafa, radius: kafaR), pi, pi, true, Paint()..color = sac);

    // --- Forma numarasi: siyah konturlu, govdenin ortasinda ---
    final TextPainter noKontur = tp('$no', boyH * 0.16, Colors.black, kalin: true, kontur: true);
    noKontur.paint(canvas, Offset(0, kalcaY - govdeH / 2 + 2) - Offset(noKontur.width / 2, noKontur.height / 2));
    final TextPainter noDolgu = tp('$no', boyH * 0.16, Colors.white, kalin: true);
    noDolgu.paint(canvas, Offset(0, kalcaY - govdeH / 2 + 2) - Offset(noDolgu.width / 2, noDolgu.height / 2));

    canvas.restore();

    // Isim etiketi (sadece onemli oyuncularda: performans)
    if (ben || topOnda || vurgu) {
      yazi(canvas, isim, g + Offset(0, boyH * 0.14), 8, Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant SahaPainter oldDelegate) => true;
}
