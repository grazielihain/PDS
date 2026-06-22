import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/instituicao_entity.dart';
import '../../domain/repositories/master_repository.dart';
import '../../../auth/data/models/institution_model.dart';
import '../../../auth/data/models/user_models.dart';

class MasterRepositoryImpl implements MasterRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Duration _timeoutPadrao = const Duration(seconds: 4);

  @override
  Future<Map<String, int>> buscarMetricasGlobais() async {
    try {
      final usuariosSnapshot = await _firestore
          .collection(AppConstants.collectionUsers)
          .get()
          .timeout(_timeoutPadrao);

      final instituicoesSnapshot = await _firestore
          .collection(AppConstants.collectionInstitutions)
          .get()
          .timeout(_timeoutPadrao);

      int master = 0;
      int admin = 0;
      int acess2 = 0;
      int acess3 = 0;

      for (var doc in usuariosSnapshot.docs) {
        final dados = doc.data();
        final String role = (dados['role'] ?? 'Acess3').toString().toLowerCase();

        if (role == 'master') master++;
        else if (role == 'admin') admin++;
        else if (role == 'acess2') acess2++;
        else if (role == 'acess3') acess3++;
      }

      return {
        'totalUsuarios': usuariosSnapshot.docs.length,
        'totalInstituicoes': instituicoesSnapshot.docs.length,
        'master': master,
        'admin': admin,
        'acess2': acess2,
        'acess3': acess3,
      };
    } catch (e) {
      return {'totalUsuarios': 0, 'totalInstituicoes': 0, 'master': 0, 'admin': 0, 'acess2': 0, 'acess3': 0};
    }
  }

  @override
  Future<List<InstituicaoEntity>> listarInstituicoes() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionInstitutions)
          .get()
          .timeout(_timeoutPadrao);

      return snapshot.docs.map((doc) {
        final model = InstitutionModel.fromFirestore(doc);
        return InstituicaoEntity(
          id: doc.id, // Garante que pega o ID real do documento do Firestore
          nome: model.nome,
          corPrimaria: model.primaryColorHex ?? model.corCustomizada ?? '#4CAF50',
          logoUrl: model.logoUrl ?? model.logo,
          dataCriacao: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      throw Exception('💥 Falha ao listar instituições: $e');
    }
  }

  @override
  Future<void> cadastrarInstituicao(InstituicaoEntity instituicao) async {
    final String idLimpo = instituicao.id.trim();
    if (idLimpo.isEmpty) {
      throw Exception('💥 ERRO: O ID do banco não pode ser vazio!');
    }

    try {
      final Map<String, dynamic> dadosParaSalvar = {
        'id': idLimpo, // ID do banco primeiro
        'nome': instituicao.nome, // Nome do sistema depois
        'primaryColorHex': instituicao.corPrimaria,
        'corCustomizada': instituicao.corPrimaria,
        'logoUrl': instituicao.logoUrl,
        'plano': 'Gratuito',
        'patrocinadores': const [],
        'dataCriacao': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(AppConstants.collectionInstitutions)
          .doc(idLimpo)
          .set(dadosParaSalvar)
          .timeout(_timeoutPadrao);
    } catch (e) {
      throw Exception('💥 Erro ao cadastrar instituição: $e');
    }
  }

  @override
  Future<void> editarInstituicao(InstituicaoEntity instituicao) async {
    try {
      await _firestore
          .collection(AppConstants.collectionInstitutions)
          .doc(instituicao.id)
          .update({
            'nome': instituicao.nome,
            'primaryColorHex': instituicao.corPrimaria,
            'corCustomizada': instituicao.corPrimaria,
            'logoUrl': instituicao.logoUrl,
          })
          .timeout(_timeoutPadrao);
    } catch (e) {
      throw Exception('💥 Erro ao editar instituição: $e');
    }
  }

  @override
  Future<void> excluirInstituicao(String id) async {
    try {
      await _firestore
          .collection(AppConstants.collectionInstitutions)
          .doc(id)
          .delete()
          .timeout(_timeoutPadrao);
    } catch (e) {
      throw Exception('💥 Erro ao excluir instituição: $e');
    }
  }

  /// Método de compatibilidade caso sua UI chame por este nome específico
  Future<void> removerInstituicao(String id) async {
    await excluirInstituicao(id);
  }

  @override
  Future<List<Map<String, dynamic>>> buscarUsuariosPorInstituicao(
      String iID, String nivelAcesso) async {
    try {
      Query query = _firestore
          .collection(AppConstants.collectionUsers)
          .where('instituicaoId', isEqualTo: iID);

      if (nivelAcesso != 'Todos') {
        query = query.where('role', isEqualTo: nivelAcesso);
      }

      final snapshot = await query.get().timeout(_timeoutPadrao);
      
      return snapshot.docs.map((doc) {
        final model = UserModel.fromFirestore(doc);
        return {
          'id': model.id,
          'nome': model.name,
          'email': model.email,
          'role': model.role,
          'instituicaoId': model.institutionId,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cadastrarUsuarioNaInstituicao(
      Map<String, dynamic> dadosUsuario, String senha) async {
    try {
      await _firestore
          .collection(AppConstants.collectionUsers)
          .add({
            'nome': dadosUsuario['nome'] ?? '',
            'email': dadosUsuario['email'] ?? '',
            'role': dadosUsuario['role'] ?? 'Acess3',
            'instituicaoId': dadosUsuario['instituicaoId'] ?? '',
            'dataCriacao': FieldValue.serverTimestamp(),
          })
          .timeout(_timeoutPadrao);
    } catch (e) {
      throw Exception('💥 Erro ao vincular usuário: $e');
    }
  }

  @override
  Future<void> excluirUsuario(String id) async {
    try {
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(id)
          .delete()
          .timeout(_timeoutPadrao);
    } catch (e) {
      throw Exception('💥 Erro ao excluir usuário: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> buscarLogsAuditoria(
      String filtroInstituicao) async {
    try {
      Query query = _firestore
          .collection('auditoria_logs')
          .orderBy('timestamp', descending: true);

      if (filtroInstituicao != 'Todas') {
        query = query.where('instituicaoId', isEqualTo: filtroInstituicao);
      }

      final snapshot = await query.limit(50).get().timeout(_timeoutPadrao);

      return snapshot.docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>? ?? {};
        return {
          'id': doc.id,
          'usuarioEmail': d['usuarioEmail'] ?? 'Sistema',
          'acao': d['acao'] ?? 'Operação desconhecida',
          'detalhes': d['detalhes'] ?? '',
          'timestamp': (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'instituicaoId': d['instituicaoId'] ?? 'Global',
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> buscarMetricasControladoria(String filtroInstituicao) async {
    final bool isGlobal = filtroInstituicao == 'Todas';
    return {
      'totalUsuarios': isGlobal ? 1240 : 310,
      'provasRealizadas': isGlobal ? 5820 : 1450,
      'questoesCadastradas': isGlobal ? 850 : 210,
      'categoriasCadastradas': isGlobal ? 45 : 12,
      'acessosRealizados': isGlobal ? 12400 : 3100,
      'graficoAtividades': <String, int>{
        'Seg': isGlobal ? 120 : 30,
        'Ter': isGlobal ? 250 : 65,
        'Qua': isGlobal ? 410 : 95,
        'Qui': isGlobal ? 380 : 80,
        'Sex': isGlobal ? 500 : 120,
        'Sáb': isGlobal ? 90 : 20,
        'Dom': isGlobal ? 40 : 10,
      },
    };
  }
}