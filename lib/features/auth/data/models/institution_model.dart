import 'package:cloud_firestore/cloud_firestore.dart';

class InstitutionModel {
  final String id;
  final String nome;
  final String plano;
  final String? corCustomizada;
  final String? primaryColorHex;
  final String? logoUrl;
  final String? logo;
  final List<String> patrocinadores;

  InstitutionModel({
    required this.id,
    required this.nome,
    required this.plano,
    this.corCustomizada,
    this.primaryColorHex,
    this.logoUrl,
    this.logo,
    this.patrocinadores = const [],
  });

  // Transforma o documento do Firestore em um objeto do Flutter mapeando os campos visuais
  factory InstitutionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Tratamento seguro para converter a lista dinâmica do Firestore em uma List<String>
    final listaPatrocinadoresRaw = data['patrocinadores'] as List<dynamic>? ?? [];
    final List<String> patrocinadoresTratados = listaPatrocinadoresRaw
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();

    // Consolidação inteligente do link da imagem
    final stringLogoUrl = data['logoUrl']?.toString() ?? data['logo']?.toString();

    return InstitutionModel(
      id: doc.id, // Pega o identificador do documento (ex: 'ulbra-01')
      nome: data['nome'] ?? '',
      plano: data['plano'] ?? 'Gratuito',
      corCustomizada: data['corCustomizada']?.toString(),
      primaryColorHex: data['primaryColorHex']?.toString(),
      logoUrl: stringLogoUrl,
      logo: stringLogoUrl,
      patrocinadores: patrocinadoresTratados,
    );
  }
}