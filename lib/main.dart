import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase com as configurações automáticas geradas
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Envolvemos o MyApp dentro de um ProviderScope para habilitar o Riverpod globalmente
  runApp(const ProviderScope(child: MyApp()));
}

// Convertido para ConsumerWidget para escutar as mudanças do routerProvider de forma limpa
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Rumo Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, 
        primarySwatch: Colors.blue,
      ),
      routerConfig: goRouter,
    );
  }
}

