import '../core/repository.dart';
import 'user_aggregate.dart';
import 'user_id.dart';

abstract class UserRepository extends Repository<User, UserId> {
  Future<User?> findByEmail(String email);
  Future<User?> findByUsername(String username);
  Future<bool> existsWithEmail(String email);
  Future<bool> existsWithUsername(String username);
  Future<List<User>> findByRole(String role);
  Future<List<User>> findLockedUsers();
  Future<List<User>> findUsersWithExpiredPasswords();
  Future<int> countActiveUsers();
}