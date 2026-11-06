import '../../core/api_client.dart';

class AdvisorService {
  Future<String> ask(String message) async {
    final data = await ApiClient.instance.post('/advisor/chat', {
      'message': message,
    });
    return (data as Map<String, dynamic>)['reply'] as String;
  }
}
