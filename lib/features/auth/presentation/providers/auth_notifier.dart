import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/auth_remote_data_source.dart';

// Ponto de acesso ao DataSource
final authDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

// O Estado da Autenticação
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });
}

// O Notifier (O motor do estado)
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRemoteDataSource dataSource; // 👈 Ajustado o nome aqui

  AuthNotifier(this.dataSource) : super(AuthState());

  // Função para cadastrar usuários via painel administrativo
  Future<void> cadastrarEstudante({
    required String email,
    required String password,
    required String nome,
    required String institutionId,
  }) async {
    state = AuthState(isLoading: true);
    try {
      await dataSource.signUpWithEmailAndPassword(
        email: email,
        password: password,
        nome: nome,
        institutionId: institutionId,
      );
      state = AuthState(isSuccess: true);
    } catch (e) {
      state = AuthState(
        errorMessage: e.toString().replaceAll('Exception:', ''),
      );
    }
  }

  // Função para recuperar senha
  Future<void> recuperarSenha(String email) async {
    state = AuthState(isLoading: true);
    try {
      await dataSource.enviarEmailRecuperacaoSenha(email);
      state = AuthState(isSuccess: true);
    } catch (e) {
      state = AuthState(
        errorMessage: e.toString().replaceAll('Exception:', ''),
      );
    }
  }
}

// O Provider que a tela vai escutar
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final dataSource = ref.watch(authDataSourceProvider);
  return AuthNotifier(dataSource);
});
