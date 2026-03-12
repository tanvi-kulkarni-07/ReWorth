import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Simple wrapper around the OpenRouter chat/completions endpoint.
///
/// Before using this class you must load your environment variables (for
/// example by calling `await dotenv.load()` in `main()`).  The following keys
/// are expected:
///
/// ```
/// OPENROUTER_API_URL=https://openrouter.ai/api/v1/chat/completions
/// OPENROUTER_API_KEY=sk-...
/// OPENROUTER_MODEL=openai/gpt-3.5-turbo
/// ```
///
/// The service just posts a user prompt and returns the text of the first
/// choice.  You can of course extend it to support system / assistant roles,
/// temperature, stop sequences, etc.
class OpenRouterService {
  final Uri _endpoint = Uri.parse(
    dotenv.env['OPENROUTER_API_URL'] ??
        'https://openrouter.ai/api/v1/chat/completions',
  );

  Future<String> ask(String prompt) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    final model = dotenv.env['OPENROUTER_MODEL'];

    if (apiKey == null || model == null) {
      throw StateError('OpenRouter API key/model not configured');
    }

    final response = await http.post(
      _endpoint,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are ReWorth Eco-Assistant, a helpful and knowledgeable expert in sustainability and the ReWorth app. '
                'While you specialize in recycling and the ReWorth platform, you are a versatile AI and should answer ANY questions the user asks, regardless of whether they are related to the app or not. '
                'Key ReWorth Features for reference: '
                '1. Upload: Users take photos of waste for listing. '
                '2. Dashboard: Tracks Waste (kg) and Carbon (CO2). '
                '3. Marketplace: Sell waste for Impact Earnings. '
                '4. Logistics: Pickup and transport. '
                '5. Recycler Map: Local centers. '
                '6. Wallet: Earnings management. '
                'Maintain a professional and helpful tone for all topics. Use Markdown (**bold**) for key terms and bullet points for lists.',
          },
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'OpenRouter error: ${response.statusCode} ${response.body}',
      );
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final choices = body['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw StateError('No choices returned from OpenRouter');
    }

    final message = choices[0]['message'] as Map<String, dynamic>?;
    return message?['content'] as String? ?? '';
  }
}
