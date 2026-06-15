import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/questao_model.dart';
import '../../data/models/historico_model.dart';

/// 📚 PROVIDER PARA BUSCAR QUESTÕES DO FIRESTORE
/// Otimizado para 50 acessos simultâneos usando filtragem indexada
final listaQuestoesFirestoreProvider = StreamProvider.family<List<QuestaoModel>, String>((ref, instituicaoId) {
  return FirebaseFirestore.instance
      .collection('questoes')
      .where('instituicaoId', isEqualTo: instituicaoId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return QuestaoModel(
              id: doc.id,
              pergunta: data['pergunta'] ?? data['enunciado'] ?? 'Sem pergunta',
              opcoes: List<String>.from(data['opcoes'] ?? []),
              respostaCorretaIndex: data['respostaCorretaIndex'] ?? 0,
              instituicaoId: data['instituicaoId'] ?? '',
              categoriaId: data['categoriaId'] ?? '',
              assuntoId: data['assuntoId'] ?? '',
            );
          }).toList());
});

/// 📜 PROVIDER PARA O HISTÓRICO DE SIMULADOS
/// 📉 OTIMIZADO PARA PLANO GRATUITO: Acessa direto a subcoleção do usuário logado,
/// eliminando a necessidade de CollectionGroup e reduzindo drasticamente as leituras do banco.
final historicoSimuladosProvider = StreamProvider<List<HistoricoModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('usuarios')
      .doc(user.uid)
      .collection('historico_simulados') // 👈 Rota linear direta do usuário
      .orderBy('dataConclusao', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            
            final dataConclusaoRaw = data['dataConclusao'];
            final DateTime dataFinal = dataConclusaoRaw is Timestamp 
                ? dataConclusaoRaw.toDate() 
                : DateTime.now();

            return HistoricoModel(
              id: doc.id,
              userId: data['userId'] ?? '',
              instituicaoId: data['instituicaoId'] ?? '',
              categoria: data['categoria'] ?? '',
              tipoProva: data['tipoProva'] ?? 'Completa',
              assunto: data['assunto'],
              totalQuestoes: data['totalQuestoes'] ?? 0,
              acertos: data['acertos'] ?? 0,
              erros: data['erros'] ?? 0,
              pontosProva: (data['pontosProva'] as num?)?.toDouble() ?? 0.0,
              pontosGamificacao: data['pontosGamificacao'] ?? 0,
              dataConclusao: dataFinal,
              // Mantém compatibilidade com a listaRevisaoJson ou revisaoQuestoes
              revisaoQuestoes: List<Map<String, dynamic>>.from(
                data['revisaoQuestoes'] ?? data['listaRevisaoJson'] ?? []
              ),
            );
          }).toList());
});

/// 🚀 PROVIDER ADICIONAL: FUNÇÃO DE ENVIO/GRAVAÇÃO DO SIMULADO NO HISTÓRICO
/// Chame esta função usando ref.read(salvarSimuladoProvider)(...) ao clicar em finalizar o quiz.
final salvarSimuladoProvider = Provider((ref) {
  return ({
    required String userId,
    required String instituicaoId,
    required String categoria,
    required int acertos,
    required int totalQuestoes,
    required List<Map<String, dynamic>> listaRevisaoJson,
  }) async {
    final DocumentReference docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('historico_simulados')
        .doc();

    final dadosSimulado = {
      'id': docRef.id,
      'userId': userId,
      'instituicaoId': instituicaoId,
      'categoria': categoria,
      'assunto': categoria,
      'tipoProva': 'Simulado Dinâmico',
      'acertos': acertos,
      'erros': totalQuestoes - acertos,
      'totalQuestoes': totalQuestoes,
      'pontosGamificacao': acertos * 10, 
      'pontosProva': acertos.toDouble(), 
      'dataConclusao': FieldValue.serverTimestamp(), 
      'revisaoQuestoes': listaRevisaoJson, 
    };

    await docRef.set(dadosSimulado);
  };
});