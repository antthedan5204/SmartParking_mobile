import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class VoiceBookingService {
  static const String _openAiKey = '';
  static Future<Map<String, dynamic>?> processConversation(
    List<Map<String, dynamic>> chatHistory,
  ) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final payload = {
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "system",
          "content":
              "Bạn là trợ lý thông minh giúp tìm bãi đỗ xe trong hệ thống Smart Parking. Thời gian hệ thống hiện tại là: ${DateTime.now().toIso8601String()}. Nhiệm vụ của bạn:\n1. Nếu người dùng muốn tìm bãi đỗ, gọi search_lots.\n2. Nếu người dùng chọn bãi đỗ, gọi select_lot.\n3. Nếu người dùng nói thời gian đỗ (giờ vào và giờ ra), gọi set_time. Chú ý các cách nói thời gian của người Việt (ví dụ: '8 rưỡi' là 08:30, 'đỗ 2 tiếng', 'đến 5 giờ chiều'). Phải tính toán chính xác start_time và end_time. Luôn trả lời ngắn gọn, thân thiện bằng tiếng Việt.",
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
                  "description":
                      "Tên địa danh (VD: Đại học GTVT) hoặc để trống nếu tìm gần đây",
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
                  "description":
                      "Thời gian bắt đầu đỗ xe (ISO8601). Nếu người dùng nói 'bây giờ' hoặc không nói rõ giờ vào, hãy dùng thời gian hệ thống hiện tại. Chú ý AM/PM.",
                },
                "end_time": {
                  "type": "string",
                  "description":
                      "Thời gian kết thúc đỗ xe (ISO8601). Tính toán dựa trên giờ bắt đầu và khoảng thời gian hoặc giờ kết thúc người dùng muốn đỗ. Ví dụ: '2 tiếng', 'đến 5h chiều'.",
                },
              },
              "required": ["start_time", "end_time"],
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
