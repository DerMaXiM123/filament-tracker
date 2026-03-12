import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:nfc_manager/nfc_manager.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'models/filament.dart';
import 'models/verbrauch.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://buwblyxrtiqkmmadngsb.supabase.co',
    anonKey: 'sb_publishable_GHfNYC68iTME3xkwD_D7Yg_yNZTjXpH',
  );
  
  runApp(const FilamentTrackerApp());
}

class FilamentTrackerApp extends StatefulWidget {
  const FilamentTrackerApp({super.key});

  @override
  State<FilamentTrackerApp> createState() => _FilamentTrackerAppState();
}

class _FilamentTrackerAppState extends State<FilamentTrackerApp> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _appVersion = '1.1.2';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSession();
      _checkForUpdates();
    }
  }

  Future<void> _checkSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && mounted) {
      setState(() {
        _isLoggedIn = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
    // Check for updates regardless of login status
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    try {
      // Check GitHub releases for updates (including pre-releases)
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/DerMaXiM123/filament-tracker/releases'),
        headers: {'Accept': 'application/vnd.github+json'},
      );
      
      debugPrint('Update check response: ${response.statusCode}');
      
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body) as List<dynamic>;
        if (data.isEmpty) return;
        
        // Get latest release (first one)
        final latest = data[0] as Map<String, dynamic>;
        final tagName = latest['tag_name'] as String? ?? 'v1.0.0';
        final remoteVersion = tagName.replaceFirst('v', '');
        final body = latest['body'] as String? ?? 'Neue Version verfügbar!';
        
        debugPrint('Remote version: $remoteVersion, Local: $_appVersion');
        
        // Get download URL for Android APK
        String downloadUrl = '';
        final assets = latest['assets'] as List<dynamic>? ?? [];
        for (var asset in assets) {
          if ((asset['name'] as String?).toString().endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String;
            break;
          }
        }
        
        debugPrint('Download URL: $downloadUrl');
        
        if (downloadUrl.isNotEmpty && _needsUpdate(remoteVersion)) {
          _showUpdateDialog(downloadUrl, body);
        }
      }
    } catch (e) {
      debugPrint('Update check error: $e');
    }
  }

  bool _needsUpdate(String remoteVersion) {
    final local = _appVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final remote = remoteVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      if (remote[i] > local[i]) return true;
      if (remote[i] < local[i]) return false;
    }
    return false;
  }

  void _showUpdateDialog(String url, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UpdateDownloadDialog(url: url, message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _darkTheme,
        home: Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.inventory_2, size: 60, color: Color(0xFF00BCD4)),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Color(0xFF00BCD4)),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _darkTheme,
      home: _isLoggedIn 
          ? HomePage(supabase: Supabase.instance.client)
          : const LoginPage(),
    );
  }

  ThemeData get _darkTheme => ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00BCD4),
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      indicatorColor: const Color(0xFF00BCD4).withAlpha(77),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF00BCD4),
      foregroundColor: Colors.black,
    ),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isSignUp = false;

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Bitte Email und Passwort eingeben';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final client = _supabase;
      AuthResponse? response;
      
      if (_isSignUp) {
        response = await client.auth.signUp(
          email: email,
          password: password,
        );
      } else {
        response = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
      
      if (response.user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(supabase: client)),
        );
      } else if (mounted) {
        setState(() {
          _errorMessage = _isSignUp ? 'Registrierung fehlgeschlagen' : 'Anmeldung fehlgeschlagen';
        });
      }
    } catch (e) {
      debugPrint('Auth error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Fehler: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.inventory_2, size: 80, color: Color(0xFF00BCD4)),
                ),
                const SizedBox(height: 24),
                Text(
                  'FilamentTracker',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp ? 'Konto erstellen' : 'Willkommen zurück',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(77),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Colors.white.withAlpha(179)),
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF00BCD4)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Passwort',
                          labelStyle: TextStyle(color: Colors.white.withAlpha(179)),
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00BCD4)),
                        ),
                      ),
                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: (_isLoading) ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  _isSignUp ? 'Registrieren' : 'Anmelden',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => setState(() {
                    _isSignUp = !_isSignUp;
                    _errorMessage = '';
                  }),
                  child: Text(
                    _isSignUp ? 'Bereits Konto? Anmelden' : 'Neues Konto? Registrieren',
                    style: TextStyle(color: Colors.white.withAlpha(179)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final SupabaseClient supabase;
  const HomePage({super.key, required this.supabase});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<Filament> _filamente = [];
  List<Verbrauch> _verbrauche = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = widget.supabase.auth.currentUser;
      if (user?.id != null) {
        final userId = user!.id;
        
        final fResponse = await widget.supabase.from('filamente').select().eq('user_id', userId);
        if (fResponse != null && mounted) {
          _filamente = fResponse.map((e) {
            if (e is Map) {
              return Filament.fromMap(Map<String, dynamic>.from(e));
            }
            return Filament.fromMap({});
          }).toList();
        }
        
        final vResponse = await widget.supabase.from('verbrauch').select().eq('user_id', userId);
        if (vResponse != null && mounted) {
          _verbrauche = vResponse.map((e) {
            if (e is Map) {
              return Verbrauch.fromMap(Map<String, dynamic>.from(e));
            }
            return Verbrauch.fromMap({});
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Load error: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF00BCD4)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          _selectedIndex == 0 ? 'Inventar' : _selectedIndex == 1 ? 'Creator' : _selectedIndex == 2 ? 'Statistik' : 'Einstellungen',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF121212),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedIndex == 0
              ? _buildInventory()
              : _selectedIndex == 1
                  ? _buildCreator()
                  : _selectedIndex == 2
                      ? _buildStatistics()
                      : _buildSettings(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFilament,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 30,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00BCD4).withAlpha(77),
                  const Color(0xFF1E1E1E),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.inventory_2, color: Color(0xFF00BCD4), size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'FilamentTracker',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.supabase.auth.currentUser?.email ?? '',
                  style: TextStyle(color: Colors.white.withAlpha(153), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildDrawerItem(0, Icons.inventory_2_outlined, 'Inventar'),
          _buildDrawerItem(1, Icons.auto_awesome, 'Creator'),
          _buildDrawerItem(2, Icons.bar_chart, 'Statistik'),
          _buildDrawerItem(3, Icons.settings, 'Einstellungen'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: InkWell(
              onTap: () async {
                await widget.supabase.auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const FilamentTrackerApp()),
                    (route) => false,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Abmelden', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (index == 0) _loadData();
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00BCD4).withAlpha(38) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00BCD4) : Colors.white.withAlpha(153),
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00BCD4) : Colors.white.withAlpha(204),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addFilament() async {
    String selectedManufacturer = 'Prusa';
    String selectedType = 'PLA';
    String selectedColor = 'Weiß';
    bool useCustomColor = false;
    String? nfcTagId;
    final customColorController = TextEditingController();
    final gewichtController = TextEditingController(text: '1000');
    final preisController = TextEditingController(text: '25');

    final manufacturers = ['Prusa', 'eSun', 'MatterHackers', 'Hatchbox', 'Sunlu', 'Generic', 'Polymaker', 'Fillamentum'];
    final types = ['PLA', 'PETG', 'ABS', 'TPU', 'ASA', 'PC', 'PA', 'PVB'];
    final colors = ['Weiß', 'Schwarz', 'Rot', 'Blau', 'Grün', 'Gelb', 'Orange', 'Lila', 'Rosa', 'Grau', 'Transparent', 'Braun', 'Beige', 'Titanium', 'Silber', 'Gold', 'Kupfer', 'Neon Grün', 'Neon Pink', 'Neon Orange'];

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF00BCD4).withAlpha(200), const Color(0xFF00BCD4).withAlpha(77)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('Neues Filament', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('NFC-Scan wird gestartet...'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                      
                      try {
                        bool isAvailable = await NfcManager.instance.isAvailable();
                        if (!isAvailable) {
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(content: Text('NFC nicht verfügbar oder deaktiviert!')),
                            );
                          }
                          return;
                        }
                        
                        await NfcManager.instance.startSession(
                          pollingOptions: {
                            NfcPollingOption.iso14443,
                            NfcPollingOption.iso15693,
                          },
                          onDiscovered: (NfcTag tag) async {
                            try {
                              String? tagId;
                              final tagData = tag.data as Map<String, dynamic>;
                              
                              if (tagData.containsKey('nfca')) {
                                final nfca = tagData['nfca'] as Map<dynamic, dynamic>?;
                                if (nfca != null && nfca['identifier'] != null) {
                                  final id = nfca['identifier'] as List<dynamic>;
                                  tagId = id.map((e) => (e as int).toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
                                }
                              }
                              
                              if (tagId != null && dialogContext.mounted) {
                                setDialogState(() {
                                  nfcTagId = tagId;
                                });
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  SnackBar(
                                    content: Text('NFC erkannt: $tagId'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              // Ignore errors
                            }
                            try {
                              await NfcManager.instance.stopSession();
                            } catch (_) {}
                          },
                        );
                      } catch (e) {
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text('NFC Fehler: $e')),
                          );
                        }
                      }
                    },
                    icon: Icon(Icons.nfc, color: nfcTagId != null ? Colors.green : const Color(0xFF00BCD4)),
                    label: Text(
                      nfcTagId != null ? 'NFC: $nfcTagId' : 'NFC-Chip scannen', 
                      style: TextStyle(color: nfcTagId != null ? Colors.green : const Color(0xFF00BCD4))
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: nfcTagId != null ? Colors.green : const Color(0xFF00BCD4)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: selectedManufacturer,
                    dropdownColor: const Color(0xFF2D2D3D),
                    style: const TextStyle(color: Colors.white),
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Hersteller',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.business, color: Color(0xFF00BCD4)),
                      filled: true,
                      fillColor: const Color(0xFF2D2D3D),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: manufacturers.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (v) => setDialogState(() => selectedManufacturer = v ?? 'Prusa'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    dropdownColor: const Color(0xFF2D2D3D),
                    style: const TextStyle(color: Colors.white),
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Typ',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.category, color: Color(0xFF00BCD4)),
                      filled: true,
                      fillColor: const Color(0xFF2D2D3D),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (v) => setDialogState(() => selectedType = v ?? 'PLA'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: useCustomColor,
                        activeColor: const Color(0xFF00BCD4),
                        onChanged: (v) => setDialogState(() => useCustomColor = v ?? false),
                      ),
                      const Text('Eigene Farbe', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  if (useCustomColor) ...[
                    TextField(
                      controller: customColorController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Farbe eingeben',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.palette, color: Color(0xFF00BCD4)),
                        filled: true,
                        fillColor: const Color(0xFF2D2D3D),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      value: selectedColor,
                      dropdownColor: const Color(0xFF2D2D3D),
                      style: const TextStyle(color: Colors.white),
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Farbe',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.palette, color: Color(0xFF00BCD4)),
                        filled: true,
                        fillColor: const Color(0xFF2D2D3D),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: colors.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (v) => setDialogState(() => selectedColor = v ?? 'Weiß'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: gewichtController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Gewicht (g)',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.scale, color: Color(0xFF00BCD4)),
                            filled: true,
                            fillColor: const Color(0xFF2D2D3D),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: preisController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Preis (€)',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.euro, color: Color(0xFF00BCD4)),
                            filled: true,
                            fillColor: const Color(0xFF2D2D3D),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00BCD4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Speichern'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      final finalColor = useCustomColor ? customColorController.text : selectedColor;
      if (finalColor.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte Farbe eingeben')),
        );
        return;
      }
      final user = widget.supabase.auth.currentUser;
      if (user?.id != null) {
        try {
          await widget.supabase.from('filamente').insert({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'farbe': finalColor,
            'typ': selectedType,
            'marke': selectedManufacturer,
            'gewicht_gramm': int.tryParse(gewichtController.text) ?? 1000,
            'restgewicht_gramm': int.tryParse(gewichtController.text) ?? 1000,
            'preis': double.tryParse(preisController.text) ?? 0,
            'user_id': user!.id,
            'gekauft_am': DateTime.now().toIso8601String(),
            'nfc_tag_id': nfcTagId,
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Filament erfolgreich erstellt!'), backgroundColor: Colors.green),
            );
          }
          _loadData();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }

  // ============ CREATOR (LEGO BUILDER) ============
  Widget _buildCreator() {
    return const LEGOBuilder();
  }

  // ============ STATISTICS ============
  Widget _buildStatistics() {
    final total = _filamente.fold<int>(0, (sum, f) => sum + f.restgewichtGramm);
    final used = _verbrauche.fold<int>(0, (sum, v) => sum + v.verbrauchtGramm);
    final totalValue = _filamente.fold<double>(0, (sum, f) => sum + (f.preis * f.restgewichtGramm / 1000));
    final lowStockCount = _filamente.where((f) => f.prozentVerbleibend < 20).length;
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildBigStatCard(
            'Gesamtwert',
            '${totalValue.toStringAsFixed(2)}€',
            Icons.account_balance_wallet,
            const Color(0xFF00BCD4),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 1 : 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: isMobile ? 3.0 : 1.8,
            children: [
              _buildStatCardSmall('Bestand', '${total}g', Icons.inventory_2, Colors.blue),
              _buildStatCardSmall('Verbraucht', '${used}g', Icons.trending_down, Colors.orange),
              _buildStatCardSmall('Spulen', '${_filamente.length}', Icons.layers, Colors.purple),
              _buildStatCardSmall('Drucke', '${_verbrauche.length}', Icons.print, Colors.green),
            ],
          ),
          const SizedBox(height: 12),
          if (lowStockCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withAlpha(77)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text('$lowStockCount Spulen unter 20%', style: TextStyle(color: Colors.red.withAlpha(204), fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBigStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(64), color.withAlpha(20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatCardSmall(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 10)),
              Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventory() {
    if (_filamente.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFF00BCD4)),
            ),
            const SizedBox(height: 24),
            const Text('Noch keine Filamente', style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Drücke + um dein erstes Filament hinzuzufügen', style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
      );
    }

    Map<String, Map<String, List<Filament>>> grouped = {};
    for (var f in _filamente) {
      grouped.putIfAbsent(f.marke, () => {}).putIfAbsent(f.typ, () => []).add(f);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((mEntry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF00BCD4).withAlpha(200), const Color(0xFF00BCD4).withAlpha(100)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      mEntry.key.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${mEntry.value.values.fold<int>(0, (sum, list) => sum + list.length)} Spulen',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...mEntry.value.entries.map((tEntry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: _getTypeColor(tEntry.key),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tEntry.key.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getTypeColor(tEntry.key),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: tEntry.value.map((f) => _buildModernFilamentCard(f)).toList(),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'PLA': return const Color(0xFF4CAF50);
      case 'PETG': return const Color(0xFF2196F3);
      case 'ABS': return const Color(0xFFFF9800);
      case 'TPU': return const Color(0xFFE91E63);
      case 'ASA': return const Color(0xFF9C27B0);
      case 'PC': return const Color(0xFF00BCD4);
      case 'PA': return const Color(0xFFFFEB3B);
      default: return const Color(0xFF607D8B);
    }
  }

  Widget _buildModernFilamentCard(Filament f) {
    final prozent = f.prozentVerbleibend;
    final spoolColor = _parseFilamentColor(f.farbe);
    final isLow = prozent < 20;
    final isMedium = prozent < 50;

    return GestureDetector(
      onTap: () => _showFilamentDetails(f),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLow ? Colors.red.withAlpha(128) : isMedium ? Colors.orange.withAlpha(77) : Colors.white.withAlpha(13),
            width: isLow ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isLow ? Colors.red.withAlpha(26) : Colors.black.withAlpha(51),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [spoolColor, spoolColor.withAlpha(153)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [spoolColor.withAlpha(230), spoolColor.withAlpha(77)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E2E),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isLow)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(51),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning, size: 10, color: Colors.red),
                              SizedBox(width: 2),
                              Text('LOW', style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    f.farbe,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${f.restgewichtGramm}g',
                              style: TextStyle(
                                color: isLow ? Colors.red : isMedium ? Colors.orange : const Color(0xFF00BCD4),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'von ${f.gewichtGramm}g',
                              style: TextStyle(color: Colors.white.withAlpha(102), fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: prozent / 100,
                      backgroundColor: Colors.white.withAlpha(26),
                      valueColor: AlwaysStoppedAnimation(
                        isLow ? Colors.red : isMedium ? Colors.orange : const Color(0xFF00BCD4),
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${prozent}%',
                        style: TextStyle(
                          color: isLow ? Colors.red : isMedium ? Colors.orange : Colors.white.withAlpha(153),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '€${(f.preis * f.restgewichtGramm / 1000).toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.white.withAlpha(153), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseFilamentColor(String farbe) {
    final colorName = farbe.toLowerCase();
    if (colorName.contains('rot') || colorName.contains('red')) return Colors.red;
    if (colorName.contains('blau') || colorName.contains('blue')) return Colors.blue;
    if (colorName.contains('grün') || colorName.contains('green')) return Colors.green;
    if (colorName.contains('gelb') || colorName.contains('yellow')) return Colors.yellow;
    if (colorName.contains('orange')) return Colors.orange;
    if (colorName.contains('schwarz') || colorName.contains('black')) return Colors.black;
    if (colorName.contains('weiß') || colorName.contains('white')) return Colors.white;
    if (colorName.contains('grau') || colorName.contains('grey') || colorName.contains('gray')) return Colors.grey;
    if (colorName.contains('lila') || colorName.contains('violett') || colorName.contains('purple')) return Colors.purple;
    if (colorName.contains('pink') || colorName.contains('magenta')) return Colors.pink;
    if (colorName.contains('türkis') || colorName.contains('cyan')) return Colors.cyan;
    if (colorName.contains('braun') || colorName.contains('brown')) return Colors.brown;
    return const Color(0xFF00BCD4);
  }

  Future<void> _showFilamentDetails(Filament f) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_parseFilamentColor(f.farbe).withAlpha(230), _parseFilamentColor(f.farbe).withAlpha(77)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.inventory_2, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${f.marke} ${f.typ}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          f.farbe,
                          style: TextStyle(color: _parseFilamentColor(f.farbe), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D3D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _detailRow('Restgewicht', '${f.restgewichtGramm}g', Icons.scale),
                    const Divider(color: Colors.white12, height: 24),
                    _detailRow('Original', '${f.gewichtGramm}g', Icons.inventory),
                    const Divider(color: Colors.white12, height: 24),
                    _detailRow('Verbraucht', '${f.gewichtGramm - f.restgewichtGramm}g', Icons.trending_down),
                    const Divider(color: Colors.white12, height: 24),
                    _detailRow('Preis/Spule', '${f.preis.toStringAsFixed(2)}€', Icons.euro),
                    const Divider(color: Colors.white12, height: 24),
                    _detailRow('Aktueller Wert', '${(f.preis * f.restgewichtGramm / 1000).toStringAsFixed(2)}€', Icons.account_balance_wallet),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(dialogContext, 'delete'),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Löschen', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(dialogContext, 'use'),
                      icon: const Icon(Icons.edit),
                      label: const Text('Verbrauchen'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == 'delete') {
      await widget.supabase.from('filamente').delete().eq('id', f.id);
      _loadData();
    } else if (result == 'use') {
      _showUseDialog(f);
    }
  }

  Widget _detailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00BCD4), size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white70)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _showUseDialog(Filament f) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_note, color: Color(0xFF00BCD4), size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Filament verbrauchen', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Verfügbar: ${f.restgewichtGramm}g',
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Menge eingeben',
                  hintStyle: TextStyle(color: Colors.white.withAlpha(77)),
                  suffixText: 'g',
                  suffixStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2D2D3D),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00BCD4))),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Speichern'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      final used = int.tryParse(controller.text) ?? 0;
      if (used > 0 && used <= f.restgewichtGramm) {
        await widget.supabase.from('verbrauch').insert({
          'filament_id': f.id,
          'verbraucht_gramm': used,
          'datum': DateTime.now().toIso8601String(),
        });
        await widget.supabase.from('filamente').update({
          'restgewicht_gramm': f.restgewichtGramm - used,
        }).eq('id', f.id);
        _loadData();
      }
    }
  }

  // ============ DIALOGS ============
  Widget _buildSettings() {
    final user = widget.supabase.auth.currentUser;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Color(0xFF00BCD4), size: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.email ?? 'Unbekannt',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Angemeldet',
                  style: TextStyle(color: Colors.white.withAlpha(128)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await widget.supabase.auth.signOut();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const FilamentTrackerApp()),
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Abmelden'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ LEGO BUILDER WIDGET ============
class LEGOBuilder extends StatefulWidget {
  const LEGOBuilder({super.key});

  @override
  State<LEGOBuilder> createState() => _LEGOBuilderState();
}

class _LEGOBuilderState extends State<LEGOBuilder> {
  int _studsX = 2;
  int _studsZ = 4;
  String _colorName = 'Rot';
  Color _legoColor = const Color(0xFFef4444);
  bool _isExporting = false;
  int _viewAngle = 0;

  static const double PITCH = 8.0;
  static const double HEIGHT = 9.6;
  static const double STUD_H = 1.7;
  static const double STUD_R = 2.4;
  static const double WALL_T = 1.5;
  static const double TUBE_R_OUT = 3.255;
  static const double TUBE_R_IN = 2.4;
  static const int SEGMENTS = 128;

  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Rot', 'color': const Color(0xFFef4444)},
    {'name': 'Blau', 'color': const Color(0xFF3b82f6)},
    {'name': 'Grün', 'color': const Color(0xFF10b981)},
    {'name': 'Orange', 'color': const Color(0xFFf59e0b)},
    {'name': 'Weiß', 'color': const Color(0xFFffffff)},
    {'name': 'Schwarz', 'color': const Color(0xFF18181b)},
    {'name': 'Lila', 'color': const Color(0xFFa855f7)},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildControls(),
          const SizedBox(height: 16),
          _build3DPreview(),
          const SizedBox(height: 16),
          _buildDimensionsInfo(),
          const SizedBox(height: 16),
          _buildExportButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFef4444).withAlpha(26), const Color(0xFF1E1E1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFef4444).withAlpha(51)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFef4444).withAlpha(26),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.view_in_ar, color: Color(0xFFef4444), size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BRICK LAB', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                Text('LEGO® Precision Studio', style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFef4444).withAlpha(26), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.tune, color: Color(0xFFef4444), size: 18),
              ),
              const SizedBox(width: 12),
              Text('PARAMETERS', style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 16),
          _buildSelector('Stud Width', _studsX, [1, 2, 4, 8], (v) => setState(() => _studsX = v)),
          const SizedBox(height: 12),
          _buildSelector('Stud Length', _studsZ, [1, 2, 4, 6, 8, 12], (v) => setState(() => _studsZ = v)),
          const SizedBox(height: 12),
          _buildColorSelector(),
        ],
      ),
    );
  }

  Widget _buildSelector(String label, int value, List<int> options, Function(int) onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 10, fontWeight: FontWeight.w600)),
            Text('${value}x', style: const TextStyle(color: Color(0xFFef4444), fontSize: 12, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: options.map((v) {
            final isSelected = v == value;
            return InkWell(
              onTap: () => onChange(v),
              child: Container(
                width: 44,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFef4444) : Colors.white.withAlpha(13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('$v', style: TextStyle(color: isSelected ? Colors.white : Colors.white.withAlpha(77), fontSize: 12, fontWeight: FontWeight.w900)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Material Grade', style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _colorOptions.map((c) {
            final isSelected = c['name'] == _colorName;
            return InkWell(
              onTap: () => setState(() {
                _colorName = c['name'];
                _legoColor = c['color'];
              }),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c['color'],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
                  boxShadow: isSelected ? [BoxShadow(color: c['color'].withAlpha(128), blurRadius: 8)] : null,
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _build3DPreview() {
    return Container(
      height: 280,
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withAlpha(13))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.yellow.withAlpha(26), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.yellow.withAlpha(51))),
                      child: Row(children: [Icon(Icons.bolt, color: Colors.yellow.withAlpha(179), size: 12), const SizedBox(width: 4), Text('Clutch High', style: TextStyle(color: Colors.yellow.withAlpha(179), fontSize: 8, fontWeight: FontWeight.w900))]),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue.withAlpha(26), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.withAlpha(51))),
                      child: Row(children: [Icon(Icons.shield, color: Colors.blue.withAlpha(179), size: 12), const SizedBox(width: 4), Text('Solid Mesh', style: TextStyle(color: Colors.blue.withAlpha(179), fontSize: 8, fontWeight: FontWeight.w900))]),
                    ),
                  ],
                ),
                Row(children: [_buildViewButton(Icons.view_in_ar, 0), _buildViewButton(Icons.rotate_right, 1), _buildViewButton(Icons.view_agenda, 2)]),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: CustomPaint(painter: _LEGOIsometricPainter(studsX: _studsX, studsZ: _studsZ, color: _legoColor, viewAngle: _viewAngle), size: Size.infinite),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(IconData icon, int angle) {
    final isSelected = _viewAngle == angle;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: () => setState(() => _viewAngle = angle),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: isSelected ? const Color(0xFFef4444) : Colors.white.withAlpha(13), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.white.withAlpha(128)),
        ),
      ),
    );
  }

  Widget _buildDimensionsInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(child: _buildStatItem(Icons.straighten, 'Dimensions', '${_studsX * 8}x${_studsZ * 8}mm', '${HEIGHT.toStringAsFixed(1)}mm HEIGHT', const Color(0xFFef4444))),
          Expanded(child: _buildStatItem(Icons.polyline, 'Resolution', '${SEGMENTS} SEG', 'HIGH_POLY_ACTIVE', Colors.blue)),
          Expanded(child: _buildStatItem(Icons.speed, 'Status', 'OPTIMAL', 'SIM_CORE_v12', Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(color: color.withAlpha(13), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withAlpha(26))),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: Colors.white.withAlpha(77), fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 1)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
          Text(sub, style: TextStyle(color: Colors.white.withAlpha(77), fontSize: 7, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isExporting ? null : _exportSTL,
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFef4444), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        icon: _isExporting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.download, size: 20),
        label: Text(_isExporting ? 'EXPORTING...' : 'EXPORT STL', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 14)),
      ),
    );
  }

  Future<void> _exportSTL() async {
    setState(() => _isExporting = true);
    try {
      final stlData = _generateLEGO_STL();
      
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save LEGO STL',
        fileName: 'LEGO_${_studsX}x${_studsZ}.stl',
        type: FileType.custom,
        allowedExtensions: ['stl'],
      );

      if (outputFile == null) {
        setState(() => _isExporting = false);
        return;
      }

      // Ensure extension
      if (!outputFile.toLowerCase().endsWith('.stl')) {
        outputFile += '.stl';
      }

      final file = File(outputFile);
      await file.writeAsBytes(stlData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ LEGO saved to ${file.path.split('\\').last}'), 
            backgroundColor: const Color(0xFF00bcd4),
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Uint8List _generateLEGO_STL() {
    final List<double> vertices = [];
    final List<double> normals = [];

    // LEGO Dimensions in mm
    const double pitch = 8.0;
    const double brickH = 9.6;
    const double wallT = 1.2;
    const double ceilingT = 1.2;
    const double studR = 2.4;
    const double studH = 1.7;
    const double tubeOutR = 3.25;
    const double tubeInR = 2.4;

    final double bW = _studsX * pitch;
    final double bD = _studsZ * pitch;
    final double iH = brickH - ceilingT;

    void addTri(List<double> p1, List<double> p2, List<double> p3) {
      double ux = p2[0] - p1[0], uy = p2[1] - p1[1], uz = p2[2] - p1[2];
      double vx = p3[0] - p1[0], vy = p3[1] - p1[1], vz = p3[2] - p1[2];
      double nx = uy * vz - uz * vy;
      double ny = uz * vx - ux * vz;
      double nz = ux * vy - uy * vx;
      double l = math.sqrt(nx * nx + ny * ny + nz * nz);
      if (l > 0) { nx /= l; ny /= l; nz /= l; }
      vertices.addAll([...p1, ...p2, ...p3]);
      normals.addAll([nx, ny, nz, nx, ny, nz, nx, ny, nz]);
    }

    void addQuad(List<double> p1, List<double> p2, List<double> p3, List<double> p4) {
      addTri(p1, p2, p3);
      addTri(p1, p3, p4);
    }

    // 1. OUTER SHELL (Open Bottom)
    addQuad([0, 0, 0], [bW, 0, 0], [bW, 0, brickH], [0, 0, brickH]); // Front
    addQuad([bW, 0, 0], [bW, bD, 0], [bW, bD, brickH], [bW, 0, brickH]); // Right
    addQuad([bW, bD, 0], [0, bD, 0], [0, bD, brickH], [bW, bD, brickH]); // Back
    addQuad([0, bD, 0], [0, 0, 0], [0, 0, brickH], [0, bD, brickH]); // Left
    addQuad([0, 0, brickH], [bW, 0, brickH], [bW, bD, brickH], [0, bD, brickH]); // Top plate

    // 2. INNER CAVITY (Facing Inward)
    addQuad([wallT, wallT, 0], [wallT, wallT, iH], [bW - wallT, wallT, iH], [bW - wallT, wallT, 0]); // Inner Front
    addQuad([bW - wallT, wallT, 0], [bW - wallT, wallT, iH], [bW - wallT, bD - wallT, iH], [bW - wallT, bD - wallT, 0]); // Inner Right
    addQuad([bW - wallT, bD - wallT, 0], [bW - wallT, bD - wallT, iH], [wallT, bD - wallT, iH], [wallT, bD - wallT, 0]); // Inner Back
    addQuad([wallT, bD - wallT, 0], [wallT, bD - wallT, iH], [wallT, wallT, iH], [wallT, wallT, 0]); // Inner Left
    addQuad([wallT, wallT, iH], [wallT, bD - wallT, iH], [bW - wallT, bD - wallT, iH], [bW - wallT, wallT, iH]); // Inner Ceiling

    // 3. BOTTOM RIM (Seals outer and inner walls)
    addQuad([0, 0, 0], [wallT, wallT, 0], [bW - wallT, wallT, 0], [bW, 0, 0]);
    addQuad([bW, 0, 0], [bW - wallT, wallT, 0], [bW - wallT, bD - wallT, 0], [bW, bD, 0]);
    addQuad([bW, bD, 0], [bW - wallT, bD - wallT, 0], [wallT, bD - wallT, 0], [0, bD, 0]);
    addQuad([0, bD, 0], [wallT, bD - wallT, 0], [wallT, wallT, 0], [0, 0, 0]);

    // 4. STUDS (Closed Manifold Cylinders - Ultra High Res)
    for (int x = 0; x < _studsX; x++) {
      for (int y = 0; y < _studsZ; y++) {
        double cx = (x + 0.5) * pitch, cy = (y + 0.5) * pitch;
        const int segments = 64; // Increased resolution for maximum smoothness
        for (int i = 0; i < segments; i++) {
          double a1 = i * 2 * math.pi / segments, a2 = (i + 1) * 2 * math.pi / segments;
          double x1 = cx + studR * math.cos(a1), y1 = cy + studR * math.sin(a1);
          double x2 = cx + studR * math.cos(a2), y2 = cy + studR * math.sin(a2);
          addQuad([x1, y1, brickH], [x2, y2, brickH], [x2, y2, brickH + studH], [x1, y1, brickH + studH]); // Side
          addTri([cx, cy, brickH + studH], [x1, y1, brickH + studH], [x2, y2, brickH + studH]); // Top
          addTri([cx, cy, brickH], [x2, y2, brickH], [x1, y1, brickH]); // Bottom seal
        }
      }
    }

    // 5. COUPLING TUBES (Closed Manifold Hollow Cylinders - Ultra High Res)
    if (_studsX > 1 || _studsZ > 1) {
      double rO = (_studsX == 1 || _studsZ == 1) ? 1.5 : tubeOutR;
      double rI = (_studsX == 1 || _studsZ == 1) ? 0 : tubeInR;
      int tx = _studsX > 1 ? _studsX - 1 : 1, ty = _studsZ > 1 ? _studsZ - 1 : 1;
      const int segments = 64; // Increased resolution for maximum smoothness
      for (int x = 0; x < tx; x++) {
        for (int y = 0; y < ty; y++) {
          double cx = _studsX > 1 ? (x + 1) * pitch : pitch / 2, cy = _studsZ > 1 ? (y + 1) * pitch : pitch / 2;
          for (int i = 0; i < segments; i++) {
            double a1 = i * 2 * math.pi / segments, a2 = (i + 1) * 2 * math.pi / segments;
            double x1o = cx + rO * math.cos(a1), y1o = cy + rO * math.sin(a1);
            double x2o = cx + rO * math.cos(a2), y2o = cy + rO * math.sin(a2);
            addQuad([x1o, y1o, 0], [x2o, y2o, 0], [x2o, y2o, iH], [x1o, y1o, iH]); // Outer
            if (rI > 0) {
              double x1i = cx + rI * math.cos(a1), y1i = cy + rI * math.sin(a1);
              double x2i = cx + rI * math.cos(a2), y2i = cy + rI * math.sin(a2);
              addQuad([x1i, y1i, 0], [x1i, y1i, iH], [x2i, y2i, iH], [x2i, y2i, 0]); // Inner
              addQuad([x1o, y1o, 0], [x1i, y1i, 0], [x2i, y2i, 0], [x2o, y2o, 0]); // Bottom Ring
              addQuad([x1o, y1o, iH], [x2o, y2o, iH], [x2i, y2i, iH], [x1i, y1i, iH]); // Top Ring
            } else {
              addTri([cx, cy, iH], [x1o, y1o, iH], [x2o, y2o, iH]); // Pin Top
              addTri([cx, cy, 0], [x2o, y2o, 0], [x1o, y1o, 0]); // Pin Bottom
            }
          }
        }
      }
    }

    return _createSTLBinary(vertices, normals);
  }

  Uint8List _createSTLBinary(List<double> vertices, List<double> normals) {
    final triangleCount = vertices.length ~/ 9;
    final buffer = ByteData(84 + triangleCount * 50);
    
    for (int i = 0; i < 80; i++) buffer.setUint8(i, 0);
    buffer.setUint32(80, triangleCount, Endian.little);
    
    int offset = 84;
    for (int t = 0; t < triangleCount; t++) {
      buffer.setFloat32(offset, normals[t * 9], Endian.little); offset += 4;
      buffer.setFloat32(offset, normals[t * 9 + 1], Endian.little); offset += 4;
      buffer.setFloat32(offset, normals[t * 9 + 2], Endian.little); offset += 4;
      
      for (int v = 0; v < 3; v++) {
        buffer.setFloat32(offset, vertices[t * 9 + v * 3], Endian.little); offset += 4;
        buffer.setFloat32(offset, vertices[t * 9 + v * 3 + 1], Endian.little); offset += 4;
        buffer.setFloat32(offset, vertices[t * 9 + v * 3 + 2], Endian.little); offset += 4;
      }
      buffer.setUint16(offset, 0, Endian.little); offset += 2;
    }
    return buffer.buffer.asUint8List();
  }
}

class _LEGOIsometricPainter extends CustomPainter {
  final int studsX;
  final int studsZ;
  final Color color;
  final int viewAngle;

  _LEGOIsometricPainter({required this.studsX, required this.studsZ, required this.color, required this.viewAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final darkPaint = Paint()..color = HSLColor.fromColor(color).withLightness((HSLColor.fromColor(color).lightness - 0.15).clamp(0, 1)).toColor();
    final lightPaint = Paint()..color = HSLColor.fromColor(color).withLightness((HSLColor.fromColor(color).lightness + 0.1).clamp(0, 1)).toColor();
    final borderPaint = Paint()..color = Colors.black.withAlpha(50)..style = PaintingStyle.stroke..strokeWidth = 0.5;

    final double unit = 12.0; // Scale for preview
    final double w = studsX * unit;
    final double d = studsZ * unit;
    final double h = 1.2 * unit;

    // Simple isometric projection
    Offset project(double x, double y, double z) {
      // Angle and rotation
      double angle = viewAngle * math.pi / 180;
      double rx = x * math.cos(angle) - z * math.sin(angle);
      double rz = x * math.sin(angle) + z * math.cos(angle);
      
      return Offset(
        size.width / 2 + (rx - rz) * 0.866,
        size.height / 2 + (rx + rz) * 0.5 - y
      );
    }

    void drawFace(List<Offset> pts, Paint p) {
      final path = Path()..addPolygon(pts, true);
      canvas.drawPath(path, p);
      canvas.drawPath(path, borderPaint);
    }

    // Brick corners
    final p1 = project(0, 0, 0);
    final p2 = project(w, 0, 0);
    final p3 = project(w, 0, d);
    final p4 = project(0, 0, d);
    final p5 = project(0, h, 0);
    final p6 = project(w, h, 0);
    final p7 = project(w, h, d);
    final p8 = project(0, h, d);

    // Draw bottom/back faces first (simplified)
    drawFace([p1, p2, p6, p5], darkPaint); // Side 1
    drawFace([p2, p3, p7, p6], darkPaint); // Side 2
    drawFace([p3, p4, p8, p7], darkPaint); // Side 3
    drawFace([p4, p1, p5, p8], darkPaint); // Side 4
    drawFace([p5, p6, p7, p8], lightPaint); // Top

    // Draw studs
    for (int ix = 0; ix < studsX; ix++) {
      for (int iz = 0; iz < studsZ; iz++) {
        final cx = (ix + 0.5) * unit;
        final cz = (iz + 0.5) * unit;
        final double sr = unit * 0.3;
        final double sh = unit * 0.2;
        
        final s1 = project(cx - sr, h, cz - sr);
        final s2 = project(cx + sr, h, cz - sr);
        final s3 = project(cx + sr, h, cz + sr);
        final s4 = project(cx - sr, h, cz + sr);
        final s5 = project(cx - sr, h + sh, cz - sr);
        final s6 = project(cx + sr, h + sh, cz - sr);
        final s7 = project(cx + sr, h + sh, cz + sr);
        final s8 = project(cx - sr, h + sh, cz + sr);

        drawFace([s1, s2, s6, s5], paint);
        drawFace([s2, s3, s7, s6], paint);
        drawFace([s5, s6, s7, s8], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _UpdateDownloadDialog extends StatefulWidget {
  final String url;
  final String message;

  const _UpdateDownloadDialog({required this.url, required this.message});

  @override
  State<_UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}

class _UpdateDownloadDialogState extends State<_UpdateDownloadDialog> {
  String _status = 'Bereit zum Download...';
  double _progress = 0;
  bool _downloading = false;
  bool _downloaded = false;
  String? _error;

  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _status = 'Download wird gestartet...';
    });

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.url));
      final response = await client.send(request);
      
      final contentLength = response.contentLength ?? 0;
      final received = <int>[];
      
      await for (final chunk in response.stream) {
        received.addAll(chunk);
        if (contentLength > 0) {
          setState(() {
            _progress = received.length / contentLength;
            _status = 'Download: ${(_progress * 100).toStringAsFixed(0)}%';
          });
        }
      }
      
      if (mounted) {
        setState(() {
          _downloading = false;
          _downloaded = true;
          _progress = 1.0;
          _status = 'Download abgeschlossen!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = e.toString();
          _status = 'Fehler: $e';
        });
      }
    }
  }

  Future<void> _openDownload() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konnte Download nicht öffnen')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E2E),
      title: Row(
        children: [
          Icon(
            _downloaded ? Icons.check_circle : Icons.system_update, 
            color: _downloaded ? Colors.green : const Color(0xFF00BCD4)
          ),
          const SizedBox(width: 8),
          Text(
            _downloaded ? 'Update bereit' : 'Update verfügbar', 
            style: const TextStyle(color: Colors.white)
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          if (_downloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF00BCD4)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              if (_downloading)
                const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00BCD4),
                  ),
                )
              else if (_downloaded)
                const Icon(Icons.check, color: Colors.green, size: 16)
              else if (_error != null)
                const Icon(Icons.error, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _status,
                  style: TextStyle(
                    color: _error != null ? Colors.red : const Color(0xFF00BCD4),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (_downloaded) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withAlpha(77)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nach dem Öffnen wirst du gefragt, ob du die APK installieren möchtest.',
                      style: TextStyle(color: Colors.orange, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!_downloaded) ...[
          TextButton(
            onPressed: _downloading ? null : () => Navigator.pop(context),
            child: Text(
              _downloading ? 'Warte...' : 'Abbrechen', 
              style: const TextStyle(color: Colors.white54)
            ),
          ),
          FilledButton(
            onPressed: _downloading ? null : _startDownload,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00BCD4)),
            child: const Text('Download starten'),
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _openDownload();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Jetzt installieren'),
          ),
        ],
      ],
    );
  }
}