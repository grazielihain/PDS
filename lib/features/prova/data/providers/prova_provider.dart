import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/prova_model.dart';
import '../../domain/models/questao_model.dart';
import '../../domain/models/historico_model.dart';

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

// Provider que busca as questões da subcoleção de uma prova específica
final listaQuestoesProvider = FutureProvider.family<List<QuestaoModel>, String>(
  (ref, provaId) async {
    final firestore = FirebaseFirestore.instance;

    final snapshot = await firestore
        .collection('provas')
        .doc(provaId)
        .collection('questoes')
        .get();

    return snapshot.docs
        .map((doc) => QuestaoModel.fromFirestore(doc.data(), doc.id))
        .toList();
  },
);

// Provider que expõe a função de salvar o histórico no banco
final salvarHistoricoProvider = Provider((ref) {
  return (HistoricoModel historico) async {
    final firestore = FirebaseFirestore.instance;

    // Cria uma nova coleção chamada 'historicos' e adiciona o documento
    await firestore.collection('historicos').add(historico.toFirestore());
  };
});

// Provider que escuta o histórico do aluno logado em tempo real
final streamHistoricoAlunoProvider = StreamProvider<List<HistoricoModel>>((ref) {
  final firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return Stream.value([]); // Retorna uma lista vazia se não houver usuário logado
  }

  // CORREÇÃO DA SINTAXE: Trocado '==:' por 'isEqualTo:'
  return firestore
      .collection('historicos')
      .where('alunoId', isEqualTo: user.uid)
      .orderBy('dataHora', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => HistoricoModel.fromFirestore(doc.data(), doc.id))
          .toList());
});

