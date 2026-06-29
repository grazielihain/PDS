import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_models.dart'; 

class AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSource(this.firebaseAuth, this.firestore);

  // Retorna o UserModel buscando o usuário atual com sessão ativa
  Future<UserModel?> getCurrentUser() async {
    final User? firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    final DocumentSnapshot userDoc = await firestore
        .collection('usuarios')
        .doc(firebaseUser.uid)
        .get();

    if (!userDoc.exists) return null;

    return UserModel.fromFirestore(userDoc);
  }

  // Escuta alterações na sessão (Se logou ou deslogou)
  Stream<User?> authStateChanges() {
    return firebaseAuth.authStateChanges();
  }

  // Faz o Login e retorna o UserModel com os dados do Firestore
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

      // 2. Busca os dados do usuário no Firestore
      final DocumentSnapshot userDoc = await firestore
          .collection('usuarios')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Perfil do usuário não encontrado no banco de dados.');
      }

      // Grava o log direto no servidor garantindo que fique registrado antes de 
      //qualquer mudança de tela
      await registrarLogAcesso(firebaseUser.uid);

      // 3. Transforma o documento no UserModel pronto
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

  // Fazer Logout
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  // Criar conta (painel administrativo do Admin/Acess2)
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
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .set({
              'uid': userCredential.user!.uid,
              'nome': nome,
              'email': email,
              'role': 'Acess3',
              'institutionId': institutionId,
              'instituicaoId': institutionId,
              'avatarEmoji': '🐱',
              'primeiroLogin': true,
              'createdAt': FieldValue.serverTimestamp(),
            });
      }

      return userCredential;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Enviar e-mail de recuperação de senha
  Future<void> enviarEmailRecuperacaoSenha(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  //Registra o log de acesso no Firestore toda vez que alguém logar
  Future<void> registrarLogAcesso(String userId) async {
    try {
      await firestore.collection('logs_acesso').add({
        'userId': userId,
        'data': FieldValue.serverTimestamp(), // Pega a data e hora exata do servidor do Firebase
      });
    } catch (e) {
      // Se falhar o log, imprime no terminal, mas não trava o app do usuário
      debugPrint('Erro ao salvar log de auditoria: $e');
    }
  }
}
