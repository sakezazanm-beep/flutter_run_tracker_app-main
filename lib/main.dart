import 'package:flutter/material.dart';
import 'package:flutter_run_tracker_app/views/splash_screen_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://uwigqerryxiutssebgez.supabase.co';
const supabasePublishableKey = 'sb_publishable_2mlRuOzWJUioWXE3p_LKrw_0BlT5QBs';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
      url: supabaseUrl, publishableKey: supabasePublishableKey);
  runApp(const FlutterRunTrackerApp());
}

class FlutterRunTrackerApp extends StatelessWidget {
  const FlutterRunTrackerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Run Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff090150)),
          scaffoldBackgroundColor: const Color(0xfff7f7fb),
          textTheme: TextTheme.of(context).apply(
              fontFamily: GoogleFonts.kanit().fontFamily,
              fontFamilyFallback: GoogleFonts.kanit().fontFamilyFallback),
          appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xff090150),
              foregroundColor: Colors.white,
              centerTitle: true),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xffe5e5ee))),
          ),
          useMaterial3: true,
        ),
        home: const SplashScreenUI(),
      );
}
