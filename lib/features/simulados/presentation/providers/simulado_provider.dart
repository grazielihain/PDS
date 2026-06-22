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
/// 📉 OTIMIZADO: Ajustado para ler as chaves corretas sincronizadas com o controller e índices.
final historicoSimuladosProvider = StreamProvider<List<HistoricoModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('usuarios')
      .doc(user.uid)
      .collection('historico_simulados') 
      .orderBy('dataHora', descending: true) // 🔥 CORRIGIDO: De 'dataConclusao' para 'dataHora' (Bate com o Índice composto)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            
            // 🔥 CORRIGIDO: Lendo o campo unificado 'dataHora' do Firestore
            final dataHoraRaw = data['dataHora'] ?? data['dataConclusao'];
            final DateTime dataFinal = dataHoraRaw is Timestamp 
                ? dataHoraRaw.toDate() 
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
              // 🔥 CORRIGIDO: Lendo de 'notaObtida' conforme o novo padrão do banco
              pontosProva: (data['notaObtida'] ?? data['pontosProva'] as num?)?.toDouble() ?? 0.0,
              pontosGamificacao: data['pontosGamificacao'] ?? 0,
              dataConclusao: dataFinal,
              revisaoQuestoes: List<Map<String, dynamic>>.from(
                data['revisaoQuestoes'] ?? data['listaRevisaoJson'] ?? []
              ),
            );
          }).toList());
});

/// 🚀 PROVIDER ADICIONAL: FUNÇÃO DE ENVIO/GRAVAÇÃO DO SIMULADO NO HISTÓRICO
/// 🔥 ATUALIZADO: Sincronizado com os mesmos campos padrão do SimuladoController para não quebrar o banco.
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
        .doc(userId.isEmpty ? 'anonimo' : userId)
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
      'pontosGamificacao': 10, // Mantido bônus fixo da regra de gamificação
      'notaObtida': acertos.toDouble(), // 🔥 CORRIGIDO: De 'pontosProva' para 'notaObtida'
      'dataHora': FieldValue.serverTimestamp(), // 🔥 CORRIGIDO: De 'dataConclusao' para 'dataHora'
      'revisaoQuestoes': listaRevisaoJson, 
    };

    await docRef.set(dadosSimulado);
  };
});
