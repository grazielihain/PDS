import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FirebaseConfig {
  /// Inicializa o Firebase SDK com suporte a Cache Offline agressivo para o Plano Grátis
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Inicializa o Firebase baseado nas configurações do FlutterFire CLI
    await Firebase.initializeApp();

    // Configura o Firestore para cache local ilimitado (evita estourar limite de Reads de 50 usuários)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true, 
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    debugPrint('[Firebase] Inicializado com sucesso. Proteção do plano gratuito ativa via cache offline.');
  }
}