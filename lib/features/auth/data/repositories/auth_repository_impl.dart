import 'dart:async';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<UserEntity> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // 🟢 Mantido: Passando as variáveis por posição em conformidade com o seu DataSource
    return await _dataSource.loginWithEmailAndPassword(email, password);
  }

  @override
  Future<void> logout() async {
    await _dataSource.logout();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return await _dataSource.getCurrentUser();
  }

  // 🟢 ADICIONADO: Reatividade exigida pelo Router e pelo ecossistema do app.
  // Encaminha a escuta do estado de autenticação diretamente a partir do DataSource.
  @override
  Stream<bool> watchAuthState() {
    return _dataSource.watchAuthState();
  }

  // 🟢 ADICIONADO: Fornece as informações de perfil mapeadas em tempo real 
  // para alimentar o White Label e os dados de exibição do menu lateral/layout shell.
  @override
  Stream<Map<String, dynamic>?> watchProfile() {
    return _dataSource.watchProfile();
  }
}