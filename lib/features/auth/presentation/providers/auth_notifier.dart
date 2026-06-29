import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/auth_remote_data_source.dart';

// Informação para o DataSource de autenticação.
final authDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

// Estado para operações de registro e recuperação de senha
class RegistroState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const RegistroState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });
}

// Notifier para cadastro de estudantes e recuperação de senha
class RegistroNotifier extends StateNotifier<RegistroState> {
  final AuthRemoteDataSource dataSource;

  RegistroNotifier(this.dataSource) : super(const RegistroState());

  Future<void> cadastrarEstudante({
    required String email,
    required String password,
    required String nome,
    required String institutionId,
  }) async {
    state = const RegistroState(isLoading: true);
    try {
      await dataSource.signUpWithEmailAndPassword(
        email: email,
        password: password,
        nome: nome,
        institutionId: institutionId,
      );
      state = const RegistroState(isSuccess: true);
    } catch (e) {
      state = RegistroState(
        errorMessage: e.toString().replaceAll('Exception:', ''),
      );
    }
  }

  Future<void> recuperarSenha(String email) async {
    state = const RegistroState(isLoading: true);
    try {
      await dataSource.enviarEmailRecuperacaoSenha(email);
      state = const RegistroState(isSuccess: true);
    } catch (e) {
      state = RegistroState(
        errorMessage: e.toString().replaceAll('Exception:', ''),
      );
    }
  }
}

// Provider exposto para as telas (login_page usa authNotifierProvider.notifier)
final authNotifierProvider =
    StateNotifierProvider<RegistroNotifier, RegistroState>((ref) {
  final dataSource = ref.watch(authDataSourceProvider);
  return RegistroNotifier(dataSource);
});
