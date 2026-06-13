import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/usecases/login_usecase.dart';
import 'auth_state.dart';

// 1. Instancia o DataSource de forma global na memória (Gerenciado pelo Riverpod)
final authDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
  FirebaseAuth.instance,
  FirebaseFirestore.instance,
);
});

// 2. Instancia o Repositório injetando o DataSource criado acima
final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  final dataSource = ref.read(authDataSourceProvider);
  return AuthRepositoryImpl(dataSource);
});

// 3. Instancia o Caso de Uso de Login injetando o Repositório
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return LoginUseCase(repository);
});

// 4. O Notifier principal que a tela vai escutar para saber o estado atual do login
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;

  AuthNotifier(this._loginUseCase) : super(const AuthInitial());

  /// Função que gerencia o fluxo visual do Login
  Future<void> login(String email, String password) async {
    // Avisa a tela para mostrar o círculo de carregamento
    state = const AuthLoading();

    try {
      // Executa a regra de negócio na camada de domínio
      final user = await _loginUseCase.execute(email: email, password: password);
      
      // Se der certo, joga o estado de Sucesso com o usuário logado
      state = AuthSuccess(user);
    } catch (e) {
      // Se der erro, captura a mensagem amigável e joga no estado de Erro
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Limpa o estado atual (útil ao fazer logout)
  void reset() {
    state = const AuthInitial();
  }
}

// 5. Provedor global que expõe o nosso controlador para as telas do Flutter
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final loginUseCase = ref.read(loginUseCaseProvider);
  return AuthNotifier(loginUseCase);
});