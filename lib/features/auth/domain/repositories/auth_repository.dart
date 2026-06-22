import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Função de login
  Future<UserEntity> loginWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Função de logout
  Future<void> logout();

  /// Verifica se existe um usuário já logado no dispositivo
  Future<UserEntity?> getCurrentUser();
}

