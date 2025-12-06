// lib/main.dart
// ✅ Medicine App (Excel -> Image from assets/images/amldac/<Name>.jpg)
// • ไม่ใช้คอลัมน์ "รูปยา" ใน Excel
// • จำกัด 36 รายการ
// • ใช้ .jpg อย่างเดียว (ไม่เดานามสกุล)
// • มี TTS (flutter_tts) อ่านชื่อยา/สรรพคุณ
// • Home: การ์ดยา (รูป+ชื่อ+สรรพคุณ) + BottomSheet รายละเอียด
// • Scan (จำลอง): กล้อง/แกลเลอรี + พิมพ์ชื่อยา -> หน้าผลลัพธ์
// • History เก็บใน SharedPreferences
// • Profile เปลี่ยนชื่อ/เลือกรูปโปรไฟล์ (local)

import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart' as xlsx;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() => runApp(const MyApp());

// ---------------- Root ----------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyMedicine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF06B6D4)),
        textTheme: GoogleFonts.kanitTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }
}

// ---------------- Splash ----------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(
            onRegisterClicked: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RegisterPage(onRegistered: () => Navigator.pop(context)),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('MyMedicine',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ---------------- Login ----------------
class LoginPage extends StatefulWidget {
  final VoidCallback onRegisterClicked;
  const LoginPage({super.key, required this.onRegisterClicked});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool rememberMe = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_me') ?? false;
    if (remember) {
      setState(() {
        emailController.text = prefs.getString('saved_email') ?? '';
        passwordController.text = prefs.getString('saved_password') ?? '';
        rememberMe = true;
      });
    }
  }

  Future<void> _login() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('user_email');
    final savedPassword = prefs.getString('user_password');
    if (emailController.text == savedEmail &&
        passwordController.text == savedPassword &&
        emailController.text.isNotEmpty) {
      if (rememberMe) {
        await prefs.setBool('remember_me', true);
        await prefs.setString('saved_email', emailController.text);
        await prefs.setString('saved_password', passwordController.text);
      } else {
        await prefs.setBool('remember_me', false);
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } else {
      setState(() => errorMessage = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFF),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: const Color(0xFFBEE3F8).withOpacity(.8)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.local_hospital_rounded,
                      color: Color(0xFF06B6D4), size: 30),
                  const SizedBox(width: 8),
                  Text('MyMedicine',
                      style: GoogleFonts.kanit(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A))),
                ]),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                      labelText: 'อีเมล', prefixIcon: Icon(Icons.email)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'รหัสผ่าน', prefixIcon: Icon(Icons.lock)),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Checkbox(
                      value: rememberMe,
                      onChanged: (v) => setState(() => rememberMe = v ?? false)),
                  const Text('จดจำฉันไว้'),
                  const Spacer(),
                  TextButton(
                      onPressed: widget.onRegisterClicked,
                      child: const Text('สมัครสมาชิก')),
                ]),
                const SizedBox(height: 12),
                FilledButton.icon(
                    onPressed: _login,
                    icon: const Icon(Icons.login),
                    label: const Text('เข้าสู่ระบบ')),
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(errorMessage,
                        style: const TextStyle(color: Colors.red)),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- Register ----------------
class RegisterPage extends StatefulWidget {
  final VoidCallback onRegistered;
  const RegisterPage({super.key, required this.onRegistered});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}
class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', _email.text.trim());
      await prefs.setString('user_password', _pw.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ลงทะเบียนสำเร็จ!')));
      widget.onRegistered();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(children: [
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'อีเมล'),
              validator: (v) =>
              (v == null || v.isEmpty) ? 'กรุณากรอกอีเมล' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pw,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
              validator: (v) =>
              (v == null || v.isEmpty) ? 'กรุณากรอกรหัสผ่าน' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pw2,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'ยืนยันรหัสผ่าน'),
              validator: (v) => v != _pw.text ? 'รหัสผ่านไม่ตรงกัน' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: _register, child: const Text('สมัครสมาชิก')),
          ]),
        ),
      ),
    );
  }
}

// ---------------- BottomNav ----------------
class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}
class _MainPageState extends State<MainPage> {
  int _current = 0;
  final _pages =
  const [HomePage(), ScanMedicinePage(), HistoryPage(), ProfilePage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_current],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _current,
        selectedItemColor: const Color(0xFF06B6D4),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _current = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

const Map<String, String> kImageOverrides = <String, String>{
};

// ---------------- Model & Repository ----------------
class MedItem {
  final String name;        // ชื่อยาความดันโลหิตสูง(ยี่ห้อยา_ชื่อยา)
  final String description; // สรรพคุณ
  final String imagePath;   // assets/images/amldac/<sanitized>.jpg
  MedItem(
      {required this.name,
        required this.description,
        required this.imagePath});
}

class MedRepository {
  static const String excelAsset = 'assets/data/meds.xlsm';
  static const String imgDir = 'assets/images/amldac/';

  List<MedItem>? _cache;

  // แปลงชื่อให้เป็นชื่อไฟล์: เว้นวรรค -> "_", อักขระต้องห้าม -> "_"
  String _fileBase(String name) {
    var s = name.trim();
    s = s.replaceAll(RegExp(r'\s+'), '_');
    s = s.replaceAll(RegExp(r'[\\/:"*?<>|]'), '_');
    return s;
  }

  Future<List<MedItem>> loadAll() async {
    if (_cache != null) return _cache!;
    final bytes = (await rootBundle.load(excelAsset)).buffer.asUint8List();
    final book = xlsx.Excel.decodeBytes(bytes);
    final sheet = book.tables.values.first;

    // header index
    final headers =
    sheet.row(0).map((c) => (c?.value?.toString() ?? '').trim()).toList();
    int idxOf(String h) =>
        headers.indexWhere((x) => x.toLowerCase() == h.toLowerCase());

    final idxName =
    idxOf('ชื่อยาความดันโลหิตสูง(ยี่ห้อยา_ชื่อยา)'); // ต้องตรงกับหัวคอลัมน์จริง
    final idxDesc = idxOf('สรรพคุณ');

    final out = <MedItem>[];
    for (int r = 1; r < sheet.maxRows && out.length < 36; r++) {
      final row = sheet.row(r);
      String cell(int i) => (i >= 0 && i < row.length && row[i] != null)
          ? row[i]!.value.toString().trim()
          : '';

      final name = cell(idxName);
      final desc = cell(idxDesc);
      if (name.isEmpty && desc.isEmpty) continue;

      final base = _fileBase(name);
      // ❗ไม่เดาไฟล์: ใช้ .jpg เท่านั้น (ถ้ามี override จะใช้ override ก่อน)
      final path = kImageOverrides[name] ?? '${imgDir}${base}.jpg';

      out.add(MedItem(name: name, description: desc, imagePath: path));
    }
    return _cache = out;
  }
}

// ---------------- Home ----------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final repo = MedRepository();
  final _search = TextEditingController();
  List<MedItem> _all = [];
  bool _loading = true;
  String _quick = 'ทั้งหมด';

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await repo.loadAll();
      if (!mounted) return;
      setState(() {
        _all = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โหลด meds.xlsm ไม่สำเร็จ: $e')),
      );
    }
  }

  List<MedItem> get _filtered {
    final q = _search.text.trim().toLowerCase();
    var base = _all.where((m) {
      final t = '${m.name} ${m.description}'.toLowerCase();
      return q.isEmpty || t.contains(q);
    }).toList();
    if (_quick == 'ทั้งหมด') return base;
    if (_quick == 'ความดันโลหิต') {
      base = base.where((m) {
        final t = '${m.name} ${m.description}'.toLowerCase();
        return t.contains('ความดัน') ||
            t.contains('ความดันโลหิต') ||
            t.contains('hypertension');
      }).toList();
    }
    return base;
  }

  void _openDetail(MedItem m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MedDetailSheet(item: m),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อมูลยาความดันโลหิตสูง (จำลอง)'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'ค้นหา "ยี่ห้อยา_ชื่อยา" หรือ สรรพคุณ…',
                filled: true,
                fillColor: const Color(0xFFF0F9FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFBAE6FD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                  const BorderSide(color: Color(0xFF0EA5E9), width: 1.4),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(children: [
              ChoiceChip(
                label: const Text('ทั้งหมด'),
                selected: _quick == 'ทั้งหมด',
                onSelected: (_) => setState(() => _quick = 'ทั้งหมด'),
                selectedColor: cs.primary.withOpacity(.15),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('ความดันโลหิต'),
                selected: _quick == 'ความดันโลหิต',
                onSelected: (_) => setState(() => _quick = 'ความดันโลหิต'),
                selectedColor: cs.primary.withOpacity(.15),
              ),
              const Spacer(),
              IconButton(
                onPressed: _load,
                tooltip: 'รีเฟรช',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ]),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_filtered.isEmpty)
            Expanded(
              child: Center(
                child: Text('ไม่พบรายการ',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: .75),
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final m = _filtered[i];
                  return GestureDetector(
                    onTap: () => _openDetail(m),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20)),
                            child: Image.asset(
                              m.imagePath,
                              height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 110,
                                color: cs.primary.withOpacity(.08),
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 6),
                                Text(
                                  m.description.isEmpty
                                      ? '— ไม่มีสรรพคุณ —'
                                      : m.description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: cs.onSurfaceVariant, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ]),
      ),
    );
  }
}

class _MedDetailSheet extends StatefulWidget {
  const _MedDetailSheet({required this.item});
  final MedItem item;
  @override
  State<_MedDetailSheet> createState() => _MedDetailSheetState();
}
class _MedDetailSheetState extends State<_MedDetailSheet> {
  final _tts = FlutterTts();
  bool _speaking = false;

  Future<void> _speak() async {
    if (_speaking) {
      await _tts.stop();
      setState(() => _speaking = false);
      return;
    }
    await _tts.setLanguage('th-TH');
    await _tts.setSpeechRate(0.47);
    await _tts.setPitch(1.0);
    final text =
        '${widget.item.name}. ${widget.item.description.isEmpty ? "ไม่มีสรรพคุณ" : widget.item.description}';
    setState(() => _speaking = true);
    await _tts.speak(text);
    setState(() => _speaking = false);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          top: 8),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              widget.item.imagePath,
              height: 190,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 190,
                alignment: Alignment.center,
                color: cs.primary.withOpacity(.08),
                child: const Icon(Icons.image_not_supported, size: 64),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(widget.item.name,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            widget.item.description.isEmpty
                ? '— ไม่มีสรรพคุณ —'
                : widget.item.description,
            style: TextStyle(
                fontSize: 16, color: cs.onSurface.withOpacity(.9), height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _speak,
                icon: Icon(_speaking
                    ? Icons.stop_circle_outlined
                    : Icons.volume_up_rounded),
                label: Text(_speaking ? 'หยุดอ่าน' : 'อ่านออกเสียง'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                label: const Text('ปิด'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ---------------- Scan (Mock) ----------------
class ScanMedicinePage extends StatefulWidget {
  const ScanMedicinePage({super.key});
  @override
  State<ScanMedicinePage> createState() => _ScanMedicinePageState();
}
class _ScanMedicinePageState extends State<ScanMedicinePage> {
  final _picker = ImagePicker();
  File? _image;
  final _nameController =
  TextEditingController(); // พิมพ์ชื่อยาเพื่อจำลองผล

  Future<void> _takePhoto() async {
    final x = await _picker.pickImage(source: ImageSource.camera);
    if (x != null) setState(() => _image = File(x.path));
  }

  Future<void> _pickGallery() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _image = File(x.path));
  }

  Future<void> _goResult() async {
    final name = _nameController.text.trim();
    if (_image == null || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('โปรดถ่าย/เลือกภาพ และพิมพ์ชื่อยา')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ScanResultPage(imageFile: _image!, detectedName: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Medicine (จำลอง)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('ถ่ายรูป'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('เลือกจากแกลเลอรี'),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          if (_image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_image!,
                  height: 150, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'พิมพ์ชื่อยา (เช่น Pfizer_Amlodipine)',
              prefixIcon: Icon(Icons.medication_liquid_outlined),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _goResult,
              icon: const Icon(Icons.fact_check_rounded),
              label: const Text('ดูผลลัพธ์'),
            ),
          ),
        ]),
      ),
    );
  }
}

class ScanResultPage extends StatelessWidget {
  const ScanResultPage(
      {super.key, required this.imageFile, required this.detectedName});
  final File imageFile;
  final String detectedName;

  Future<MedItem?> _findFromExcel() async {
    final repo = MedRepository();
    final all = await repo.loadAll();
    // เทียบชื่อแบบ case-insensitive
    return all.firstWhere(
          (m) => m.name.toLowerCase() == detectedName.toLowerCase(),
      orElse: () {
        // fallback .jpg ตรง ๆ (พร้อม sanitize)
        String sanitize(String x) {
          var s = x.trim();
          s = s.replaceAll(RegExp(r'\s+'), '_');
          s = s.replaceAll(RegExp(r'[\\/:"*?<>|]'), '_');
          return s;
        }
        final base = sanitize(detectedName);
        final override = kImageOverrides[detectedName];
        return MedItem(
          name: detectedName,
          description: '',
          imagePath: override ?? 'assets/images/amldac/${base}.jpg',
        );
      },
    );
  }

  Future<void> _saveHistory(List<String> items) async {
    await HistoryStore.addRecord(items);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<MedItem?>(
      future: _findFromExcel(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final med = snap.data!;
        return Scaffold(
          appBar: AppBar(title: const Text('ผลลัพธ์การสแกน')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [
                        cs.primary.withOpacity(.12),
                        cs.secondary.withOpacity(.08)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.outline.withOpacity(.2)),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(imageFile,
                        width: 86, height: 86, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ระบุยา',
                              style: TextStyle(color: cs.onSurfaceVariant)),
                          Text(med.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.verified_rounded,
                                size: 18, color: cs.primary),
                            const SizedBox(width: 6),
                            Text('ผลการสแกนจำลอง',
                                style: TextStyle(
                                    color: cs.onSurface.withOpacity(.7))),
                          ]),
                        ]),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      med.imagePath,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 72,
                        height: 72,
                        color: cs.primary.withOpacity(.08),
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              Text('สรรพคุณ',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(med.description.isEmpty
                  ? '— ไม่มีสรรพคุณ —'
                  : med.description),
            ]),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FilledButton.icon(
              onPressed: () async {
                await _saveHistory([med.name]);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('บันทึกลง History แล้ว')),
                  );
                }
              },
              icon: const Icon(Icons.save_alt_rounded),
              label: const Text('บันทึกลง History'),
            ),
          ),
        );
      },
    );
  }
}

// ---------------- History ----------------
class HistoryRecord {
  final DateTime time;
  final List<String> items;
  HistoryRecord({required this.time, required this.items});
  Map<String, dynamic> toJson() =>
      {'time': time.toIso8601String(), 'items': items};
  static HistoryRecord fromJson(Map<String, dynamic> j) => HistoryRecord(
      time: DateTime.parse(j['time']),
      items: (j['items'] as List).cast<String>());
}

class HistoryStore {
  static const _key = 'scan_history';
  static Future<List<HistoryRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => HistoryRecord.fromJson(e))
        .toList();
    list.sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  static Future<void> addRecord(List<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await load();
    list.insert(0, HistoryRecord(time: DateTime.now(), items: items));
    await prefs.setString(
        _key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}
class _HistoryPageState extends State<HistoryPage> {
  late Future<List<HistoryRecord>> _future;
  @override
  void initState() {
    super.initState();
    _future = HistoryStore.load();
  }

  Future<void> _refresh() async =>
      setState(() => _future = HistoryStore.load());

  Future<void> _clearAll() async {
    await HistoryStore.clear();
    if (mounted) {
      await _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบประวัติทั้งหมดแล้ว')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('History การสแกน'),
        actions: [
          IconButton(
            tooltip: 'ลบทั้งหมด',
            onPressed: _clearAll,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<HistoryRecord>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          if (data.isEmpty) {
            return Center(
              child: Text('ยังไม่มีประวัติการสแกน',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: data.length,
              itemBuilder: (context, i) {
                final rec = data[i];
                final timeText =
                    '${rec.time.year}-${rec.time.month.toString().padLeft(2, '0')}-${rec.time.day.toString().padLeft(2, '0')} '
                    '${rec.time.hour.toString().padLeft(2, '0')}:${rec.time.minute.toString().padLeft(2, '0')}';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.primary.withOpacity(.12),
                      child: Text('${rec.items.length}',
                          style: TextStyle(color: cs.primary)),
                    ),
                    title: Text(rec.items.join(', '),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('สแกนเมื่อ $timeText'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ---------------- Profile ----------------
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage> {
  String? email = '';
  String? displayName = 'ผู้ใช้ของฉัน';
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('user_email');
      displayName = prefs.getString('display_name') ?? 'ผู้ใช้ของฉัน';
    });
  }

  Future<void> _changeNameDialog() async {
    final controller = TextEditingController(text: displayName);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('เปลี่ยนชื่อผู้ใช้'),
        content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'กรอกชื่อใหม่')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('display_name', controller.text);
              setState(() => displayName = controller.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', false);
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPage(
          onRegisterClicked: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RegisterPage(onRegistered: () => Navigator.pop(context)),
              ),
            );
          },
        ),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          GestureDetector(
            onTap: _pickProfileImage,
            child: CircleAvatar(
              radius: 60,
              backgroundImage:
              _imageFile != null ? FileImage(_imageFile!) : null,
              backgroundColor: const Color(0xFF06B6D4).withOpacity(.25),
              child: _imageFile == null
                  ? const Icon(Icons.person, size: 60, color: Colors.black54)
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(displayName ?? '',
                style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            IconButton(onPressed: _changeNameDialog, icon: const Icon(Icons.edit)),
          ]),
          const SizedBox(height: 10),
          Text(email ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('ออกจากระบบ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            ),
          ),
        ]),
      ),
    );
  }
}
