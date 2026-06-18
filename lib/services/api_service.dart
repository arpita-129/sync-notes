import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio(BaseOptions(
    baseUrl: 'https://6a33d2918248ee962fa479fd.mockapi.io/api/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<List<dynamic>> getNotes() async {
    final response = await _dio.get('/notes');
    return response.data;
  }

  Future<dynamic> getNote(String id) async {
    final response = await _dio.get('/notes/$id');
    return response.data;
  }

  Future<dynamic> createNote(Map<String, dynamic> data) async {
    final response = await _dio.post('/notes', data: data);
    return response.data;
  }

  Future<dynamic> updateNote(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/notes/$id', data: data);
    return response.data;
  }

  Future<void> deleteNote(String id) async {
    await _dio.delete('/notes/$id');
  }
}
