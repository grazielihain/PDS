import 'dart:io';
import 'package:flutter/foundation.dart'; // Import necessário para o debugPrint
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/instituicao_entity.dart';
import '../../domain/repositories/master_repository.dart';

class MasterRepositoryImpl implements MasterRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<Map<String, int>> buscarMetricasGlobais() async {
    try {
      final usuariosSnapshot = await _firestore
          .collection(AppConstants.collectionUsers)
          .get();

      final instituicoesSnapshot = await _firestore
          .collection(AppConstants.collectionInstitutions)
          .get();

      int master = 0;
      int admin = 0;
      int acess2 = 0;
      int acess3 = 0;

      for (var doc in usuariosSnapshot.docs) {
        final dados = doc.data();
        final String role = (dados['role'] ?? 'Acess3')
            .toString()
            .toLowerCase();

        if (role == 'master') {
          master++;
        } else if (role == 'admin') {
          admin++;
        } else if (role == 'acess2') {
          acess2++;
        } else if (role == 'acess3') {
          acess3++;
        }
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
      debugPrint('🔥 ERRO FIRESTORE BUSCAR_METRICAS_GLOBAIS: $e');
      throw Exception('Erro ao buscar métricas globais: $e');
    }
  }

  @override
  Future<List<InstituicaoEntity>> listarInstituicoes() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionInstitutions)
          .get();

      return snapshot.docs.map((doc) {
        final dados = doc.data();
        
        String obtenerCorSegura() {
          final corBase = dados['primaryColorHex'] ?? dados['corCustomizada'] ?? '#4CAF50';
          if (corBase.isEmpty) return '#4CAF50';
          return corBase.startsWith('#') ? corBase : '#$corBase';
        }

        return InstituicaoEntity(
          id: doc.id,
          nome: dados['nome']?.toString().isEmpty ?? true ? 'Instituição Sem Nome' : dados['nome'],
          corPrimaria: obtenerCorSegura(),
          logoUrl: dados['logoUrl'] ?? dados['logo'] ?? '',
          dataCriacao: DateTime.now(), 
        );
      }).toList();
    } catch (e) {
      debugPrint('🔥 ERRO FIRESTORE LISTAR_INSTITUICOES: $e');
      throw Exception('Erro ao listar instituições: $e');
    }
  }

  @override
  Future<void> cadastrarInstituicao(InstituicaoEntity instituicao, {dynamic arquivoLogo}) async {
    try {
      final String customId = instituicao.id.trim();
      final docRef = customId.isNotEmpty 
          ? _firestore.collection(AppConstants.collectionInstitutions).doc(customId)
          : _firestore.collection(AppConstants.collectionInstitutions).doc();

      String? urlFinal = instituicao.logoUrl;

      if (arquivoLogo != null && arquivoLogo is PlatformFile) {
        final refStorage = _storage.ref().child('instituicoes/${docRef.id}/logo.png');
        final metadata = SettableMetadata(contentType: 'image/png');

        if (arquivoLogo.bytes != null && arquivoLogo.bytes!.isNotEmpty) {
          await refStorage.putData(arquivoLogo.bytes!, metadata);
        } else if (arquivoLogo.path != null) {
          await refStorage.putFile(File(arquivoLogo.path!), metadata);
        }
        urlFinal = await refStorage.getDownloadURL();
      }

      final corSalvar = instituicao.corPrimaria.startsWith('#') 
          ? instituicao.corPrimaria 
          : '#${instituicao.corPrimaria}';

      await docRef.set({
        'id': docRef.id,
        'nome': instituicao.nome,
        'primaryColorHex': corSalvar,
        'corCustomizada': corSalvar,
        'logoUrl': urlFinal ?? '',
        'plano': 'Gratuito',
        'patrocinadores': const [],
        'dataCriacao': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('🔥 ERRO FIRESTORE CADASTRAR_IE: $e');
      throw Exception('Erro ao cadastrar instituição: $e');
    }
  }

  @override
  Future<void> editarInstituicao(InstituicaoEntity instituicao, {dynamic arquivoLogo}) async {
    try {
      String? urlFinal = instituicao.logoUrl;

      if (arquivoLogo != null && arquivoLogo is PlatformFile) {
        final refStorage = _storage.ref().child('instituicoes/${instituicao.id}/logo.png');
        final metadata = SettableMetadata(contentType: 'image/png');

        if (arquivoLogo.bytes != null && arquivoLogo.bytes!.isNotEmpty) {
          await refStorage.putData(arquivoLogo.bytes!, metadata);
        } else if (arquivoLogo.path != null) {
          await refStorage.putFile(File(arquivoLogo.path!), metadata);
        }
        urlFinal = await refStorage.getDownloadURL();
      }

      final corSalvar = instituicao.corPrimaria.startsWith('#') 
          ? instituicao.corPrimaria 
          : '#${instituicao.corPrimaria}';

      await _firestore
          .collection(AppConstants.collectionInstitutions)
          .doc(instituicao.id)
          .update({
            'nome': instituicao.nome,
            'primaryColorHex': corSalvar,
            'corCustomizada': corSalvar,
            'logoUrl': urlFinal ?? '',
          });
    } catch (e) {
      debugPrint('🔥 ERRO FIRESTORE EDITAR_IE: $e');
      throw Exception('Erro ao editar instituição: $e');
    }
  }

  @override
  Future<void> excluirInstituicao(String id) async {
    try {
      try {
        final refStorage = _storage.ref().child('instituicoes/$id/logo.png');
        await refStorage.delete();
      } catch (_) {}

      await _firestore
          .collection(AppConstants.collectionInstitutions)
          .doc(id)
          .delete();
          
    } catch (e) {
      debugPrint('🔥 ERRO FIRESTORE EXCLUIR_IE: $e');
      throw Exception('Erro ao excluir instituição: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> buscarUsuariosPorInstituicao(
    String iID,
    String nivelAcesso,
  ) async {
    try {
      Query query = _firestore
          .collection(AppConstants.collectionUsers)
          .where('instituicaoId', isEqualTo: iID);

      if (nivelAcesso != 'Todos') {
        query = query.where('role', isEqualTo: nivelAcesso);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final dados = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'nome': dados['nome'] ?? dados['name'] ?? 'Sem Nome',
          'email': dados['email'] ?? '',
          'role': dados['role'] ?? 'Acess3',
          'instituicaoId': dados['instituicaoId'] ?? dados['institutionId'] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('🔥 ERRO FIRESTORE BUSCAR_USUARIOS_POR_IE: $e');
      throw Exception('Erro ao buscar usuários da instituição: $e');
    }
  }

  @override
  Future<void> cadastrarUsuarioNaInstituicao(
    Map<String, dynamic> dadosUsuario,
    String senha,
  ) async {
    try {
      final docRef = _firestore.collection(AppConstants.collectionUsers).doc();

      await docRef.set({
        'id': docRef.id,
        'nome': dadosUsuario['nome'] ?? '',
        'email': dadosUsuario['email'] ?? '',
        'role': dadosUsuario['role'] ?? 'Acess3',
        'instituicaoId': dadosUsuario['instituicaoId'] ?? '',
        'dataCriacao': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('🔥 ERRO FIRESTORE CADASTRAR_USER: $e');
      throw Exception('Erro ao vincular usuário na instituição: $e');
    }
  }

  @override
  Future<void> editarUsuarioNaInstituicao(Map<String, dynamic> dadosUsuario) async {
    try {
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(dadosUsuario['id'])
          .update({
        'nome': dadosUsuario['nome'],
        'email': dadosUsuario['email'],
        'role': dadosUsuario['role'],
      });
    } catch (e) {
      debugPrint('🔥 ERRO FIRESTORE EDITAR_USER: $e');
      throw Exception('Erro ao editar dados de usuário: $e');
    }
  }

  @override
  Future<void> excluirUsuario(String id) async {
    try {
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('🔥 ERRO FIRESTORE EXCLUIR_USER: $e');
      throw Exception('Erro ao excluir usuário: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> buscarLogsAuditoria(
    String filtroInstituicao,
  ) async {
    try {
      Query query = _firestore
          .collection('auditoria_logs')
          .orderBy('timestamp', descending: true);

      if (filtroInstituicao != 'Todas') {
        query = query.where('instituicaoId', isEqualTo: filtroInstituicao);
      }

      final snapshot = await query.limit(50).get();

      return snapshot.docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>? ?? {};
        return {
          'id': doc.id,
          'usuarioEmail': d['usuarioEmail'] ?? 'Sistema',
          'acao': d['acao'] ?? 'Operação desconhecida',
          'detalhes': d['detalhes'] ?? '',
          'timestamp':
              (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'instituicaoId': d['instituicaoId'] ?? 'Global',
        };
      }).toList();
    } catch (e) {
      debugPrint('🔥 ERRO FIRESTORE BUSCAR_LOGS_AUDITORIA: $e');
      throw Exception('Erro ao carregar logs de auditoria: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> buscarMetricasControladoria(
    String filtroInstituicao,
  ) async {
    try {
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
    } catch (e) {
      debugPrint('🔥 ERRO FIRESTORE BUSCAR_METRICAS_CONTROLADORIA: $e');
      throw Exception('Erro ao processar indicadores da controladoria: $e');
    }
  }
}