import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminRemoteDataSource {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  AdminRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ─── INSTITUIÇÃO ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> buscarInstituicao(String id) async {
    final doc = await _db.collection('instituicoes').doc(id).get();
    return doc.data();
  }

  Future<void> salvarIdentidade(
      String id, Map<String, dynamic> dados) async {
    await _db
        .collection('instituicoes')
        .doc(id)
        .set(dados, SetOptions(merge: true));
  }

  // ─── UPLOAD DE IMAGEM ────────────────────────────────────────────────────────
  // Usa path fixo para logo/mascote (evita acúmulo de arquivos no Storage).
  // Patrocinadores usam timestamp pois múltiplos arquivos coexistem.

  Future<String> uploadImagem({
    required Uint8List bytes,
    required String storagePath,
    required String contentType,
  }) async {
    final ref = _storage.ref().child(storagePath);
    final upload = await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    return upload.ref.getDownloadURL();
  }

  // ─── PATROCINADORES ──────────────────────────────────────────────────────────

  Future<void> salvarPatrocinadores(
      String instituicaoId, List<String> urls) async {
    await _db.collection('instituicoes').doc(instituicaoId).set(
      {'patrocinadoresUrls': urls, 'patrocinios': urls},
      SetOptions(merge: true),
    );
  }

  // ─── CATEGORIAS ──────────────────────────────────────────────────────────────

  Stream<QuerySnapshot> streamCategorias(String instituicaoId) {
    return _db
        .collection('categorias')
        .where('instituicaoId', isEqualTo: instituicaoId)
        .snapshots();
  }

  Future<void> criarCategoria(
      String nome, String instituicaoId) async {
    final existentes = await _db
        .collection('categorias')
        .where('instituicaoId', isEqualTo: instituicaoId)
        .get();
    if (existentes.docs.length >= 20) {
      throw Exception('Limite de 20 categorias por instituição atingido.');
    }
    await _db.collection('categorias').doc().set({
      'nome': nome.trim(),
      'instituicaoId': instituicaoId,
      'dataCriacao': FieldValue.serverTimestamp(),
    });
  }

  Future<void> editarCategoria(String docId, String nome) async {
    await _db.collection('categorias').doc(docId).update({'nome': nome.trim()});
  }

  Future<void> excluirCategoria(String docId) async {
    await _db.collection('categorias').doc(docId).delete();
  }

  // ─── ASSUNTOS ────────────────────────────────────────────────────────────────

  Stream<QuerySnapshot> streamAssuntos(String instituicaoId) {
    return _db
        .collection('assuntos')
        .where('instituicaoId', isEqualTo: instituicaoId)
        .snapshots();
  }

  Future<void> criarAssunto(
      String categoriaId, String nome, String instituicaoId) async {
    final existentes = await _db
        .collection('assuntos')
        .where('instituicaoId', isEqualTo: instituicaoId)
        .get();
    if (existentes.docs.length >= 30) {
      throw Exception('Limite de 30 assuntos por instituição atingido.');
    }
    await _db.collection('assuntos').doc().set({
      'nome': nome.trim(),
      'categoriaId': categoriaId,
      'instituicaoId': instituicaoId,
      'dataCriacao': FieldValue.serverTimestamp(),
    });
  }

  Future<void> editarAssunto(String docId, String nome) async {
    await _db.collection('assuntos').doc(docId).update({'nome': nome.trim()});
  }

  Future<void> excluirAssunto(String docId) async {
    await _db.collection('assuntos').doc(docId).delete();
  }

  Future<bool> assuntoPossuiQuestoes(
      String assuntoId, String instituicaoId) async {
    final q = await _db
        .collection('questoes')
        .where('assuntoId', isEqualTo: assuntoId)
        .where('instituicaoId', isEqualTo: instituicaoId)
        .limit(1)
        .get();
    return q.docs.isNotEmpty;
  }

  // ─── TIPOS DE SIMULADO ───────────────────────────────────────────────────────

  Stream<QuerySnapshot> streamTiposSimulado(String categoriaId) {
    return _db
        .collection('tipos_simulado')
        .where('categoriaId', isEqualTo: categoriaId)
        .snapshots();
  }

  Future<void> criarTipoSimulado(Map<String, dynamic> dados) async {
    await _db.collection('tipos_simulado').doc().set(dados);
  }

  Future<void> editarTipoSimulado(
      String docId, Map<String, dynamic> dados) async {
    await _db.collection('tipos_simulado').doc(docId).update(dados);
  }

  Future<void> excluirTipoSimulado(String docId) async {
    await _db.collection('tipos_simulado').doc(docId).delete();
  }

  // ─── QUESTÕES ────────────────────────────────────────────────────────────────

  Stream<QuerySnapshot> streamQuestoes({
    required String instituicaoId,
    String? categoriaId,
    String? assuntoId,
    String? criadoPor,
  }) {
    Query q = _db
        .collection('questoes')
        .where('instituicaoId', isEqualTo: instituicaoId);
    if (categoriaId != null && categoriaId.isNotEmpty) {
      q = q.where('categoriaId', isEqualTo: categoriaId);
    }
    if (assuntoId != null && assuntoId.isNotEmpty) {
      q = q.where('assuntoId', isEqualTo: assuntoId);
    }
    if (criadoPor != null && criadoPor.isNotEmpty) {
      q = q.where('criadoPor', isEqualTo: criadoPor);
    }
    return q.snapshots();
  }

  Future<String> criarQuestao(Map<String, dynamic> dados) async {
    final existentes = await _db
        .collection('questoes')
        .where('instituicaoId', isEqualTo: dados['instituicaoId'])
        .get();
    if (existentes.docs.length >= 100) {
      throw Exception('Limite de 100 questões por instituição atingido.');
    }
    final ref = _db.collection('questoes').doc();
    await ref.set({...dados, 'dataCriacao': FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> editarQuestao(
      String docId, Map<String, dynamic> dados) async {
    await _db.collection('questoes').doc(docId).update(dados);
  }

  Future<void> excluirQuestao(String docId) async {
    await _db.collection('questoes').doc(docId).delete();
  }

  // ─── MENSAGENS DE RESULTADO ──────────────────────────────────────────────────

  Stream<QuerySnapshot> streamMensagens(String instituicaoId) {
    return _db
        .collection('mensagens_resultado')
        .where('instituicaoId', isEqualTo: instituicaoId)
        .snapshots();
  }

  Future<void> criarMensagem(Map<String, dynamic> dados) async {
    await _db.collection('mensagens_resultado').doc().set({
      ...dados,
      'dataCriacao': FieldValue.serverTimestamp(),
    });
  }

  Future<void> editarMensagem(
      String docId, Map<String, dynamic> dados) async {
    await _db.collection('mensagens_resultado').doc(docId).update(dados);
  }

  Future<void> excluirMensagem(String docId) async {
    await _db.collection('mensagens_resultado').doc(docId).delete();
  }

  // ─── GAMIFICAÇÃO ─────────────────────────────────────────────────────────────

  Stream<QuerySnapshot> streamGamificacao(String instituicaoId) {
    return _db
        .collection('gamificacao')
        .where('instituicaoId', isEqualTo: instituicaoId)
        .snapshots();
  }

  Future<void> criarRegraGamificacao(Map<String, dynamic> dados) async {
    await _db.collection('gamificacao').doc().set({
      ...dados,
      'dataCriacao': FieldValue.serverTimestamp(),
    });
  }

  Future<void> editarRegraGamificacao(
      String docId, Map<String, dynamic> dados) async {
    await _db.collection('gamificacao').doc(docId).update(dados);
  }

  Future<void> excluirRegraGamificacao(String docId) async {
    await _db.collection('gamificacao').doc(docId).delete();
  }

  // ─── USUÁRIOS ────────────────────────────────────────────────────────────────

  Stream<QuerySnapshot> streamUsuarios({
    required String instituicaoId,
    String? role,
    String? criadoPor,
  }) {
    Query q = _db
        .collection('usuarios')
        .where('instituicaoId', isEqualTo: instituicaoId)
        .limit(15);
    if (role != null) q = q.where('role', isEqualTo: role);
    if (criadoPor != null) q = q.where('criadoPor', isEqualTo: criadoPor);
    return q.snapshots();
  }

  Future<void> editarUsuario(
      String docId, Map<String, dynamic> dados) async {
    await _db.collection('usuarios').doc(docId).update(dados);
  }

  Future<void> excluirUsuario(String docId) async {
    await _db.collection('usuarios').doc(docId).delete();
  }

  // ─── AUDITORIA ───────────────────────────────────────────────────────────────

  Future<void> registrarAuditoria({
    required String instituicaoId,
    required String acao,
    required String tela,
    required String detalhe,
    required String registroAntigo,
    required String registroNovo,
  }) async {
    try {
      final user = _auth.currentUser;
      await _db.collection('auditoria').add({
        'instituicaoId': instituicaoId,
        'userId': user?.uid ?? 'desconhecido',
        'userName': user?.email ?? 'Administrador',
        'acao': acao,
        'tela': tela,
        'detalhe': detalhe,
        'registroAntigo': registroAntigo,
        'registroNovo': registroNovo,
        'dataHora': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Stream<QuerySnapshot> streamAuditoria(String instituicaoId) {
    return _db
        .collection('auditoria')
        .where('instituicaoId', isEqualTo: instituicaoId)
        .limit(50)
        .snapshots();
  }

  // ─── MÉTRICAS HOME ───────────────────────────────────────────────────────────

  Future<int> contarDocumentos({
    required String collection,
    required String instituicaoId,
    String? filtroChave,
    String? filtroValor,
    String? filtroChave2,
    String? filtroValor2,
  }) async {
    Query q = _db
        .collection(collection)
        .where('instituicaoId', isEqualTo: instituicaoId);
    if (filtroChave != null && filtroValor != null) {
      q = q.where(filtroChave, isEqualTo: filtroValor);
    }
    if (filtroChave2 != null && filtroValor2 != null) {
      q = q.where(filtroChave2, isEqualTo: filtroValor2);
    }
    final snap = await q.count().get();
    return snap.count ?? 0;
  }
}
