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
    // 🟢 CORRIGIDO: Passando as variáveis diretamente por posição,
    // sem as etiquetas "email:" e "password:", combinando com o seu DataSource!
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
}
