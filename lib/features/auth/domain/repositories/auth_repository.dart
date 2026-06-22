import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> loginWithEmailAndPassword({
    required String email,
    required String password,
  });
  
  Future<void> logout();
  
  Future<UserEntity?> getCurrentUser();

  // Contratos reativos para o GoRouter e White Label
  Stream<bool> watchAuthState();
  Stream<Map<String, dynamic>?> watchProfile();
}