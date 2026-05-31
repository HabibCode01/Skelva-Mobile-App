import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'splash_screen.dart';
// import 'populate_firebase.dart'; // Keep commented out if not using

void main() async {
  // 1. Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase (Wrap in try-catch)
  try {
    await Firebase.initializeApp();
    print("✅ Firebase Initialized");
  } catch (e) {
    print("❌ Firebase Failed: $e");
  }

  // 3. Initialize Stripe (CRITICAL: Wrap in try-catch)
  try {
    Stripe.publishableKey = 'pk_test_51Sp2U10zC4OvPu7nnmjR5kTFPzUx8LlzU6eKm5e9WWa2NBCbb9sr2mLWCy7vfBtDk3XVngVeANv2YqIr4vVw4l9S004pbsgoUM';
    await Stripe.instance.applySettings();
    print("✅ Stripe Initialized");
  } catch (e) {
    print("❌ Stripe Initialization Failed: $e");
    // The app will continue even if this fails!
  }

  // 4. Run the App (This draws the UI)
  runApp(const SkelvaApp());
}

class SkelvaApp extends StatelessWidget {
  const SkelvaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => "Skelva Config"),
      ],
      child: MaterialApp(
        title: 'Skelva',
        debugShowCheckedModeBanner: false,

        // Global Theme
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Helvetica Rounded',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF335D61),
            primary: const Color(0xFF335D61),
            secondary: const Color(0xFFEF963B),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF963B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            labelStyle: TextStyle(fontSize: 12, color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFF335D61), width: 2),
            ),
          ),
        ),

        // Localization
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('ms', ''),
        ],

        home: const SplashScreen(),
      ),
    );
  }
}