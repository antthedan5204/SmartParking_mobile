import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class VoiceBookingService {
  // TODO: Securely store and retrieve this key.
  static const String _openAiKey =
      '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';

  static Future<Map<String, dynamic>?> processConversation(
    List<Map<String, dynamic>> chatHistory,
  ) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final payload = {
      "model": "gpt-3.5-turbo",
      "messages": [
        {
          "role": "system",
          "content": "Bạn là trợ lý thông minh giúp tìm bãi đỗ xe trong hệ thống Smart Parking. Thời gian hệ thống hiện tại là: ${DateTime.now().toIso8601String()}. Nhiệm vụ của bạn: 1. Nếu người dùng muốn tìm bãi đỗ, gọi search_lots. 2. Nếu người dùng chọn bãi đỗ, gọi select_lot. 3. Nếu người dùng nói thời gian đỗ (giờ vào và giờ ra), gọi set_time. Luôn trả lời ngắn gọn, thân thiện bằng tiếng Việt nếu cần hỏi thêm thông tin.",
        },
        ...chatHistory,
      ],
      "tools": [
        {
          "type": "function",
          "function": {
            "name": "search_lots",
            "description": "Tìm kiếm bãi đỗ xe",
            "parameters": {
              "type": "object",
              "properties": {
                "lot_name": {
                  "type": "string",
                  "description": "Tên bãi đỗ chính xác (VD: Vincom, Hồ Gươm)",
                },
                "near_location": {
                  "type": "string",
                  "description": "Tên địa danh (VD: Đại học GTVT) hoặc để trống nếu tìm gần đây",
                },
              },
            },
          },
        },
        {
          "type": "function",
          "function": {
            "name": "select_lot",
            "description": "Chọn bãi đỗ xe từ danh sách đã tìm thấy",
            "parameters": {
              "type": "object",
              "properties": {
                "lot_index": {
                  "type": "integer",
                  "description": "Số thứ tự bãi đỗ (0, 1, 2...)",
                },
              },
            },
          },
        },
        {
          "type": "function",
          "function": {
            "name": "set_time",
            "description": "Thiết lập thời gian bắt đầu và kết thúc đỗ xe",
            "parameters": {
              "type": "object",
              "properties": {
                "start_time": {
                  "type": "string",
                  "description": "Thời gian bắt đầu đỗ xe (ISO8601). Nếu người dùng nói 'bây giờ' hoặc không nói rõ giờ vào, hãy dùng thời gian hệ thống hiện tại.",
                },
                "end_time": {
                  "type": "string",
                  "description": "Thời gian kết thúc đỗ xe (ISO8601). Tính toán dựa trên giờ bắt đầu và khoảng thời gian người dùng muốn đỗ.",
                },
              },
              "required": ["start_time", "end_time"]
            },
          },
        },
      ],
      // Let the model decide whether to call a tool or reply with text
      "tool_choice": "auto",
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAiKey',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final message = data['choices'][0]['message'];
        
        // Trả về toàn bộ message object (có thể chứa content hoặc tool_calls)
        return message;
      } else {
        debugPrint('OpenAI Error: ${response.body}');
      }
    } catch (e) {
      debugPrint('VoiceBooking Error: $e');
    }
    return null;
  }
}
