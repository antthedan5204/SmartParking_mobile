import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong2/latlong.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../../core/services/voice_booking_service.dart';
import '../../../../core/services/location_service.dart';
import 'parking_provider.dart';
import '../../domain/entities/parking_lot.dart';
import '../../domain/entities/parking_slot.dart';

enum VoiceBookingStateStatus {
  idle,
  listening,
  analyzing,
  findingLocation,
  speaking,
  success,
  error,
}

enum VoiceBookingStep {
  initial,
  selectingLot,
  selectingTime,
  confirming,
}

class VoiceBookingState {
  final VoiceBookingStateStatus status;
  final VoiceBookingStep step;
  final String text; // Tin nhắn người dùng
  final String aiMessage; // Lời nói của AI
  final String? errorMessage;
  
  // Data
  final List<ParkingLot> suggestedLots;
  final ParkingLot? matchedLot; // used as selectedLot
  final ParkingSlot? matchedSlot; // chosen automatically
  final DateTime? startTime;
  final DateTime? endTime;
  final double? distanceInMeters;

  const VoiceBookingState({
    this.status = VoiceBookingStateStatus.idle,
    this.step = VoiceBookingStep.initial,
    this.text = '',
    this.aiMessage = '',
    this.errorMessage,
    this.suggestedLots = const [],
    this.matchedLot,
    this.matchedSlot,
    this.startTime,
    this.endTime,
    this.distanceInMeters,
  });

  VoiceBookingState copyWith({
    VoiceBookingStateStatus? status,
    VoiceBookingStep? step,
    String? text,
    String? aiMessage,
    String? errorMessage,
    List<ParkingLot>? suggestedLots,
    ParkingLot? matchedLot,
    ParkingSlot? matchedSlot,
    DateTime? startTime,
    DateTime? endTime,
    double? distanceInMeters,
  }) {
    return VoiceBookingState(
      status: status ?? this.status,
      step: step ?? this.step,
      text: text ?? this.text,
      aiMessage: aiMessage ?? this.aiMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      suggestedLots: suggestedLots ?? this.suggestedLots,
      matchedLot: matchedLot ?? this.matchedLot,
      matchedSlot: matchedSlot ?? this.matchedSlot,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distanceInMeters: distanceInMeters ?? this.distanceInMeters,
    );
  }
}

class VoiceBookingNotifier extends StateNotifier<VoiceBookingState> {
  final Ref ref;
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _speechEnabled = false;

  bool _isInitializing = false;

  VoiceBookingNotifier(this.ref) : super(const VoiceBookingState()) {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("vi-VN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    state = state.copyWith(status: VoiceBookingStateStatus.speaking, aiMessage: text);
    await _flutterTts.speak(text);
  }

  Future<void> startListening() async {
    if (!_speechEnabled && !_isInitializing) {
      _isInitializing = true;
      try {
        _speechEnabled = await _speechToText.initialize(
          onStatus: (status) {
            if (status == 'notListening' || status == 'done') {
              if (state.status == VoiceBookingStateStatus.listening) {
                if (state.text.isNotEmpty) {
                  _processVoiceCommand(state.text);
                } else {
                  state = state.copyWith(status: VoiceBookingStateStatus.idle);
                }
              }
            }
          },
          onError: (error) {
            String friendlyMsg = 'Lỗi mic: ${error.errorMsg}';
            if (error.errorMsg == 'error_speech_timeout') {
              friendlyMsg = 'Không nghe thấy bạn nói gì. Vui lòng thử lại!';
            } else if (error.errorMsg == 'error_no_match') {
              friendlyMsg = 'Không nhận diện được. Vui lòng nói rõ hơn!';
            }
            state = state.copyWith(
              status: VoiceBookingStateStatus.error,
              errorMessage: friendlyMsg,
            );
          },
        );
      } catch (e) {
        debugPrint('Lỗi khởi tạo mic: $e');
      } finally {
        _isInitializing = false;
      }

      if (!_speechEnabled) {
        state = state.copyWith(
          status: VoiceBookingStateStatus.error,
          errorMessage: 'Không có quyền sử dụng Microphone',
        );
        return;
      }
    }

    state = state.copyWith(status: VoiceBookingStateStatus.listening);
    await _speechToText.listen(
      onResult: (result) {
        state = state.copyWith(text: result.recognizedWords);
        // Only process when user stops speaking and result is final
        if (result.finalResult) {
          _processVoiceCommand(result.recognizedWords);
        }
      },
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    if (state.status == VoiceBookingStateStatus.listening) {
      if (state.text.isNotEmpty) {
        _processVoiceCommand(state.text);
      } else {
        state = state.copyWith(status: VoiceBookingStateStatus.idle);
      }
    }
  }

  final List<Map<String, dynamic>> _chatHistory = [];

  Future<void> _processVoiceCommand(String command) async {
    if (command.isEmpty) {
      state = state.copyWith(
        status: VoiceBookingStateStatus.error,
        errorMessage: 'Không nghe rõ lệnh của bạn',
      );
      return;
    }

    state = state.copyWith(status: VoiceBookingStateStatus.analyzing);

    // Add user message to history
    _chatHistory.add({"role": "user", "content": command});

    final message = await VoiceBookingService.processConversation(_chatHistory);

    if (message == null) {
      state = state.copyWith(
        status: VoiceBookingStateStatus.error,
        errorMessage: 'Không thể phản hồi',
      );
      return;
    }

    final safeMessage = {
      "role": "assistant",
      "content": message["content"],
    };
    if (message["tool_calls"] != null) {
      safeMessage["tool_calls"] = message["tool_calls"];
    }
    _chatHistory.add(safeMessage);

    if (message['tool_calls'] != null) {
      final toolCalls = message['tool_calls'] as List;
      for (var toolCall in toolCalls) {
        final toolName = toolCall['function']['name'];
        final argsStr = toolCall['function']['arguments'];
        
        Map<String, dynamic> args = {};
        try {
          args = json.decode(argsStr);
        } catch (e) {
          // Parse error
        }

        if (toolName == 'search_lots') {
          await _handleSearchLots(args, toolCall['id']);
        } else if (toolName == 'select_lot') {
          await _handleSelectLot(args, toolCall['id']);
        } else if (toolName == 'set_time') {
          await _handleSetTime(args, toolCall['id']);
        }
      }
      
      await _evaluateStateAndRespond();
    } else if (message['content'] != null) {
      // Just a normal text response
      final aiText = message['content'].toString();
      await _speak(aiText);
      state = state.copyWith(status: VoiceBookingStateStatus.idle);
    }
  }

  Future<void> _handleSearchLots(Map<String, dynamic> intent, String toolCallId) async {
    final lots = ref.read(parkingLotsProvider).lots;
    if (lots.isEmpty) {
      _addSystemToolResponse(toolCallId, "Chưa tải được danh sách bãi đỗ");
      return;
    }

    ParkingLot? closestLot;
    double minDistance = double.infinity;
    List<ParkingLot> foundLots = [];

    if (intent.containsKey('lot_name') &&
        intent['lot_name'] != null &&
        intent['lot_name'].toString().isNotEmpty) {
      final lotName = intent['lot_name'].toString().toLowerCase();
      for (var lot in lots) {
        if (lot.name.toLowerCase().contains(lotName)) {
          foundLots.add(lot);
        }
      }
    } else {
      final locationQuery = intent['near_location']?.toString().toLowerCase() ?? '';
      LatLng? targetLatLng;
      final genericKeywords = ['gần', 'gần đây', 'quanh đây', 'hiện tại', 'đây', 'chỗ này'];

      if (locationQuery.isNotEmpty && !genericKeywords.contains(locationQuery)) {
        targetLatLng = await LocationService.getCoordinatesFromAddress(locationQuery);
      }

      if (targetLatLng == null) {
        final pos = await LocationService.getCurrentPosition();
        if (pos != null) {
          targetLatLng = LatLng(pos.latitude, pos.longitude);
        }
      }

      if (targetLatLng != null) {
        // Sort lots by distance
        final lotDistances = lots.where((l) => l.latitude != null && l.longitude != null).map((l) {
          final dist = LocationService.calculateDistance(
            targetLatLng!,
            LatLng(l.latitude!, l.longitude!),
          );
          return {'lot': l, 'dist': dist};
        }).toList();

        lotDistances.sort((a, b) => (a['dist'] as double).compareTo(b['dist'] as double));
        foundLots = lotDistances.take(3).map((e) => e['lot'] as ParkingLot).toList();
        if (foundLots.isNotEmpty) {
          minDistance = lotDistances.first['dist'] as double;
        }
      }
    }

    if (foundLots.isNotEmpty) {
      state = state.copyWith(
        suggestedLots: foundLots,
        distanceInMeters: minDistance * 1000,
      );
      
      final names = foundLots.map((l) => l.name).join(", ");
      final msg = "Đã tìm thấy các bãi đỗ: $names.";
      _addSystemToolResponse(toolCallId, msg);
    } else {
      state = state.copyWith(suggestedLots: []);
      _addSystemToolResponse(toolCallId, "Không tìm thấy bãi đỗ");
    }
  }

  Future<void> _handleSelectLot(Map<String, dynamic> args, String toolCallId) async {
    final index = args['lot_index'] as int?;
    if (index != null && index >= 0 && index < state.suggestedLots.length) {
      final lot = state.suggestedLots[index];
      state = state.copyWith(matchedLot: lot);
      _addSystemToolResponse(toolCallId, "Đã chọn bãi đỗ ${lot.name}");
    } else {
      _addSystemToolResponse(toolCallId, "Chỉ mục bãi đỗ không hợp lệ");
    }
  }

  Future<ParkingSlot?> _pickRandomAvailableSlot() async {
    if (state.matchedLot == null) return null;
    try {
      final slots = await ref.read(parkingSlotsProvider(state.matchedLot!.id).future);
      final availableSlots = slots.where((s) => s.isAvailable == true).toList();
      if (availableSlots.isNotEmpty) {
        availableSlots.shuffle();
        return availableSlots.first;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _handleSetTime(Map<String, dynamic> args, String toolCallId) async {
    final startTimeStr = args['start_time'] as String?;
    final endTimeStr = args['end_time'] as String?;
    
    if (startTimeStr != null && endTimeStr != null) {
      try {
        final startTime = DateTime.parse(startTimeStr);
        final endTime = DateTime.parse(endTimeStr);
        
        state = state.copyWith(
          startTime: startTime,
          endTime: endTime,
        );
        _addSystemToolResponse(toolCallId, "Đã thiết lập thời gian");
      } catch (e) {
        _addSystemToolResponse(toolCallId, "Lỗi định dạng thời gian");
      }
    } else {
      _addSystemToolResponse(toolCallId, "Thiếu thời gian");
    }
  }

  Future<void> _evaluateStateAndRespond() async {
    if (state.matchedLot != null && state.startTime != null && state.endTime != null) {
      // Đã có đủ thông tin bãi đỗ và thời gian
      final randomSlot = await _pickRandomAvailableSlot();
      state = state.copyWith(
        step: VoiceBookingStep.confirming,
        matchedSlot: randomSlot,
        status: VoiceBookingStateStatus.success,
      );
      await _speak("Đã đủ thông tin đỗ xe. Chuẩn bị thanh toán...");
    } else if (state.matchedLot != null && (state.startTime == null || state.endTime == null)) {
      // Đã chọn bãi, thiếu thời gian
      state = state.copyWith(step: VoiceBookingStep.selectingTime, status: VoiceBookingStateStatus.idle);
      await _speak("Bạn đã chọn ${state.matchedLot!.name}. Bạn muốn đỗ từ mấy giờ đến mấy giờ?");
    } else if (state.suggestedLots.isNotEmpty && state.matchedLot == null) {
      // Đã tìm thấy các bãi đỗ, cần người dùng chọn
      state = state.copyWith(step: VoiceBookingStep.selectingLot, status: VoiceBookingStateStatus.idle);
      if (state.startTime != null && state.endTime != null) {
        await _speak("Tôi đã nhận thời gian đỗ. Tôi tìm thấy ${state.suggestedLots.length} bãi đỗ xe phù hợp gần đó. Bạn chọn bãi số mấy?");
      } else {
        await _speak("Tôi tìm thấy ${state.suggestedLots.length} bãi đỗ xe phù hợp. Bạn muốn chọn bãi số mấy?");
      }
    } else {
      // Không tìm thấy gì cả
      state = state.copyWith(status: VoiceBookingStateStatus.error);
      await _speak("Xin lỗi, tôi không tìm thấy bãi đỗ xe nào phù hợp. Bạn thử địa điểm khác nhé.");
    }
  }

  void _addSystemToolResponse(String toolCallId, String content) {
    _chatHistory.add({
      "role": "tool",
      "tool_call_id": toolCallId,
      "content": content,
    });
  }

  void reset() {
    _flutterTts.stop();
    _speechToText.stop();
    _chatHistory.clear();
    state = const VoiceBookingState();
  }

  // --- Hybrid Methods (For manual touch input) ---
  Future<void> selectLotManual(int index) async {
    if (index >= 0 && index < state.suggestedLots.length) {
      final lot = state.suggestedLots[index];
      _chatHistory.add({"role": "user", "content": "Tôi chọn bãi đỗ ${lot.name}"});
      
      state = state.copyWith(matchedLot: lot);
      await _evaluateStateAndRespond();
    }
  }

  Future<void> setTimeManual(DateTime startDate, DateTime endDate) async {
    _chatHistory.add({"role": "user", "content": "Tôi muốn đỗ từ ${startDate.hour}:${startDate.minute} đến ${endDate.hour}:${endDate.minute}"});
    
    state = state.copyWith(
      startTime: startDate,
      endTime: endDate,
    );
    await _evaluateStateAndRespond();
  }
}

final voiceBookingProvider =
    StateNotifierProvider<VoiceBookingNotifier, VoiceBookingState>((ref) {
      return VoiceBookingNotifier(ref);
    });
