import 'package:cloud_firestore/cloud_firestore.dart';

class InstitutionModel {
  final String id;
  final String nome;
  final String plano;
  final String corHexadecimal;
  final String logoUrl;
  final List<String> patrocinadoresUrls;

  InstitutionModel({
    required this.id,
    required this.nome,
    required this.plano,
    required this.corHexadecimal,
    required this.logoUrl,
    required this.patrocinadoresUrls,
  });

  factory InstitutionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InstitutionModel(
      id: doc.id,
      nome: data['nome'] ?? '',
      plano: data['plano'] ?? 'Gratuito',
      corHexadecimal:
          (data['corHexadecimal'] ?? data['corHex'])?.toString() ?? '#1E88E5',
      logoUrl: data['logoUrl']?.toString() ?? '',
      patrocinadoresUrls: List<String>.from(
        data['patrocinadoresUrls'] ?? data['patrocinios'] ?? [],
      ),
    );
  }
}
