import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/messaging_service.dart';
import 'theme/app_theme.dart';
import 'screens/sign_in_screen.dart';
import 'screens/shell_screen.dart';

const bool _useEmulator =
    bool.fromEnvironment('USE_EMULATOR', defaultValue: false);

String get _emulatorHost {
  if (_useEmulator && defaultTargetPlatform == TargetPlatform.android) {
    return '10.0.2.2';
  }
  return 'localhost';
}

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await Firebase.initializeApp(
    options: _useEmulator
        ? const FirebaseOptions(
            apiKey: 'demo-key',
            appId: '1:0:android:demo',
            messagingSenderId: '0',
            projectId: 'demo-mle',
          )
        : DefaultFirebaseOptions.currentPlatform,
  );

  if (_useEmulator) {
    final host = _emulatorHost;
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  } else {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      MessagingService().init(user.uid);
    }
  }

  FlutterNativeSplash.remove();
  runApp(const MleApp());
}

class MleApp extends StatelessWidget {
  const MleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<AuthService>(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'MLE',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.hasData ? const ShellScreen() : const SignInScreen();
      },
    );
  }
}
