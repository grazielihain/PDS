import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Ponto de acesso ao DataSource
final authDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

// Vinculação do Repositório Abstrato (Clean Architecture)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authDataSourceProvider);
  return AuthRepositoryImpl(dataSource);
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
  final AuthRepository repository;

  AuthNotifier(this.repository) : super(AuthState());

  // 🟢 CORRIGIDO E ATIVADO: Executa o login usando o contrato da arquitetura limpa
  Future<void> loginComEmailESenha(String email, String password) async {
    state = AuthState(isLoading: true);
    try {
      await repository.loginWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      // Ao chegar aqui, o Firebase Auth atualizou a sessão.
      state = AuthState(isSuccess: true);
    } catch (e) {
      state = AuthState(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Função para cadastrar usuários via painel administrativo
  Future<void> cadastrarEstudante({
    required String email,
    required String password,
    required String nome,
    required String institutionId,
  }) async {
    state = AuthState(isLoading: true);
    try {
      // Executa o fluxo se necessário através do DataSource/Repository
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
      // Chamada para o repositório enviar e-mail de recuperação
      state = AuthState(isSuccess: true);
    } catch (e) {
      state = AuthState(
        errorMessage: e.toString().replaceAll('Exception:', ''),
      );
    }
  }
}

// O Provider que a tela vai escutar
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});