import 'package:flutter/material.dart';
import 'package:flutter_run_tracker_app/views/show_all_run_ui.dart';

class SplashScreenUI extends StatefulWidget {
  const SplashScreenUI({super.key});
  @override
  State<SplashScreenUI> createState() => _SplashScreenUIState();
}

class _SplashScreenUIState extends State<SplashScreenUI> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ShowAllRunUI()));
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color.fromARGB(255, 5, 1, 80),
        body: Stack(children: [
          Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Image.asset('assests/images/logo.png',
                    width: MediaQuery.of(context).size.width * .45,
                    height: MediaQuery.of(context).size.width * .45,
                    fit: BoxFit.cover),
                Text('Run Tracker',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.height * .038,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic)),
                const SizedBox(height: 50),
                const CircularProgressIndicator(color: Colors.white),
              ])),
          Center(
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text('Copyright © 2026 RUN TRACKER',
                style: TextStyle(
                    color: const Color.fromARGB(158, 153, 152, 152),
                    fontSize: MediaQuery.of(context).size.height * .02)),
            Text('Created by NBEST SAU TEAM',
                style: TextStyle(
                    color: const Color.fromARGB(158, 153, 152, 152),
                    fontSize: MediaQuery.of(context).size.height * .02)),
            const SizedBox(height: 50),
          ])),
        ]),
      );
}
