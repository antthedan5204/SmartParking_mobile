import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/voice_booking_provider.dart';
import '../pages/select_slot_page.dart';
import '../pages/virtual_payment_page.dart';

void showVoiceBookingDialog(BuildContext context, WidgetRef ref) {
  ref.read(voiceBookingProvider.notifier).reset();

  Navigator.of(context, rootNavigator: true)
      .push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return const VoiceBookingPage();
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      )
      .whenComplete(() {
        ref.read(voiceBookingProvider.notifier).reset();
      });
}

class VoiceBookingPage extends ConsumerStatefulWidget {
  const VoiceBookingPage({super.key});

  @override
  ConsumerState<VoiceBookingPage> createState() => _VoiceBookingPageState();
}

class _VoiceBookingPageState extends ConsumerState<VoiceBookingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Bắt đầu lắng nghe sau khi animation chuyển cảnh hoàn tất (400ms)
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        ref.read(voiceBookingProvider.notifier).startListening();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<VoiceBookingState>(voiceBookingProvider, (previous, next) {
      if (next.step == VoiceBookingStep.confirming &&
          next.status == VoiceBookingStateStatus.success) {
        Navigator.pop(context); // Close the AI page
        if (next.matchedSlot != null) {
          final duration = next.endTime!.difference(next.startTime!);
          final double hours = duration.inMinutes / 60.0;
          final totalPrice = next.matchedLot!.pricePerHour * hours;
          
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => VirtualPaymentPage(
                lot: next.matchedLot!,
                amount: totalPrice,
                selectedSlotId: next.matchedSlot!.id,
                selectedSlotNumber: next.matchedSlot!.slotNumber,
                startTime: next.startTime,
                endTime: next.endTime,
              ),
            ),
          );
        } else {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => SelectSlotPage(
                lot: next.matchedLot!,
                startTime: next.startTime,
                endTime: next.endTime,
              ),
            ),
          );
        }
      }
    });

    final voiceState = ref.watch(voiceBookingProvider);
    final isError = voiceState.status == VoiceBookingStateStatus.error;
    final isListening = voiceState.status == VoiceBookingStateStatus.listening;
    final isSpeaking = voiceState.status == VoiceBookingStateStatus.speaking;
    final isAnalyzing = voiceState.status == VoiceBookingStateStatus.analyzing;

    if (isListening || isSpeaking || isAnalyzing) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }

    return Scaffold(
      backgroundColor: Colors.black, // Dark theme like Gemini
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 32,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Smart AI Assistant',
                          style: AppTextStyles.subtitle2.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 48), // Balance for back button
                  ],
                ),
              ),

              // Chat History / AI message area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // User input display
                      if (voiceState.text.isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24, left: 40),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                                bottomLeft: Radius.circular(24),
                                bottomRight: Radius.circular(4),
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              voiceState.text,
                              style: AppTextStyles.body1.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                      // AI Response
                      if (voiceState.aiMessage.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(
                              bottom: 24,
                              right: 40,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.accent,
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.smart_toy,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(24),
                                        bottomLeft: Radius.circular(24),
                                        bottomRight: Radius.circular(24),
                                      ),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      voiceState.aiMessage,
                                      style: AppTextStyles.body1.copyWith(
                                        color: Colors.white,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Error message
                      if (voiceState.errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  voiceState.errorMessage!,
                                  style: AppTextStyles.body2.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Hybrid UI elements
                      if (voiceState.step == VoiceBookingStep.selectingLot &&
                          voiceState.suggestedLots.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: voiceState.suggestedLots.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final lot = voiceState.suggestedLots[index];
                              return GestureDetector(
                                onTap: () => ref
                                    .read(voiceBookingProvider.notifier)
                                    .selectLotManual(index),
                                child: Container(
                                  width: 180,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          "Bãi ${index + 1}",
                                          style: AppTextStyles.caption.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        lot.name,
                                        style: AppTextStyles.subtitle1.copyWith(
                                          color: Colors.white,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              AppColors.primary,
                                              AppColors.accent,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'Chọn',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      else if (voiceState.step ==
                          VoiceBookingStep.selectingTime)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: Colors.white70,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Hãy nói rõ giờ vào và giờ ra\n(Ví dụ: Từ 16h đến 18h)",
                                textAlign: TextAlign.center,
                                style: AppTextStyles.subtitle1.copyWith(
                                  color: Colors.white,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              OutlinedButton.icon(
                                onPressed: () => _pickStartAndEndTime(context, ref),
                                icon: const Icon(Icons.touch_app),
                                label: const Text("Hoặc chọn thủ công"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom Control Area
              Container(
                padding: const EdgeInsets.only(bottom: 40, top: 20),
                child: Column(
                  children: [
                    Text(
                      _getVoiceStatusText(voiceState.status),
                      style: AppTextStyles.body2.copyWith(
                        color: isError ? Colors.redAccent : Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (voiceState.step != VoiceBookingStep.initial &&
                            !isListening) ...[
                          GestureDetector(
                            onTap: () {
                              ref
                                  .read(voiceBookingProvider.notifier)
                                  .startListening();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              child: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 32),
                        ],

                        // Main Mic Button
                        GestureDetector(
                          onTap: () {
                            if (isListening) {
                              ref
                                  .read(voiceBookingProvider.notifier)
                                  .stopListening();
                            } else {
                              ref
                                  .read(voiceBookingProvider.notifier)
                                  .startListening();
                            }
                          },
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: (isListening || isSpeaking)
                                    ? _pulseAnimation.value
                                    : 1.0,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: isError
                                          ? [Colors.redAccent, Colors.red]
                                          : [
                                              AppColors.primary,
                                              AppColors.accent,
                                            ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (isError
                                                    ? Colors.red
                                                    : AppColors.primary)
                                                .withValues(alpha: 0.4),
                                        blurRadius: 30,
                                        spreadRadius:
                                            (isListening || isSpeaking)
                                            ? 10 * _pulseAnimation.value
                                            : 5,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isListening ? Icons.graphic_eq : Icons.mic,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickStartAndEndTime(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 5))),
      helpText: "CHỌN GIỜ VÀO",
    );
    if (start == null) return;

    if (!context.mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (start.hour + 2) % 24, minute: start.minute),
      helpText: "CHỌN GIỜ RA",
    );
    if (end == null) return;

    // Adjust dates
    var startDate = DateTime(now.year, now.month, now.day, start.hour, start.minute);
    if (startDate.isBefore(now)) {
      startDate = startDate.add(const Duration(days: 1));
    }
    
    var endDate = DateTime(startDate.year, startDate.month, startDate.day, end.hour, end.minute);
    if (endDate.isBefore(startDate) || endDate.isAtSameMomentAs(startDate)) {
      endDate = endDate.add(const Duration(days: 1));
    }

    ref.read(voiceBookingProvider.notifier).setTimeManual(startDate, endDate);
  }

  String _getVoiceStatusText(VoiceBookingStateStatus status) {
    switch (status) {
      case VoiceBookingStateStatus.idle:
        return 'Nhấn vào micro để nói';
      case VoiceBookingStateStatus.listening:
        return 'Đang lắng nghe...';
      case VoiceBookingStateStatus.analyzing:
        return 'AI đang suy nghĩ...';
      case VoiceBookingStateStatus.findingLocation:
        return 'Đang quét bản đồ...';
      case VoiceBookingStateStatus.speaking:
        return 'AI đang trả lời...';
      case VoiceBookingStateStatus.success:
        return 'Hoàn tất!';
      case VoiceBookingStateStatus.error:
        return 'Có lỗi xảy ra, vui lòng thử lại';
    }
  }
}
