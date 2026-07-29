import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kYesil = Color(0xFF2E7D32);
const Color kGokMavisi = Color(0xFF87CEEB);
const Color kTuruncu = Color(0xFFF57C00);
const Color kAltin = Color(0xFFFFD54F);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

class AnaCerceve extends StatefulWidget {
  const AnaCerceve({super.key});

  @override
  State<AnaCerceve> createState() => _AnaCerceveState();
}

class _AnaCerceveState extends State<AnaCerceve> {
  Ekran ekran = Ekran.yukleniyor;
  SharedPreferences? prefs;
  Map<String, dynamic>? kariyer;
  Map<String, dynamic> ayarlar = <String, dynamic>{
    'zorluk': 'Orta',
    'ses': 0.5,
    'titresim': true,
  };

  // Yeni kariyer formu geçici verisi
  String formAd = '';
  String formSoyad = '';
  String formUlke = 'Türkiye';
  String formTakim = '';
  List<int> formRenk = <int>[0, 0];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    prefs = await SharedPreferences.getInstance();
    final String? c = prefs!.getString('career');
    if (c != null) {
      kariyer = Map<String, dynamic>.from(jsonDecode(c) as Map<dynamic, dynamic>);
    }
    final String? s = prefs!.getString('settings');
    if (s != null) {
      ayarlar = Map<String, dynamic>.from(jsonDecode(s) as Map<dynamic, dynamic>);
    }
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
        govde = YukleniyorEkrani(bitir: () => git(Ekran.anaMenu));
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
          secti: (String takim, List<int> renk) {
            formTakim = takim;
            formRenk = renk;
            git(Ekran.sozlesme);
          },
        );
        break;
      case Ekran.sozlesme:
        govde = SozlesmeEkrani(
          ad: formAd,
          soyad: formSoyad,
          takim: formTakim,
          renk: formRenk,
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
            final Random r = Random();
            final int overall = 55 + r.nextInt(6);
            setState(() {
              kariyer = <String, dynamic>{
                'ad': formAd,
                'soyad': formSoyad,
                'ulke': formUlke,
                'lig': '$formUlke 3. Ligi',
                'takim': formTakim,
                'takimRenk': formRenk,
                'sezon': 1,
                'hafta': 1,
                'overall': overall,
                'gol': 0,
                'asist': 0,
                'macSayisi': 0,
                'ratingGecmisi': <double>[],
              };
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

// ---------- Ortak yardımcılar ----------

String takimEk(String takim) {
  // Basit bulunma eki: ’da/’de/’ta/’te
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
  // kalın/ince ünlü
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

Map<String, List<List<dynamic>>> tumTakimlar() {
  return <String, List<List<dynamic>>>{
    'Türkiye': <List<dynamic>>[
      <dynamic>['Hatayzanspor', 0xFFD32F2F, 0xFFFFFFFF],
      <dynamic>['Karadeniz Fırtına', 0xFF1565C0, 0xFF8D6E63],
      <dynamic>['Anadolu Yıldızı', 0xFFF9A825, 0xFF4E342E],
    ],
    'İngiltere': <List<dynamic>>[
      <dynamic>['Londra Kralları', 0xFF6A1B9A, 0xFFFFD54F],
      <dynamic>['Kuzey Şövalyeleri', 0xFF37474F, 0xFF90CAF9],
      <dynamic>['Thames Rovers', 0xFF00695C, 0xFFFFFFFF],
    ],
    'Almanya': <List<dynamic>>[
      <dynamic>['Berlin Kartalları', 0xFF212121, 0xFFD32F2F],
      <dynamic>['Ren Şimşekleri', 0xFFF9A825, 0xFF1565C0],
      <dynamic>['Bavyera Ayıları', 0xFF5D4037, 0xFFFFB300],
    ],
    'İspanya': <List<dynamic>>[
      <dynamic>['Madrid Güneşi', 0xFFFF6F00, 0xFFFFFFFF],
      <dynamic>['Katalan Şahinleri', 0xFFAD1457, 0xFFF9A825],
      <dynamic>['Endülüs Boğaları', 0xFF212121, 0xFFD32F2F],
    ],
    'İtalya': <List<dynamic>>[
      <dynamic>['Roma Gladyatörleri', 0xFF8E0000, 0xFFFFD54F],
      <dynamic>['Venedik Denizcileri', 0xFF0277BD, 0xFFFFFFFF],
      <dynamic>['Toskana Zeytinleri', 0xFF33691E, 0xFFFFF176],
    ],
    'Fransa': <List<dynamic>>[
      <dynamic>['Paris Horozları', 0xFF1565C0, 0xFFD32F2F],
      <dynamic>['Riviera Yıldızları', 0xFF00ACC1, 0xFFFFFFFF],
      <dynamic>['Lyon Aslanları', 0xFFE65100, 0xFF212121],
    ],
    'Hollanda': <List<dynamic>>[
      <dynamic>['Amsterdam Laleleri', 0xFFE64A19, 0xFFFFFFFF],
      <dynamic>['Değirmen United', 0xFF455A64, 0xFFFFD54F],
      <dynamic>['Peynir Şehri SK', 0xFFF9A825, 0xFF33691E],
    ],
    'Portekiz': <List<dynamic>>[
      <dynamic>['Lizbon Fenerleri', 0xFF2E7D32, 0xFFFFFFFF],
      <dynamic>['Porto Deniz Kartalı', 0xFF1565C0, 0xFFFFD54F],
      <dynamic>['Madeira Kayaları', 0xFF4E342E, 0xFFFFB300],
    ],
    'Belçika': <List<dynamic>>[
      <dynamic>['Brüksel Waffle FC', 0xFF6D4C41, 0xFFFFD54F],
      <dynamic>['Flaman Şövalyeleri', 0xFF212121, 0xFFF9A825],
      <dynamic>['Antwerp Elmasları', 0xFF00838F, 0xFFFFFFFF],
    ],
    'Brezilya': <List<dynamic>>[
      <dynamic>['Rio Samba Spor', 0xFF2E7D32, 0xFFF9A825],
      <dynamic>['Amazon Pumaları', 0xFF1B5E20, 0xFF8D6E63],
      <dynamic>['Sao Paulo Yıldırım', 0xFF212121, 0xFFFFFFFF],
    ],
    'Arjantin': <List<dynamic>>[
      <dynamic>['Buenos Tango FC', 0xFF81D4FA, 0xFFFFFFFF],
      <dynamic>['Pampa Kovboyları', 0xFF5D4037, 0xFFFFD54F],
      <dynamic>['And Kondorları', 0xFF37474F, 0xFFEF6C00],
    ],
  };
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
    // Şerit
    final Path serit = Path()
      ..moveTo(w * 0.35, h * 0.05)
      ..lineTo(w * 0.65, h * 0.05)
      ..lineTo(w * 0.65, h * 0.75)
      ..lineTo(w * 0.5, h * 0.9)
      ..lineTo(w * 0.35, h * 0.75)
      ..close();
    canvas.drawPath(serit, Paint()..color = renk2);
    // Çerçeve
    canvas.drawPath(
      kalkan,
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // Harfler
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
    // Mini top
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
      child: Padding(
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

  static const List<String> ulkeler = <String>[
    'Türkiye', 'İngiltere', 'Almanya', 'İspanya', 'İtalya', 'Fransa',
    'Hollanda', 'Portekiz', 'Belçika', 'Brezilya', 'Arjantin',
  ];

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
                    for (final String u in ulkeler) DropdownMenuItem<String>(value: u, child: Text(u)),
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

// ---------- Ekran 5: Takım Seçimi ----------

class TakimSecimEkrani extends StatefulWidget {
  final String ulke;
  final VoidCallback geri;
  final void Function(String, List<int>) secti;

  const TakimSecimEkrani({super.key, required this.ulke, required this.geri, required this.secti});

  @override
  State<TakimSecimEkrani> createState() => _TakimSecimEkraniState();
}

class _TakimSecimEkraniState extends State<TakimSecimEkrani> {
  int secili = -1;

  @override
  Widget build(BuildContext context) {
    final List<List<dynamic>> takimlar = tumTakimlar()[widget.ulke] ?? tumTakimlar()['Türkiye']!;
    return sahaArkaplan(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('${widget.ulke} 3. Ligi', textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Takımını Seç!', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, color: Colors.white)),
            const SizedBox(height: 24),
            for (int i = 0; i < takimlar.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () => setState(() => secili = i),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: secili == i ? kAltin : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: secili == i ? kTuruncu : Colors.transparent, width: 4),
                    ),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: CustomPaint(
                            painter: RozetPainter(
                              Color(takimlar[i][1] as int),
                              Color(takimlar[i][2] as int),
                              basHarfler(takimlar[i][0] as String),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            takimlar[i][0] as String,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (secili == i) const Icon(Icons.check_circle, color: kYesil, size: 32),
                      ],
                    ),
                  ),
                ),
              ),
            const Spacer(),
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
                            widget.secti(
                              takimlar[secili][0] as String,
                              <int>[takimlar[secili][1] as int, takimlar[secili][2] as int],
                            );
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
  final List<int> renk;
  final VoidCallback geri;
  final VoidCallback imzaladi;

  const SozlesmeEkrani({
    super.key,
    required this.ad,
    required this.soyad,
    required this.takim,
    required this.renk,
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

// ---------- Ekran 8: Kariyer Ana Sayfası ----------

class GrafikPainter extends CustomPainter {
  final List<double> degerler;
  GrafikPainter(this.degerler);

  @override
  void paint(Canvas canvas, Size size) {
    if (degerler.isEmpty) return;
    final List<double> son = degerler.length > 10 ? degerler.sublist(degerler.length - 10) : degerler;
    final double barW = size.width / (son.length * 2);
    for (int i = 0; i < son.length; i++) {
      final double v = son[i].clamp(0.0, 10.0);
      final double h = size.height * (v / 10.0);
      final double x = size.width * (i / son.length) + barW / 2;
      final Rect r = Rect.fromLTWH(x, size.height - h, barW, h);
      final Color renk = v >= 7 ? kYesil : (v >= 5 ? kTuruncu : Colors.red.shade400);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(4)),
        Paint()..color = renk,
      );
    }
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), Paint()..color = Colors.white,);
  }

  @override
  bool shouldRepaint(covariant GrafikPainter oldDelegate) => true;
}

class KariyerEkrani extends StatelessWidget {
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

  String _str(String k, [String d = '']) => (kariyer[k] ?? d) as String;
  int _int(String k, [int d = 0]) => ((kariyer[k] ?? d) as num).toInt();

  List<double> ratingler() {
    final List<dynamic> ham = (kariyer['ratingGecmisi'] ?? <double>[]) as List<dynamic>;
    return <double>[for (final dynamic e in ham) (e as num).toDouble()];
  }

  void macYap(BuildContext context) {
    final Random r = Random();
    final int overall = _int('overall', 60);
    final String zorluk = _ayarStr('zorluk', 'Orta');
    // Zorluğa göre rakip gücü
    int rakipGuc;
    if (zorluk == 'Kolay') {
      rakipGuc = 45 + r.nextInt(15);
    } else if (zorluk == 'Zor') {
      rakipGuc = 60 + r.nextInt(20);
    } else {
      rakipGuc = 52 + r.nextInt(16);
    }
    final int fark = overall - rakipGuc;
    int golBiz = max(0, 1 + (fark / 10).round() + r.nextInt(3) - 1);
    int golRakip = max(0, 1 - (fark / 10).round() + r.nextInt(3) - 1);
    // Oyuncu katkısı
    final double golSansi = zorluk == 'Kolay' ? 0.55 : (zorluk == 'Zor' ? 0.3 : 0.42);
    int gol = 0;
    int asist = 0;
    for (int i = 0; i < golBiz; i++) {
      final double z = r.nextDouble();
      if (z < golSansi * 0.5) {
        gol++;
      } else if (z < golSansi) {
        asist++;
      }
    }
    // Rating
    double rating = 6.0 + gol * 1.3 + asist * 0.8 + (golBiz > golRakip ? 0.7 : (golBiz == golRakip ? 0.2 : -0.5));
    rating = rating.clamp(3.0, 10.0);
    // Overall değişimi
    int yeniOverall = overall + (rating >= 7.5 ? 1 : (rating < 5 ? -1 : 0));
    yeniOverall = yeniOverall.clamp(40, 99);
    kariyer['overall'] = yeniOverall;
    kariyer['gol'] = _int('gol') + gol;
    kariyer['asist'] = _int('asist') + asist;
    kariyer['macSayisi'] = _int('macSayisi') + 1;
    kariyer['hafta'] = _int('hafta', 1) + 1;
    final List<double> g = ratingler()..add(double.parse(rating.toStringAsFixed(1)));
    kariyer['ratingGecmisi'] = g;
    kaydet();
    degisti();

    final bool galibiyet = golBiz > golRakip;
    final bool berabere = golBiz == golRakip;
    showDialog<void>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: Text(galibiyet ? '🎉 Galibiyet!' : (berabere ? '🤝 Beraberlik' : '😞 Mağlubiyet')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('${_str('takim')} $golBiz - $golRakip Rakip', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (gol > 0) Text('⚽ $gol gol attın! Harikasın! 🎊', style: const TextStyle(fontSize: 18)),
            if (asist > 0) Text('👟 $asist asist yaptın!', style: const TextStyle(fontSize: 18)),
            if (gol == 0 && asist == 0) const Text('Bu maç sessiz kaldın. Sıradaki maçta parlayacaksın! 💪', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Maç notun: ${rating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: <Widget>[
          ElevatedButton(onPressed: () => Navigator.pop(c), child: const Text('Tamam', style: TextStyle(fontSize: 18))),
        ],
      ),
    );
  }

  String _ayarStr(String k, String d) => (ayarlar[k] ?? d) as String;

  void antrenman(BuildContext context) {
    final int hafta = _int('hafta', 1);
    final int sonAnt = _int('sonAntrenman', 0);
    if (sonAnt == hafta) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu hafta zaten antrenman yaptın!')));
      return;
    }
    final Random r = Random();
    final int overall = _int('overall', 60);
    if (r.nextDouble() < 0.6 && overall < 99) {
      kariyer['overall'] = overall + 1;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🏋 Süper antrenman! +1 Overall')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🏋 İyi çalıştın! Formdasın.')));
    }
    kariyer['sonAntrenman'] = hafta;
    kaydet();
    degisti();
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> renkHam = (kariyer['takimRenk'] ?? <int>[0xFF2E7D32, 0xFFFFFFFF]) as List<dynamic>;
    final List<int> renk = <int>[for (final dynamic e in renkHam) (e as num).toInt()];
    final List<double> gecmis = ratingler();
    return sahaArkaplan(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CustomPaint(painter: RozetPainter(Color(renk[0]), Color(renk[1]), basHarfler(_str('takim')))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('${_str('ad')} ${_str('soyad')}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('${_str('takim')} • ${_str('lig')}', style: const TextStyle(fontSize: 16, color: Colors.white)),
                      Text('Sezon ${_int('sezon', 1)} • Hafta ${_int('hafta', 1)}', style: const TextStyle(fontSize: 16, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            const Text('⭐ Overall', style: TextStyle(fontSize: 16)),
                            Text('${_int('overall', 60)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: kYesil)),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            const Text('🎂 Yaş', style: TextStyle(fontSize: 16)),
                            Text('${16 + _int('sezon', 1) - 1}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Text('⚽ Gol: ${_int('gol')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('👟 Asist: ${_int('asist')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('🏟 Maç: ${_int('macSayisi')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.white24,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: <Widget>[
                    const Text('📊 Performans Grafiği (son haftalar)', style: TextStyle(fontSize: 16, color: Colors.white)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      width: double.infinity,
                      child: gecmis.isEmpty
                          ? const Center(child: Text('Henüz maç yok', style: TextStyle(color: Colors.white)))
                          : CustomPaint(painter: GrafikPainter(gecmis)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            buyukButon(yazi: '⚽ Maç Yap', renk: kYesil, onPressed: () => macYap(context)),
            const SizedBox(height: 12),
            buyukButon(yazi: '🏋 Antrenman', onPressed: () => antrenman(context)),
            const SizedBox(height: 12),
            buyukButon(yazi: '🏠 Ana Menü', renk: const Color(0xFF546E7A), onPressed: anaMenu),
          ],
        ),
      ),
    );
  }
}
