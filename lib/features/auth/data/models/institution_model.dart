import 'package:cloud_firestore/cloud_firestore.dart';

class InstitutionModel {
  final String id;
  final String nome;
  final String plano;

  InstitutionModel({
    required this.id,
    required this.nome,
    required this.plano,
  });

  // Transforma o documento do Firestore em um objeto do Flutter
  factory InstitutionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InstitutionModel(
      id: doc.id, // Pega o nome do documento (ex: 'ulbra-01')
      nome: data['nome'] ?? '',
      plano: data['plano'] ?? 'Gratuito',
    );
  }
}