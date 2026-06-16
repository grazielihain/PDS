import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FirebaseConfig {
  /// Inicializa o Firebase SDK com suporte a Cache Offline para proteção da cota gratuita
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Inicializa o Firebase baseado nas configurações geradas pelo FlutterFire CLI
    await Firebase.initializeApp();

    // Configura o Firestore para priorizar o cache local e economizar leituras (Plano Grátis)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled:
          true, // Ativa a persistência offline em Web, Android e iOS
      cacheSizeBytes:
          Settings.CACHE_SIZE_UNLIMITED, // Sem limite rígido de cache local
    );

    debugPrint(
      '🚀 [Firebase] Inicializado com sucesso e cache offline ativado.',
    );
  }
}
