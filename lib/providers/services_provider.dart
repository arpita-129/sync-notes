import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SyncService(apiService);
});
