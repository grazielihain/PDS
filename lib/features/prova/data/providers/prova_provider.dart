import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/prova_model.dart';

// Provider busca as provas filtradas pela instituição em tempo real
final listaProvasProvider = StreamProvider.family<List<ProvaModel>, String>((
  ref,
  instituicaoId,
) {
  final firestore = FirebaseFirestore.instance;

  // O .trim() limpa qualquer espaço em branco invisível que possa ter vindo do banco
  final idFiltrado = instituicaoId.trim();

  return firestore
      .collection('provas')
      .where(
        'instituicaoId',
        isEqualTo: idFiltrado,
      ) // O filtro White Label voltou!
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => ProvaModel.fromFirestore(doc.data(), doc.id))
            .toList();
      });
});
