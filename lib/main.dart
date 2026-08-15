import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FlutterFire reemplaza esta inicializacion por DefaultFirebaseOptions
  // despues de ejecutar `flutterfire configure`. No se incluyen credenciales.
  await Firebase.initializeApp();

  runApp(const ProviderScope(child: App()));
}
