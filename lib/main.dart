import 'dart:async';
import 'dart:convert';
import 'dart:math';

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
          kariyer = k;
        }
      }
    } catch (_) {
      kariyer = null;
    }
    try {
      final String? s = prefs!.getString('settings');
      if (s != null) {
        ayarlar = Map<String, dynamic>.from(jsonDecode(s) as Map<dynamic, dynamic>);
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
  final int benimIndex = lig.indexWhere((TakimBilgi t) => t.ad == takim);
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
    t += (e as num).toDouble();
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
    kontrol = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    kontrol.addStatusListener((AnimationStatus s) {
      if (s == AnimationStatus.completed) bitis();
    });
    kontrol.forward();
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
    const String logo = 'CEA GAMES';
    return GestureDetector(
      onTap: bitis, // dokununca atla
      child: Container(
        color: Colors.black,
        child: AnimatedBuilder(
          animation: kontrol,
          builder: (BuildContext context, Widget? child) {
            final double t = kontrol.value;
            final int harfSayi = (t * 1.6 * logo.length).clamp(0, logo.length).floor();
            final String gorunen = logo.substring(0, harfSayi);
            final double sunarOp = ((t - 0.75) / 0.25).clamp(0.0, 1.0);
            return Stack(
              children: <Widget>[
                Positioned.fill(child: CustomPaint(painter: SplashPainter(t))),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const SizedBox(height: 120),
                      Text(
                        gorunen,
                        style: const TextStyle(
                          color: kAltin,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                          shadows: <Shadow>[
                            Shadow(blurRadius: 18, color: kAltin),
                            Shadow(blurRadius: 4, color: Colors.black),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 60,
                  child: Opacity(
                    opacity: sunarOp,
                    child: const Text(
                      'sunar',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 16, letterSpacing: 3),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Siyah zeminde 2 spot ışık hüzmesi + dönerek büyüyen futbol topu
class SplashPainter extends CustomPainter {
  final double t;
  SplashPainter(this.t);

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

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    // Spot ışıklar: üstten inen yarı şeffaf altın üçgenler
    final double isik = (t / 0.35).clamp(0.0, 1.0);
    for (final double cx in <double>[w * 0.28, w * 0.72]) {
      final Path huzme = Path()
        ..moveTo(cx - 14, 0)
        ..lineTo(cx + 14, 0)
        ..lineTo(cx + w * 0.22, h * 0.75 * isik)
        ..lineTo(cx - w * 0.22, h * 0.75 * isik)
        ..close();
      canvas.drawPath(huzme, Paint()..color = kAltin.withOpacity(0.13 * isik));
      canvas.drawPath(huzme, Paint()..color = const Color(0xFFFFF8E1).withOpacity(0.07 * isik));
      // zemin ışık dairesi
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, h * 0.75 * isik), width: w * 0.42, height: 26 * isik),
        Paint()..color = kAltin.withOpacity(0.10 * isik),
      );
    }
    // Dönerek büyüyen futbol topu
    final double bt = ((t - 0.15) / 0.55).clamp(0.0, 1.0);
    if (bt > 0) {
      final double olcek = Curves.elasticOut.transform(bt);
      final Offset merkez = Offset(w / 2, h * 0.38);
      final double r = 62 * olcek;
      canvas.drawCircle(merkez, r, Paint()..color = Colors.white);
      canvas.drawCircle(merkez, r, Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
      final double rot = bt * 5.2;
      final Paint siyah = Paint()..color = Colors.black87;
      besgen(canvas, merkez, r * 0.32, rot, siyah);
      for (int i = 0; i < 5; i++) {
        final double a = rot - pi / 2 + i * 2 * pi / 5;
        final Offset d = merkez + Offset(cos(a) * r * 0.82, sin(a) * r * 0.82);
        besgen(canvas, d, r * 0.22, rot + pi / 5, siyah);
        canvas.drawLine(merkez + Offset(cos(a) * r * 0.32, sin(a) * r * 0.32), d, Paint()
          ..color = Colors.black54
          ..strokeWidth = 1.5);
      }
    }
  }

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
        setState(() => zipliyor = true);
        await Future<void>.delayed(const Duration(milliseconds: 600));
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
    final int idx = ((fik[hafta - 1] as num).toInt()).clamp(0, lig.length - 1);
    if (lig[idx].ad == benimTakim.ad && lig.length > 1) return lig[(idx + 1) % lig.length];
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
                final Map<String, dynamic> m = Map<String, dynamic>.from(b[i] as Map<dynamic, dynamic>);
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
                                    b.removeAt(i);
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
        onAdLoaded: (RewardedAd ad) => odulluReklam = ad,
        onAdFailedToLoad: (LoadAdError e) => odulluReklam = null,
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
    final double hedefTur = 5 * 2 * pi + (kazanan / kKramponMagaza.length) * 2 * pi;
    final double baslangic = carkAcisi % (2 * pi);
    carkKontrol.reset();
    final Animation<double> anim = Tween<double>(begin: baslangic, end: baslangic + hedefTur).animate(CurvedAnimation(parent: carkKontrol, curve: Curves.decelerate));
    anim.addListener(() {
      carkAcisi = anim.value;
    });
    carkKontrol.forward().then((_) {
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
        odulluReklam = null;
        reklamiYukle();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd a, AdError e) {
        a.dispose();
        odulluReklam = null;
        reklamiYukle();
      },
    );
    ad.show(onUserEarnedReward: (AdWithoutView a, RewardItem r) {
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
    final List<int> rakipNolar = <int>{...<int>[for (int i = 0; i < 11; i++) 1 + rr.nextInt(40)]}.take(11).toList();
    while (rakipNolar.length < 11) {
      rakipNolar.add(1 + rr.nextInt(50));
    }
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

class _MacEkraniState extends State<MacEkrani> {
  final Random r = Random();
  Timer? timer;
  Timer? overlayTimer;
  Timer? secimTimer;
  double dakika = 0;
  int hiz = 1;
  int skorBiz = 0;
  int skorRakip = 0;
  int gol = 0;
  int asist = 0;
  int pas = 0;
  int sut = 0;
  final List<String> spiker = <String>[];
  String fase = 'oyun'; // oyun, devre, sonuc, panel, roportaj
  String overlay = '';
  Color overlayRenk = kAltin;
  bool devreYapildi = false;
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

  // --- Gol efektleri ---
  double sarsinti = 0; // 1 -> 0 azalan ekran sarsintisi
  final List<Konfeti> konfeti = <Konfeti>[];
  final List<Offset> topIz = <Offset>[]; // top ucus izi (trail)
  double animT = 0; // kosma sallanma animasyonu icin zaman
  double agUst = 0; // ust kale aginda titresim suresi
  double agAlt = 0; // alt kale aginda titresim suresi
  String mesafeYazi = ''; // vurus mesafesi kutusu
  double overlayBoyut = 44;

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
    timer = Timer.periodic(const Duration(milliseconds: 40), (Timer t) => tik());
  }

  @override
  void dispose() {
    timer?.cancel();
    overlayTimer?.cancel();
    secimTimer?.cancel();
    super.dispose();
  }

  void spikerEkle(String s) {
    spiker.add(s);
    while (spiker.length > 5) {
      spiker.removeAt(0);
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
    if (fase != 'oyun' || interaktif) return;
    setState(() {
      final double dt = 0.04 * hiz; // saniye (hiz carpani ile)
      animT += dt;
      if (agUst > 0) agUst = (agUst - dt).clamp(0.0, 1.0);
      if (agAlt > 0) agAlt = (agAlt - dt).clamp(0.0, 1.0);
      dakika += dt / 1.2; // 1x hizinda ~1.2 sn = 1 oyun dakikasi
      if (!topUcuyor && dakika >= sonrakiPozisyonDk) pozisyonDusur();
      simule(dt);
      konfetiGuncelle(dt);
      if (sarsinti > 0) sarsinti = (sarsinti - dt * 1.1).clamp(0.0, 1.0);
      // Rastgele spiker yorumu
      if (!topUcuyor && r.nextDouble() < 0.006 * dt * 25) {
        final List<String> yorumlar = <String>[
          'Orta sahada büyük mücadele var!',
          'Taraftarlar coşkuyla takımını destekliyor! 🎺',
          '${benimIsimler[0]} boş koşu yapıyor, topu istiyor!',
          'Tempo giderek artıyor! ⚡',
          '${rakipIsimler[r.nextInt(rakipIsimler.length)]} pres yapıyor.',
        ];
        spikerEkle(yorumlar[r.nextInt(yorumlar.length)]);
      }
      if (dakika >= 45 && !devreYapildi && !topUcuyor) {
        devreYapildi = true;
        fase = 'devre';
        spikerEkle('İlk yarı sona erdi! Devre arası. ⏸');
      }
      if (dakika >= 90 && !topUcuyor) {
        dakika = 90;
        macBitti();
      }
    });
  }

  // Pozisyon eventleri: %40 kullaniciya interaktif, %60 yapay zeka (animasyonlu)
  void pozisyonDusur() {
    sonrakiPozisyonDk = dakika + 6 + r.nextDouble() * 8;
    final double z = r.nextDouble();
    if (z < 0.40) {
      interaktifBaslat();
    } else if (z < 0.70) {
      rakipAtak();
    } else {
      arkadasAtak();
    }
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
      // Beyaz-krem iz (trail): son 12 konum
      topIz.add(top);
      if (topIz.length > 12) topIz.removeAt(0);
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
    for (int i = 0; i < 70; i++) {
      final double aci = r.nextDouble() * 2 * pi;
      final double h = 60 + r.nextDouble() * 220;
      konfeti.add(Konfeti(
        ekran,
        Offset(cos(aci) * h, sin(aci) * h - 160),
        kKonfetiRenkler[r.nextInt(kKonfetiRenkler.length)],
        1.2 + r.nextDouble() * 0.9,
        3 + r.nextDouble() * 5,
      ));
    }
  }

  void konfetiGuncelle(double dt) {
    for (final Konfeti k in konfeti) {
      k.p += k.v * dt;
      k.v += const Offset(0, 320) * dt;
      k.omur -= dt;
    }
    konfeti.removeWhere((Konfeti k) => k.omur <= 0);
  }

  void golEfekt(bool ustKale, String yazi, Color renk) {
    sarsinti = 1;
    // Top kale ağına çarpar ve 0.4 sn titrer
    if (ustKale) {
      agUst = 0.4;
    } else {
      agAlt = 0.4;
    }
    final Offset k = SahaPainter.proje(Offset(0.5, ustKale ? 0.0 : 1.0), sahaSize);
    konfetiSac(k);
    goster(yazi, renk, boyut: yazi.contains('GOOOL') ? 62 : 44);
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
        golEfekt(false, 'RAKİP GOL 😟', Colors.red.shade300);
      } else if ((hedef.dy - 0.985).abs() < 0.01) {
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
      spikerEkle('$ark harika bir gol attı! ${benimTakim.ad} sevinç içinde! ⚽');
      golEfekt(true, 'GOOOL! ⚽', kAltin);
    });
  }

  void goster(String yazi, Color renk, {double boyut = 44}) {
    overlayTimer?.cancel();
    setState(() {
      overlay = yazi;
      overlayRenk = renk;
      overlayBoyut = boyut;
    });
    overlayTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => overlay = '');
    });
  }

  // ---- Interaktif pozisyon ----

  void interaktifBaslat() {
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
    benimPos[0] = const Offset(0.5, 0.20);
    top = const Offset(0.5, 0.215);
    for (int i = 1; i <= 3; i++) {
      benimPos[i] = Offset(0.14 + 0.24 * (i - 1), 0.30 + 0.04 * (i % 2));
    }
    for (int i = 0; i < 4; i++) {
      rakipPos[i] = Offset(0.28 + 0.15 * i, 0.12 + 0.05 * (i % 2));
    }
    rakipPos[10] = const Offset(0.5, 0.045); // kaleci
    spikerEkle('${benimIsimler[0]} büyük bir pozisyon yakaladı! Oku sürükle, hedefi seç ve gücü ayarla! 🎯');
    secimTimer?.cancel();
    secimTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && interaktif) vurusYap(otomatik: true);
    });
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
    final String ad = benimIsimler[0];
    final double kx = kose == 'sol' ? 0.42 : 0.58;
    final String sonuc;
    final Offset hedef;
    double kavis = 0.55;
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
      if (g >= 0.45 && g <= 0.75) p += 0.08; // ideal sari bolge
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
        break;
      case 'sert':
        spikerEkle('$ad çok sert vurdu! Top üstten auta çıktı! 🚀');
        break;
      case 'gol':
        gol++;
        skorBiz++;
        spikerEkle('$ad $kose köşeye vurdu ve GOL! ${benimTakim.ad} ${skorBiz > skorRakip ? 'öne geçiyor' : 'skoru değiştiriyor'}! ⚽🎉');
        golEfekt(true, 'GOOOL! ⚽', kAltin);
        break;
      case 'kurtaris':
        spikerEkle('$ad $kose köşeye vurdu ama kaleci harika kurtardı! 🧤');
        break;
      case 'direk':
        spikerEkle('$ad vurdu, top direkten döndü! 😱');
        break;
      default:
        spikerEkle('$ad vurdu ama top az farkla auta gitti!');
    }
  }

  void pasSonuc(double g, int hi) {
    final String ark = benimIsimler[hi];
    final int pasOz = ozellik(widget.kariyer, 'pas');
    final String ad = benimIsimler[0];
    if (g < 0.25) {
      topaUcus(benimPos[hi] + (top - benimPos[hi]) * 0.5, sure: 0.5, kavis: 0.2, sonu: () {
        spikerEkle('$ad pası kısa düştü, top kaybı! 🐌');
      });
      return;
    }
    if (g > 0.92) {
      topaUcus(Offset((benimPos[hi].dx + 0.3).clamp(0.0, 1.0), (benimPos[hi].dy + 0.25).clamp(0.0, 1.0)), sure: 0.6, kavis: 0.35, sonu: () {
        spikerEkle('$ad pası çok sert gönderdi, top taca çıktı!');
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
        return;
      }
      pas++;
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
        spikerEkle('$ark, $ad pasında topu ağlara gönderdi! ASİST! 🎯🎉');
        golEfekt(true, '👟 ASİST! 🎯', kTuruncu);
      });
    });
  }

  void macBitti() {
    fase = 'sonuc';
    final bool galibiyet = skorBiz > skorRakip;
    final bool berabere = skorBiz == skorRakip;
    spikerEkle('Maç sona erdi! Skor: $skorBiz v $skorRakip 📣');
    goster(galibiyet ? 'KAZANDIN! 🎉' : (berabere ? 'BERABERLİK 🤝' : 'KAYBETTİN 😞'), galibiyet ? kYesil : (berabere ? Colors.orange : Colors.red));
    Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() {
        overlay = '';
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Modern skor tabelasi
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFF12263A), Color(0xFF0D1B2A)],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      rozet(benimTakim.ad, 30),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(benimTakim.ad, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10), border: Border.all(color: kAltin, width: 1.5)),
                        child: Text('$skorBiz - $skorRakip',
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                      ),
                      Expanded(
                        child: Text(widget.rakip.ad, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                      rozet(widget.rakip.ad, 30),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(color: kYesil, borderRadius: BorderRadius.circular(8)),
                        child: Text("${dakika.floor()}'", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      if (dakika >= 45) const Padding(padding: EdgeInsets.only(left: 6), child: Text('2. YARI', style: TextStyle(color: kAltin, fontSize: 11, fontWeight: FontWeight.bold))),
                      const Spacer(),
                      for (final int h in <int>[1, 2, 10])
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: GestureDetector(
                            onTap: () => setState(() => hiz = h),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: hiz == h ? kAltin : Colors.white12,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: hiz == h ? kAltin : Colors.white30),
                              ),
                              child: Text('${h}x',
                                  style: TextStyle(color: hiz == h ? Colors.black : Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Saha
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints cons) {
                  sahaSize = Size(cons.maxWidth, cons.maxHeight);
                  return Stack(
                    children: <Widget>[
                      Transform.translate(
                        offset: Offset(sin(sarsinti * 40) * 6 * sarsinti, cos(sarsinti * 33) * 5 * sarsinti),
                        child: AnimatedScale(
                          scale: interaktif ? 1.9 : 1.0,
                          alignment: const Alignment(0, -0.55),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          child: SizedBox(
                            width: cons.maxWidth,
                            height: cons.maxHeight,
                            child: GestureDetector(
                              onPanStart: panBaslat,
                              onPanUpdate: panGuncelle,
                              onPanEnd: panBitir,
                              child: CustomPaint(
                                size: sahaSize,
                                painter: SahaPainter(
                                  benimPos: benimPos,
                                  rakipPos: rakipPos,
                                  top: top,
                                  topYukseklik: topYukseklik,
                                  benimRenk: Color(benimTakim.renk1),
                                  benimRenk2: Color(benimTakim.renk2),
                                  rakipRenk: rakipRenk,
                                  rakipRenk2: Color(widget.rakip.renk2),
                                  benimIsimler: benimIsimler,
                                  rakipIsimler: rakipIsimler,
                                  formaNo: kInt(widget.kariyer, 'formaNo', 99),
                                  nisan: nisan,
                                  hedefTip: hedefTip,
                                  hedefIndex: hedefIndex,
                                  hedefKose: hedefKose,
                                  interaktif: interaktif,
                                  konfeti: konfeti,
                                  topIz: topIz,
                                  animT: animT,
                                  agUst: agUst,
                                  agAlt: agAlt,
                                ),
                              ),
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
                      // Guc gostergesi (en ustte, dikey, asagi dolan)
                      if (interaktif) gucCubugu(),
                      // Vuruş mesafesi kutusu
                      if (mesafeYazi.isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kAltin, width: 1.5),
                            ),
                            child: Text('📏 $mesafeYazi', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      // GOL / skor banneri
                      if (overlay.isNotEmpty)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: overlayRenk, width: 3),
                              boxShadow: <BoxShadow>[BoxShadow(color: overlayRenk.withOpacity(0.6), blurRadius: 24)],
                            ),
                            child: Text(overlay, style: TextStyle(color: overlayRenk, fontSize: overlayBoyut, fontWeight: FontWeight.w900, shadows: const <Shadow>[Shadow(blurRadius: 14, color: Colors.black)])),
                          ),
                        ),
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
            // Alt bar: spiker (max 5 satir, son satir vurgulu)
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
                    Text('🎙 ${spiker[i]}',
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
    return Center(
      child: Container(
        margin: const EdgeInsets.all(30),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('⏸ Devre Arası', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kYesil)),
            const SizedBox(height: 8),
            Text('$skorBiz v $skorRakip', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('İstatistiklerin: $gol gol • $asist asist • $pas pas • $sut şut', style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 14),
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
    return Center(
      child: Container(
        margin: const EdgeInsets.all(26),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
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

// Üstten görünümlü saha + oyuncular + top + konfeti çizimi (NSS tarzı düz üstten)
class SahaPainter extends CustomPainter {
  final List<Offset> benimPos;
  final List<Offset> rakipPos;
  final Offset top;
  final double topYukseklik;
  final Color benimRenk;
  final Color benimRenk2;
  final Color rakipRenk;
  final Color rakipRenk2;
  final List<String> benimIsimler;
  final List<String> rakipIsimler;
  final int formaNo;
  final Offset? nisan;
  final String hedefTip;
  final int hedefIndex;
  final String hedefKose;
  final bool interaktif;
  final List<Konfeti> konfeti;
  final List<Offset> topIz;
  final double animT;
  final double agUst;
  final double agAlt;

  SahaPainter({
    required this.benimPos,
    required this.rakipPos,
    required this.top,
    required this.topYukseklik,
    required this.benimRenk,
    required this.benimRenk2,
    required this.rakipRenk,
    required this.rakipRenk2,
    required this.benimIsimler,
    required this.rakipIsimler,
    required this.formaNo,
    required this.nisan,
    required this.hedefTip,
    required this.hedefIndex,
    required this.hedefKose,
    required this.interaktif,
    required this.konfeti,
    required this.topIz,
    required this.animT,
    required this.agUst,
    required this.agAlt,
  });

  // --- Düz üstten projeksiyon: dikey saha, saldırılan kale üstte ---
  static const double sol = 0.075; // w oranı
  static const double sag = 0.925;
  static const double ust = 0.115; // h oranı (üstte tribün + reklam bandı)
  static const double alt = 0.895; // altta reklam bandı + tribün

  // Saha koordinatını (0..1) ekrana dönüştürür
  static Offset proje(Offset s, Size size) {
    return Offset(
      size.width * (sol + s.dx * (sag - sol)),
      size.height * (ust + s.dy * (alt - ust)),
    );
  }

  // Ekran noktasını saha koordinatına çevirir (nişan için)
  static Offset tersProje(Offset p, Size size) {
    final double x = ((p.dx / size.width - sol) / (sag - sol)).clamp(0.0, 1.0);
    final double y = ((p.dy / size.height - ust) / (alt - ust)).clamp(0.0, 1.0);
    return Offset(x, y);
  }

  void yazi(Canvas canvas, String s, Offset merkez, double boyut, Color renk, {bool kalin = false}) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: renk,
          fontSize: boyut,
          fontWeight: kalin ? FontWeight.bold : FontWeight.normal,
          shadows: const <Shadow>[Shadow(blurRadius: 2, color: Colors.black)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, merkez - Offset(tp.width / 2, tp.height / 2));
  }

  void cizgiCiz(Canvas canvas, Size size, double x1, double y1, double x2, double y2, Paint p) {
    canvas.drawLine(proje(Offset(x1, y1), size), proje(Offset(x2, y2), size), p);
  }

  Rect sahaRect(Size size, double x1, double y1, double x2, double y2) {
    final Offset a = proje(Offset(x1, y1), size);
    final Offset b = proje(Offset(x2, y2), size);
    return Rect.fromLTRB(a.dx, a.dy, b.dx, b.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // --- Zemin: koyu stadyum çerçevesi ---
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF14261A));

    // --- Tribün hissi: üst + alt + yanlarda renkli nokta seyirci bantları ---
    const List<Color> seyirci = <Color>[
      Color(0xFFEF5350), Color(0xFFFFCA28), Color(0xFF42A5F5), Color(0xFFEC407A),
      Color(0xFF66BB6A), Color(0xFFFFA726), Color(0xFFAB47BC), Color(0xFFEEEEEE),
    ];
    void seyirciBandi(double x0, double y0, double x1, double y1, bool yatay) {
      if (yatay) {
        for (double xx = x0 + 4; xx < x1 - 2; xx += 8) {
          for (int row = 0; row < 3; row++) {
            final int ci = (xx.floor() * 7 + row * 13) % seyirci.length;
            canvas.drawCircle(Offset(xx + (row % 2) * 3, y0 + 3 + row * (y1 - y0 - 6) / 2), 2.2, Paint()..color = seyirci[ci]);
          }
        }
      } else {
        for (double yy = y0 + 4; yy < y1 - 2; yy += 8) {
          for (int col = 0; col < 2; col++) {
            final int ci = (yy.floor() * 5 + col * 11) % seyirci.length;
            canvas.drawCircle(Offset(x0 + 3 + col * (x1 - x0 - 6), yy + (col % 2) * 3), 2.0, Paint()..color = seyirci[ci]);
          }
        }
      }
    }

    final double sahaSolX = w * sol;
    final double sahaSagX = w * sag;
    final double sahaUstY = h * ust;
    final double sahaAltY = h * alt;
    // Üst tribün (en üst şerit)
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.045), Paint()..color = const Color(0xFF263238));
    seyirciBandi(0, 0, w, h * 0.045, true);
    // Alt tribün
    canvas.drawRect(Rect.fromLTWH(0, h * 0.955, w, h * 0.045), Paint()..color = const Color(0xFF263238));
    seyirciBandi(0, h * 0.955, w, h, true);
    // Yan tribünler (saha hizasında ince şeritler)
    canvas.drawRect(Rect.fromLTWH(0, sahaUstY, w * 0.035, sahaAltY - sahaUstY), Paint()..color = const Color(0xFF263238));
    canvas.drawRect(Rect.fromLTWH(w * 0.965, sahaUstY, w * 0.035, sahaAltY - sahaUstY), Paint()..color = const Color(0xFF263238));
    seyirciBandi(0, sahaUstY, w * 0.035, sahaAltY, false);
    seyirciBandi(w * 0.965, sahaUstY, w * 0.035, sahaAltY, false);

    // --- Reklam panosu şeritleri (üst ve alt, kendi kurgu markalarımız) ---
    const List<List<dynamic>> markalar = <List<dynamic>>[
      <dynamic>['CEA GAMES', 0xFF1B1B1B, 0xFFFFD54F],
      <dynamic>['YILDIZ SPOR', 0xFF0D47A1, 0xFFFFFFFF],
      <dynamic>['KRAMPO MAX', 0xFFB71C1C, 0xFFFFFFFF],
      <dynamic>['ALTIN LİG', 0xFF4A3800, 0xFFFFD54F],
    ];
    void panoSeridi(double y0, double y1) {
      canvas.drawRect(Rect.fromLTWH(0, y0, w, y1 - y0), Paint()..color = const Color(0xFF101010));
      int mi = 0;
      double xx = 4;
      while (xx < w - 10) {
        final List<dynamic> m = markalar[mi % markalar.length];
        final String ad = m[0] as String;
        final double pw = ad.length * 7.0 + 18;
        final Rect r = Rect.fromLTWH(xx, y0 + 2, pw, y1 - y0 - 4);
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = Color(m[1] as int));
        yazi(canvas, ad, r.center, 9, Color(m[2] as int), kalin: true);
        xx += pw + 10;
        mi++;
      }
    }

    panoSeridi(h * 0.050, h * 0.105); // üst panolar
    panoSeridi(h * 0.905, h * 0.955); // alt panolar

    // --- Cim: iki ton yeşil yatay şeritler + hafif nokta dokusu ---
    const int seritSayi = 10;
    for (int i = 0; i < seritSayi; i++) {
      final Color renk = i.isEven ? const Color(0xFF2E7D32) : const Color(0xFF37913F);
      canvas.drawRect(
        Rect.fromLTRB(sahaSolX, sahaUstY + (sahaAltY - sahaUstY) * i / seritSayi, sahaSagX, sahaUstY + (sahaAltY - sahaUstY) * (i + 1) / seritSayi),
        Paint()..color = renk,
      );
    }
    // Gürültü/nokta çim dokusu (deterministik)
    final Paint nokta = Paint()..color = Colors.white.withOpacity(0.05);
    final Paint nokta2 = Paint()..color = Colors.black.withOpacity(0.06);
    for (int i = 0; i < 260; i++) {
      final double nx = ((i * 137) % 997) / 997;
      final double ny = ((i * 389) % 991) / 991;
      canvas.drawCircle(Offset(sahaSolX + nx * (sahaSagX - sahaSolX), sahaUstY + ny * (sahaAltY - sahaUstY)), 1.1, i.isEven ? nokta : nokta2);
    }
    // Saha kenarlarında koyu çerçeve
    canvas.drawRect(
      Rect.fromLTRB(sahaSolX - 5, sahaUstY - 5, sahaSagX + 5, sahaAltY + 5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = const Color(0xFF0F3D17),
    );

    // --- Beyaz saha çizgileri ---
    final Paint cizgi = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    cizgiCiz(canvas, size, 0, 0, 1, 0, cizgi);
    cizgiCiz(canvas, size, 0, 1, 1, 1, cizgi);
    cizgiCiz(canvas, size, 0, 0, 0, 1, cizgi);
    cizgiCiz(canvas, size, 1, 0, 1, 1, cizgi);
    // Orta çizgi + orta yuvarlak
    cizgiCiz(canvas, size, 0, 0.5, 1, 0.5, cizgi);
    canvas.drawOval(sahaRect(size, 0.35, 0.425, 0.65, 0.575), cizgi);
    canvas.drawCircle(proje(const Offset(0.5, 0.5), size), 2.5, Paint()..color = Colors.white);
    // Ceza sahaları + kale alanları
    canvas.drawRect(sahaRect(size, 0.22, 0, 0.78, 0.15), cizgi);
    canvas.drawRect(sahaRect(size, 0.22, 0.85, 0.78, 1), cizgi);
    canvas.drawRect(sahaRect(size, 0.36, 0, 0.64, 0.055), cizgi);
    canvas.drawRect(sahaRect(size, 0.36, 0.945, 0.64, 1), cizgi);

    // --- Kaleler (ağ dokusu görünür) ---
    kaleCiz(canvas, size, true);
    kaleCiz(canvas, size, false);

    // --- Nişan oku (interaktif modda) ---
    if (interaktif && nisan != null) {
      final Offset a = proje(benimPos[0], size);
      final Offset b = proje(nisan!, size);
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
      if (hedefTip == 'sut') {
        final Offset k = proje(Offset(hedefKose == 'sol' ? 0.42 : 0.58, 0.0), size);
        canvas.drawCircle(k, 14, Paint()..color = Colors.yellow.withOpacity(0.45));
        canvas.drawCircle(k, 14, Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
      }
    }

    // --- Oyuncular (üstten görünüm: uzak olanlar önce çizilir) ---
    final List<int> rakipSirali = List<int>.generate(11, (int i) => i)..sort((int a, int b) => rakipPos[a].dy.compareTo(rakipPos[b].dy));
    final List<int> benimSirali = List<int>.generate(11, (int i) => i)..sort((int a, int b) => benimPos[a].dy.compareTo(benimPos[b].dy));
    for (final int i in rakipSirali) {
      oyuncuCiz(canvas, size, rakipPos[i], rakipRenk, rakipRenk2, i + 1, rakipIsimler[i], false, false, i);
    }
    for (final int i in benimSirali) {
      final int no = i == 0 ? formaNo : i + 1;
      final bool vurgu = interaktif && hedefTip == 'pas' && hedefIndex == i;
      oyuncuCiz(canvas, size, benimPos[i], i == 0 ? kAltin : benimRenk, benimRenk2, no, benimIsimler[i], i == 0, vurgu, i);
    }

    // --- Top izi (beyaz-krem trail, giderek incelen noktalar) ---
    for (int i = 0; i < topIz.length; i++) {
      final double t = (i + 1) / topIz.length; // eski -> yeni
      final Offset g = proje(topIz[i], size);
      canvas.drawCircle(g, 1.5 + 4.5 * t, Paint()..color = const Color(0xFFFFF8E1).withOpacity(0.15 + 0.55 * t));
    }

    // --- Top (gölge yerde, top havada büyür) ---
    final Offset zemin = proje(top, size);
    final double yuk = topYukseklik * 50;
    canvas.drawOval(
      Rect.fromCenter(center: zemin + const Offset(0, 2), width: 14 - topYukseklik * 5, height: 5 - topYukseklik * 2),
      Paint()..color = Colors.black.withOpacity(0.38 - topYukseklik * 0.18),
    );
    final Offset tp = zemin - Offset(0, yuk);
    final double tr = 6.5 + topYukseklik * 4.0;
    canvas.drawCircle(tp, tr, Paint()..color = Colors.white);
    canvas.drawCircle(tp, tr, Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4);
    canvas.drawCircle(tp + Offset(-tr * 0.25, -tr * 0.25), tr * 0.22, Paint()..color = Colors.black87);
    canvas.drawCircle(tp + Offset(tr * 0.3, tr * 0.25), tr * 0.16, Paint()..color = Colors.black87);

    // --- Gol anı: top ağda titrer (0.4 sn) ---
    for (final bool ustKale in <bool>[true, false]) {
      final double ag = ustKale ? agUst : agAlt;
      if (ag > 0) {
        final Offset merkez = proje(Offset(0.5, ustKale ? 0.0 : 1.0), size);
        final Offset titresim = Offset(sin(ag * 55) * 3, cos(ag * 47) * 2);
        final Offset gm = merkez + Offset(0, ustKale ? -8 : 8) + titresim;
        canvas.drawCircle(gm, 7, Paint()..color = Colors.white);
        canvas.drawCircle(gm, 7, Paint()
          ..color = Colors.black54
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
        canvas.drawCircle(gm + const Offset(-1.8, -1.8), 1.6, Paint()..color = Colors.black87);
        // Ağ parlaması
        canvas.drawRect(
          Rect.fromCenter(center: merkez + Offset(0, ustKale ? -9 : 9), width: (sahaSagX - sahaSolX) * 0.24, height: 18),
          Paint()..color = Colors.white.withOpacity(0.12 + ag * 0.3),
        );
      }
    }

    // --- Yıldız konfeti patlaması ---
    for (final Konfeti k in konfeti) {
      canvas.save();
      canvas.translate(k.p.dx, k.p.dy);
      canvas.rotate(k.p.dx * 0.05 + k.omur * 3);
      final Paint kp = Paint()..color = k.c.withOpacity(k.omur.clamp(0.0, 1.0));
      // küçük yıldız
      final Path yildiz = Path();
      for (int i = 0; i < 10; i++) {
        final double rr = i.isEven ? k.boyut : k.boyut * 0.45;
        final double aa = -pi / 2 + i * pi / 5;
        final Offset n = Offset(cos(aa) * rr, sin(aa) * rr);
        if (i == 0) {
          yildiz.moveTo(n.dx, n.dy);
        } else {
          yildiz.lineTo(n.dx, n.dy);
        }
      }
      yildiz.close();
      canvas.drawPath(yildiz, kp);
      canvas.restore();
    }
  }

  // Üstten görünümde kale: beyaz direkler + ağ dokusu (kale sahanın dışına taşar)
  void kaleCiz(Canvas canvas, Size size, bool ustKale) {
    final double sy = ustKale ? 0.0 : 1.0;
    final double yon = ustKale ? -1.0 : 1.0;
    final Offset solDirek = proje(Offset(0.38, sy), size);
    final Offset sagDirek = proje(Offset(0.62, sy), size);
    const double derinlik = 16; // ağ derinliği (px)
    final Paint direk = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    // Ağ kutusu (sahanın dışına taşan dikdörtgen)
    final Rect agKutu = Rect.fromPoints(solDirek + Offset(0, yon * derinlik), sagDirek);
    // Ağ dolgusu
    canvas.drawRect(agKutu, Paint()..color = Colors.white.withOpacity(0.14));
    // Ağ örgüsü: dikey + yatay ipler
    final Paint ag = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = 1;
    for (int i = 1; i < 8; i++) {
      final double t = i / 8;
      final double xx = solDirek.dx + (sagDirek.dx - solDirek.dx) * t;
      canvas.drawLine(Offset(xx, solDirek.dy), Offset(xx, solDirek.dy + yon * derinlik), ag);
    }
    for (int i = 1; i < 3; i++) {
      final double yy = solDirek.dy + yon * derinlik * i / 3;
      canvas.drawLine(Offset(solDirek.dx, yy), Offset(sagDirek.dx, yy), ag);
    }
    // Direkler (gol çizgisinde iki nokta + arka çizgi)
    canvas.drawCircle(solDirek, 3, Paint()..color = Colors.white);
    canvas.drawCircle(sagDirek, 3, Paint()..color = Colors.white);
    canvas.drawLine(solDirek, solDirek + Offset(0, yon * derinlik), direk);
    canvas.drawLine(sagDirek, sagDirek + Offset(0, yon * derinlik), direk);
    canvas.drawLine(solDirek + Offset(0, yon * derinlik), sagDirek + Offset(0, yon * derinlik), Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 2);
  }

  // Üstten mini figür: gölge elipsi + forma gövdesi + kafa + forma no (+ koşma sallanması)
  void oyuncuCiz(Canvas canvas, Size size, Offset p, Color govde, Color detay, int no, String isim, bool ben, bool vurgu, int idx) {
    final Offset g0 = proje(p, size);
    // Koşma hissi: sin dalgasıyla hafif gövde kayması
    final Offset g = g0 + Offset(sin(animT * 9 + idx * 1.7) * 1.6, cos(animT * 7 + idx * 2.3) * 1.2);
    // Gölge elipsi
    canvas.drawOval(Rect.fromCenter(center: g + const Offset(0, 3), width: 20, height: 7), Paint()..color = Colors.black38);
    if (vurgu) {
      canvas.drawCircle(g, 16, Paint()..color = Colors.yellow.withOpacity(0.40));
      canvas.drawCircle(g, 16, Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
    }
    if (ben) {
      canvas.drawCircle(g, 14, Paint()..color = kAltin.withOpacity(0.35));
    }
    // Forma gövdesi (üstten omuz dairesi)
    canvas.drawCircle(g, 8.5, Paint()..color = govde);
    canvas.drawCircle(g, 8.5, Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    // Omuz detayı (ikinci renk şeridi)
    canvas.drawArc(Rect.fromCircle(center: g, radius: 8.5), pi * 0.15, pi * 0.7, true, Paint()..color = detay.withOpacity(0.9));
    // Kafa
    canvas.drawCircle(g - const Offset(0, 1.5), 4.2, Paint()..color = const Color(0xFFFFCC9E));
    canvas.drawArc(Rect.fromCircle(center: g - const Offset(0, 1.5), radius: 4.2), pi, pi, true, Paint()..color = const Color(0xFF3E2723));
    // Forma numarası
    yazi(canvas, '$no', g + const Offset(0, 11), 8, Colors.white, kalin: true);
    // İsim
    yazi(canvas, isim, g + const Offset(0, 20), 8, Colors.white);
  }

  @override
  bool shouldRepaint(covariant SahaPainter oldDelegate) => true;
}
