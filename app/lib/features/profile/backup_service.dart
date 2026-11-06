import '../../core/api_client.dart';

class BackupService {
  Future<Map<String, dynamic>> exportBackup() async {
    final data = await ApiClient.instance.get('/backup');
    return data as Map<String, dynamic>;
  }

  Future<void> restoreBackup(Map<String, dynamic> backup) async {
    await ApiClient.instance.post('/backup/restore', backup);
  }

  Future<void> clearAll() async {
    await ApiClient.instance.delete('/backup/all');
  }
}
