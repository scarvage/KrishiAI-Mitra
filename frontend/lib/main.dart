import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'providers/disease_provider.dart';
import 'providers/language_provider.dart';
import 'providers/mandi_provider.dart';
import 'providers/voice_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/disease_screen.dart';
import 'screens/mandi_screen.dart';
import 'screens/voice_chat_screen.dart';
import 'utils/app_colors.dart';
import 'widgets/language_selection_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final languageProvider = LanguageProvider();
  await languageProvider.init();

  final voiceProvider = VoiceProvider();
  final diseaseProvider = DiseaseProvider();
  final mandiProvider = MandiProvider()..loadPrices();

  // Sync all feature providers whenever the global language changes.
  void syncLanguage() {
    final code = languageProvider.languageCode;
    voiceProvider.setLanguage(code);
    diseaseProvider.setLanguage(code);
    mandiProvider.setLanguage(code);
  }

  // Apply saved language on startup.
  syncLanguage();
  languageProvider.addListener(syncLanguage);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
        ChangeNotifierProvider<VoiceProvider>.value(value: voiceProvider),
        ChangeNotifierProvider<DiseaseProvider>.value(value: diseaseProvider),
        ChangeNotifierProvider<MandiProvider>.value(value: mandiProvider),
      ],
      child: const KrishiMitraApp(),
    ),
  );
}

class KrishiMitraApp extends StatelessWidget {
  const KrishiMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Krishi Mitra | कृषि मित्र',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    VoiceChatScreen(),
    DiseaseScreen(),
    MandiScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLanguageSetup());
  }

  void _checkLanguageSetup() {
    final provider = context.read<LanguageProvider>();
    if (!provider.isLanguageSet) {
      LanguageSelectionDialog.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'होम',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_rounded),
            label: 'आवाज़',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_rounded),
            label: 'रोग',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_rounded),
            label: 'मंडी',
          ),
        ],
      ),
    );
  }
}
