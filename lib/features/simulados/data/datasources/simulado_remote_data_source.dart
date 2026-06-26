import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/questao_model.dart';

final simuladoDataSourceProvider = Provider<SimuladoRemoteDataSource>((ref) {
  return SimuladoRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
});

class ResultadoMetaModel {
  final String nome;
  final String mensagem;
  final String instituicao;
  final String? logoUrl;
  final String? imagemUrlMensagem;

  const ResultadoMetaModel({
    required this.nome,
    required this.mensagem,
    required this.instituicao,
    this.logoUrl,
    this.imagemUrlMensagem,
  });
}

// Estatísticas da tela inicial do aluno (quiz_selection_page)
class DashboardAlunoModel {
  final String nome;
  final int provasConcluidas;
  final double pontosAcumulados;
  final double taxaAcerto;
  final double tempoMedioAssuntoMin;
  final double tempoMedioCompletaMin;

  const DashboardAlunoModel({
    required this.nome,
    required this.provasConcluidas,
    required this.pontosAcumulados,
    required this.taxaAcerto,
    required this.tempoMedioAssuntoMin,
    required this.tempoMedioCompletaMin,
  });

  static const empty = DashboardAlunoModel(
    nome: 'Estudante',
    provasConcluidas: 0,
    pontosAcumulados: 0,
    taxaAcerto: 0,
    tempoMedioAssuntoMin: 0,
    tempoMedioCompletaMin: 0,
  );
}

abstract class SimuladoRemoteDataSource {
  Future<List<QuestaoModel>> buscarQuestoesPorFiltro({
    required String institutionId,
    required String categoriaId,
    String? assuntoId,
  });

  Future<ResultadoMetaModel> buscarMetaResultado({
    required String? uid,
    required String? instituicaoId,
    required double taxaAcerto,
    required String nomeFallback,
    required String instituicaoFallback,
    String? logoFallback,
  });

  /// Retorna o instituicaoId do usuário autenticado.
  Future<String?> buscarInstituicaoIdDoUsuario(String uid);

  /// Retorna [{id, nome}] de categorias da instituição, ordenado por nome.
  Future<List<Map<String, dynamic>>> buscarCategoriasInstituicao(
      String instituicaoId);

  /// Retorna [{id, modo, quantidadeMaxima}] de tipos de simulado da categoria.
  Future<List<Map<String, dynamic>>> buscarTiposSimuladoCategoria({
    required String categoriaId,
    required String instituicaoId,
  });

  /// Retorna [{id, nome}] de assuntos da categoria, ordenado por nome.
  Future<List<Map<String, dynamic>>> buscarAssuntosCategoria({
    required String categoriaId,
    required String instituicaoId,
  });

  /// Retorna estatísticas agregadas do histórico de simulados do aluno.
  Future<DashboardAlunoModel> buscarDashboardAluno(String uid);
}

// 🟢 O GARÇOM (DataSource): Vai no Firebase e traz as questões da escola certa
class SimuladoRemoteDataSourceImpl implements SimuladoRemoteDataSource {
  final FirebaseFirestore _firestore;

  SimuladoRemoteDataSourceImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  @override
  Future<List<QuestaoModel>> buscarQuestoesPorFiltro({
    required String institutionId,
    required String categoriaId,
    String? assuntoId,
  }) async {
    try {
      // 1. Iniciamos a query filtrando estritamente pela Instituição e pela Categoria selecionada
      // Nota: Mantemos o mapeamento exato de chaves do seu banco NoSQL desnormalizado (Sprint 2)
      Query query = _firestore
          .collection('questoes')
          .where('instituicaoId', isEqualTo: institutionId)
          .where('categoriaId', isEqualTo: categoriaId);

      // 2. Se o usuário (Acess3) escolheu uma prova "Por Assunto", filtramos também pelo assunto específico
      if (assuntoId != null && assuntoId.isNotEmpty) {
        query = query.where('assuntoId', isEqualTo: assuntoId);
      }

      // ⏱️ Forçamos um limite de 5 segundos. Se o Firebase congelar, ele cancela e avisa!
      final QuerySnapshot querySnapshot = await query.get().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception(
          'O Firebase demorou muito para responder! Verifique se a instituição e categorias existem no banco.',
        ),
      );

      // 3. Converte os documentos recebidos em lote único para o modelo estruturado QuestaoModel
      return querySnapshot.docs
          .map((doc) => QuestaoModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar as questões do simulado no banco: $e');
    }
  }

  @override
  Future<ResultadoMetaModel> buscarMetaResultado({
    required String? uid,
    required String? instituicaoId,
    required double taxaAcerto,
    required String nomeFallback,
    required String instituicaoFallback,
    String? logoFallback,
  }) async {
    String nome = nomeFallback;
    String mensagem = '';
    String instituicao = instituicaoFallback;
    String? logoUrl = logoFallback;
    String? imagemUrlMensagem;

    if (uid == null) {
      return ResultadoMetaModel(
        nome: nome,
        mensagem: mensagem,
        instituicao: instituicao,
        logoUrl: logoUrl,
        imagemUrlMensagem: imagemUrlMensagem,
      );
    }

    try {
      final userDoc = await _firestore.collection('usuarios').doc(uid).get();
      final userData = userDoc.data() ?? {};
      nome = userData['nome'] as String? ?? nome;

      final instId = (instituicaoId?.isNotEmpty == true)
          ? instituicaoId!
          : userData['instituicaoId'] as String? ?? '';

      if (instId.isNotEmpty) {
        final results = await Future.wait([
          _firestore
              .collection('mensagens_resultado')
              .where('instituicaoId', isEqualTo: instId)
              .get(),
          _firestore.collection('instituicoes').doc(instId).get(),
        ]);

        final msgSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
        for (final doc in msgSnap.docs) {
          final md = doc.data();
          final de = (md['de'] as num? ?? 0).toDouble();
          final ate = (md['ate'] as num? ?? 100).toDouble();
          if (taxaAcerto >= de && taxaAcerto <= ate) {
            mensagem = md['texto'] as String? ?? '';
            imagemUrlMensagem = md['imagemUrl'] as String?;
            break;
          }
        }

        final instDoc = results[1] as DocumentSnapshot<Map<String, dynamic>>;
        if (instDoc.exists) {
          final instData = instDoc.data() ?? {};
          if (instituicao == 'Minha Instituição') {
            instituicao = instData['nome'] as String? ?? instituicao;
          }
          logoUrl ??= instData['logoUrl'] as String?;
        }
      }
    } catch (_) {}

    return ResultadoMetaModel(
      nome: nome,
      mensagem: mensagem,
      instituicao: instituicao,
      logoUrl: logoUrl,
      imagemUrlMensagem: imagemUrlMensagem,
    );
  }

  @override
  Future<String?> buscarInstituicaoIdDoUsuario(String uid) async {
    final doc = await _firestore.collection('usuarios').doc(uid).get();
    return doc.data()?['instituicaoId'] as String?;
  }

  @override
  Future<List<Map<String, dynamic>>> buscarCategoriasInstituicao(
      String instituicaoId) async {
    final snap = await _firestore
        .collection('categorias')
        .where('instituicaoId', isEqualTo: instituicaoId)
        .get();
    final result = snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList()
      ..sort((a, b) =>
          (a['nome'] as String? ?? '').compareTo(b['nome'] as String? ?? ''));
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> buscarTiposSimuladoCategoria({
    required String categoriaId,
    required String instituicaoId,
  }) async {
    final snap = await _firestore
        .collection('tipos_simulado')
        .where('categoriaId', isEqualTo: categoriaId)
        .where('instituicaoId', isEqualTo: instituicaoId)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> buscarAssuntosCategoria({
    required String categoriaId,
    required String instituicaoId,
  }) async {
    final snap = await _firestore
        .collection('assuntos')
        .where('categoriaId', isEqualTo: categoriaId)
        .where('instituicaoId', isEqualTo: instituicaoId)
        .get();
    final result = snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList()
      ..sort((a, b) =>
          (a['nome'] as String? ?? '').compareTo(b['nome'] as String? ?? ''));
    return result;
  }

  @override
  Future<DashboardAlunoModel> buscarDashboardAluno(String uid) async {
    try {
      final results = await Future.wait([
        _firestore.collection('usuarios').doc(uid).get(),
        _firestore
            .collection('usuarios')
            .doc(uid)
            .collection('historico_simulados')
            .get(),
      ]);

      final userDoc = results[0] as DocumentSnapshot;
      final historicoSnap = results[1] as QuerySnapshot;

      String nome = 'Estudante';
      if (userDoc.exists) {
        nome = (userDoc.data() as Map<String, dynamic>)['nome'] as String? ??
            nome;
      }

      double pontos = 0;
      int totalAcertos = 0;
      int totalQuestoes = 0;
      double tempoAssunto = 0;
      int countAssunto = 0;
      double tempoCompleta = 0;
      int countCompleta = 0;

      for (final doc in historicoSnap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        pontos += (d['pontosGamificacao'] as num? ?? 0);
        totalAcertos += (d['acertos'] as num? ?? 0).toInt();
        totalQuestoes += (d['totalQuestoes'] as num? ?? 0).toInt();
        final tipo = (d['tipoProva'] as String? ?? '').toLowerCase();
        final tempo = (d['tempoUtilizadoSegundos'] as num? ?? 0).toDouble();
        if (tipo.contains('assunto')) {
          tempoAssunto += tempo;
          countAssunto++;
        } else {
          tempoCompleta += tempo;
          countCompleta++;
        }
      }

      return DashboardAlunoModel(
        nome: nome,
        provasConcluidas: historicoSnap.docs.length,
        pontosAcumulados: pontos,
        taxaAcerto: totalQuestoes > 0
            ? (totalAcertos / totalQuestoes) * 100
            : 0,
        tempoMedioAssuntoMin:
            countAssunto > 0 ? (tempoAssunto / countAssunto) / 60 : 0,
        tempoMedioCompletaMin:
            countCompleta > 0 ? (tempoCompleta / countCompleta) / 60 : 0,
      );
    } catch (_) {
      return DashboardAlunoModel.empty;
    }
  }
}