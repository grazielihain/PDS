import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_models.dart'; // Importa o modelo que herda de UserEntity
import '../../../../core/constants/app_constants.dart';

class AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSource(this.firebaseAuth, this.firestore);

  // 🟢 RETORNA O USERMODEL BUSCANDO O USUÁRIO ATUAL COM SESSÃO ATIVA
  Future<UserModel?> getCurrentUser() async {
    final User? firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    final DocumentSnapshot userDoc = await firestore
        .collection(AppConstants.collectionUsers)
        .doc(firebaseUser.uid)
        .get();

    if (!userDoc.exists) return null;

    return UserModel.fromFirestore(userDoc);
  }

  // 🟢 REATIVIDADE DO ROTEADOR: Escuta as alterações na sessão (se mudou o estado de autenticado)
  Stream<bool> watchAuthState() {
    return firebaseAuth.authStateChanges().map((user) => user != null);
  }

  // 🟢 REATIVIDADE DO WHITE LABEL / SHELL / ROUTER: Fornece as informações do perfil mapeadas em tempo real
  Stream<Map<String, dynamic>?> watchProfile() {
    return firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      
      final doc = await firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .get();
          
      if (!doc.exists || doc.data() == null) return null;

      final dadosOriginais = doc.data() as Map<String, dynamic>;
      
      // 🟢 NORMALIZAÇÃO DE CHAVES: Garante total compatibilidade entre PT e EN para o roteador e modelos
      final Map<String, dynamic> dadosNormalizados = Map<String, dynamic>.from(dadosOriginais);
      
      // Resolve o conflito de instituição
      final String instituicao = dadosOriginais['instituicaoId'] ?? dadosOriginais['institutionId'] ?? 'ulbra-01';
      dadosNormalizados['instituicaoId'] = instituicao;
      dadosNormalizados['institutionId'] = instituicao;

      // Resolve o conflito de nome
      dadosNormalizados['nome'] = dadosOriginais['nome'] ?? dadosOriginais['name'] ?? 'Estudante';
      dadosNormalizados['name'] = dadosOriginais['nome'] ?? dadosOriginais['name'] ?? 'Estudante';

      // Normaliza o UID e o Role
      dadosNormalizados['uid'] = user.uid;
      dadosNormalizados['role'] = (dadosOriginais['role'] ?? 'Acess3').toString().trim();

      return dadosNormalizados;
    });
  }

  // Antigo método mantido caso seja utilizado em outras partes legadas do código
  Stream<User?> authStateChanges() {
    return firebaseAuth.authStateChanges();
  }

  // 🟢 FAZ O LOGIN E RETORNA O USERMODEL RECHEADO COM OS DADOS DO FIRESTORE
  Future<UserModel> loginWithEmailAndPassword(String email, String password) async {
    try {
      // 1. Autentica no Firebase Auth
      final UserCredential credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Não foi possível realizar o login. Usuário nulo.');
      }

      // 2. Busca os dados do usuário no Firestore utilizando as AppConstants
      final DocumentSnapshot userDoc = await firestore
          .collection(AppConstants.collectionUsers)
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Perfil do usuário não encontrado no banco de dados.');
      }

      // 🟢 O PULO DO GATO (US 23): Grava o log aqui dentro, direto no servidor,
      // garantindo que fique registrado antes de qualquer mudança de tela!
      await registrarLogAcesso(firebaseUser.uid);

      // 3. Transforma o documento no nosso UserModel pronto
      return UserModel.fromFirestore(userDoc);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('E-mail ou senha incorretos.');
      }
      throw Exception(e.message ?? 'Erro ao realizar autenticação.');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  // FAZER LOGOUT
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  // CRIAR CONTA (Usada no painel administrativo do Admin/Acess2)
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String nome,
    required String institutionId,
  }) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        await firestore
            .collection(AppConstants.collectionUsers)
            .doc(userCredential.user!.uid)
            .set({
              'uid': userCredential.user!.uid,
              'nome': nome,
              'email': email,
              'role': 'Acess3',
              'institutionId': institutionId,
              'instituicaoId': institutionId,
              'avatarEmoji': '🐱',
              'createdAt': FieldValue.serverTimestamp(),
            });
      }

      return userCredential;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ENVIAR E-MAIL DE RECUPERAÇÃO DE SENHA (US 03)
  Future<void> enviarEmailRecuperacaoSenha(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // REGISTRA O LOG DE ACESSO NO FIRESTORE TODA VEZ QUE ALGUÉM LOGAR
  Future<void> registrarLogAcesso(String userId) async {
    try {
      await firestore.collection('logs_acesso').add({
        'userId': userId,
        'data': FieldValue.serverTimestamp(), // Pega a data e hora exata do servidor do Firebase
      });
    } catch (e) {
      // Se falhar o log, imprimimos no terminal, mas não travamos o app do usuário
      print('Erro ao salvar log de auditoria: $e');
    }
  }
}