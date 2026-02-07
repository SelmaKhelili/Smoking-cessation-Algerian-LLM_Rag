import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service to communicate with the RAG API (deployed via ngrok)
/// This connects your Flutter app to the sophisticated RAG system from the notebook
class RagApiService {
  // ⚠️ IMPORTANT: Replace this with your actual ngrok URL from the notebook output
  // Example: 'https://1234-abcd-5678-efgh.ngrok-free.app'
  static const String _baseUrl = 'https://nikolas-interfilar-stalagmitically.ngrok-free.dev'; // ← Base URL only, no /query!
  
  static const Duration _timeout = Duration(seconds: 30);

  /// Send a question to the RAG API and get the response
  /// 
  /// Returns a Map with the full response including:
  /// - answer: The generated response
  /// - confidence: Similarity score (0-1)
  /// - rag_used: Whether RAG context was used
  /// - query_type: Type of query (smoking, greeting, insult, off_topic)
  /// - similarity_interpretation: Detailed similarity analysis
  /// - selected_document: Document used (if any)
  /// - token_usage: Token budget information
  Future<Map<String, dynamic>> sendQuery(String question) async {
    try {
      final url = Uri.parse('$_baseUrl/query');
      
      print('🚀 Sending query to RAG API: $question');
      
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'query': question,  // Changed from 'question' to 'query' to match API
            }),
          )
          .timeout(_timeout);

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        // Log the response for debugging
        print('✅ RAG Response:');
        print('  Answer: ${data['answer']}');
        print('  Confidence: ${data['confidence']}');
        print('  RAG Used: ${data['rag_used']}');
        print('  Query Type: ${data['query_type']}');
        
        return data;
      } else {
        print('❌ Error: ${response.statusCode} - ${response.body}');
        throw Exception('API returned ${response.statusCode}: ${response.body}');
      }
    } on http.ClientException catch (e) {
      print('❌ Network error: $e');
      throw Exception('Network error: Cannot connect to RAG API. Is ngrok running?');
    } catch (e) {
      print('❌ Error: $e');
      throw Exception('Failed to get response: $e');
    }
  }

  /// Check if the API is healthy
  Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('$_baseUrl/health');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ API Health: ${data['status']} - ${data['documents']} documents loaded');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }

  /// Get API information
  Future<Map<String, dynamic>> getApiInfo() async {
    try {
      final url = Uri.parse('$_baseUrl/info');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print('❌ Info request failed: $e');
      return {};
    }
  }
}
