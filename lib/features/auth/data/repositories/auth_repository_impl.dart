import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Implementação AuthRepository: une a camada de Domain à camada de Data.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  // O Repositório precisa do Datasource para buscar os dados na nuvem
  AuthRepositoryImpl(this._dataSource);

  @override
  Future<UserEntity> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Chama o datasource para fazer o login bruto no Firebase
    // Como UserModel herda de UserEntity, o Dart aceita o retorno.
    return await _dataSource.loginWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> logout() async {
    await _dataSource.logout();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return await _dataSource.getCurrentUser();
  }
}