import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/admin_stats.dart';
import '../models/paginated.dart';
import '../models/user.dart';

class AdminProvider extends ChangeNotifier {
  final _dio = ApiClient.instance.dio;

  AdminStats? stats;
  bool isLoadingStats = false;

  List<User> users = [];
  int page = 1;
  int totalPages = 1;
  bool isLoadingUsers = false;

  Future<void> loadStats() async {
    isLoadingStats = true;
    notifyListeners();
    try {
      final response = await _dio.get('/admin/stats');
      stats = AdminStats.fromJson(response.data as Map<String, dynamic>);
    } finally {
      isLoadingStats = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers({bool reset = true}) async {
    if (reset) page = 1;
    isLoadingUsers = true;
    notifyListeners();
    try {
      final response = await _dio.get('/admin/users', queryParameters: {
        'page': page,
        'limit': 20,
      });
      final paginated = Paginated<User>.fromJson(
        response.data as Map<String, dynamic>,
        User.fromJson,
      );
      users = reset ? paginated.items : [...users, ...paginated.items];
      totalPages = paginated.totalPages;
    } finally {
      isLoadingUsers = false;
      notifyListeners();
    }
  }

  Future<void> loadNextUsersPage() async {
    if (page >= totalPages) return;
    page++;
    await loadUsers(reset: false);
  }

  Future<bool> updateUserRole(String userId, String role) async {
    try {
      final response =
          await _dio.patch('/admin/users/$userId/role', data: {'role': role});
      final updated = User.fromJson(response.data as Map<String, dynamic>);
      final index = users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        users[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
