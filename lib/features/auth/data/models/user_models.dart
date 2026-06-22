import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    required super.institutionId,
  });

  /// Converte um documento do Firebase Firestore em um UserModel (Leitura do Banco)
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    // Captura os dados brutos do documento NoSQL como um Mapa de Chave e Valor
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception("Dados do usuário não encontrados no Firestore!");
    }

    return UserModel(
      id: doc.id, // O ID vem diretamente do identificador do documento
      name: data['nome'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'Acess3', // Se não houver role, padroniza como Aluno
      institutionId: data['instituicaoId'] ?? '',
    );
  }

  /// Converte o modelo em JSON para ser gravado na nuvem 
  Map<String, dynamic> toFirestore() {
    return {
      'nome': name,
      'email': email,
      'role': role,
      'instituicaoId': institutionId,
    };
  }
}
