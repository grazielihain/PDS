import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/questao_model.dart';
import '../../data/models/historico_model.dart';

/// 📚 PROVIDER PARA BUSCAR QUESTÕES DO FIRESTORE
final listaQuestoesFirestoreProvider = StreamProvider.family<List<QuestaoModel>, String>((ref, instituicaoId) {
  return FirebaseFirestore.instance
      .collection('questoes')
      .where('instituicaoId', isEqualTo: instituicaoId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            // 🛠️ Mapeamento manual para suprir a falta do .fromFirestore
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
final historicoSimuladosProvider = StreamProvider<List<HistoricoModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  // 🛠️ Atualizado os filtros de 'alunoId' para 'userId' e 'dataHora' para 'dataConclusao'
  return FirebaseFirestore.instance
      .collectionGroup('historico_simulados') // Busca em todas as subcoleções de históricos
      .where('userId', isEqualTo: user.uid)
      .orderBy('dataConclusao', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            
            // Tratamento seguro da data vinda como Timestamp do Firebase
            final dataConclusaoRaw = data['dataConclusao'];
            final DateTime dataFinal = dataConclusaoRaw is Timestamp 
                ? dataConclusaoRaw.toDate() 
                : DateTime.now();

            // 🛠️ Mapeamento manual para suprir a falta do .fromFirestore
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
              revisaoQuestoes: List<Map<String, dynamic>>.from(data['revisaoQuestoes'] ?? []),
            );
          }).toList());
});