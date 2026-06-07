import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_models.dart';
import '../../../../core/constants/app_constants.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Função que faz o login na nuvem e busca os dados do perfil
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Faz a autenticação de e-mail e senha no Firebase Auth
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Não foi possível realizar o login. Usuário nulo.');
      }

      // 2. Com o ID do usuário em mãos, busca os dados complementares no Firestore      
      final DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Perfil do usuário não encontrado no banco de dados.');
      }

      // 3. Converte o documento bruto NoSQL para a UserModel
      return UserModel.fromFirestore(userDoc);
    } on FirebaseAuthException catch (e) {
      // Tratamento amigável de erros comuns do Firebase Auth
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('E-mail ou senha incorretos.');
      }
      throw Exception(e.message ?? 'Erro ao realizar autenticação.');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  /// Realiza o logout no Firebase Auth
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Verifica se há um usuário com sessão ativa no aparelho e busca seus dados
  Future<UserModel?> getCurrentUser() async {
    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final DocumentSnapshot userDoc = await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(firebaseUser.uid)
        .get();

    if (!userDoc.exists) return null;

    return UserModel.fromFirestore(userDoc);
  }
}