import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/vehicle_provider.dart';

class VehicleManagementPage extends ConsumerWidget {
  const VehicleManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleState = ref.watch(vehicleProvider);

    // Lắng nghe lỗi và hiển thị SnackBar
    ref.listen<VehicleState>(vehicleProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Quản lý biển số xe',
          style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: vehicleState.isLoading && vehicleState.vehicles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : vehicleState.vehicles.isEmpty
              ? _buildEmptyState(context)
              : _buildVehicleList(context, ref, vehicleState),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVehicleDialog(context, ref),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Thêm xe mới',
          style: AppTextStyles.buttonSmall.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              size: 80,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có biển số xe nào',
            style: AppTextStyles.heading3.copyWith(
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Hãy thêm biển số xe của bạn để có thể thực hiện đặt chỗ bãi đỗ xe.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body2.copyWith(
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleList(BuildContext context, WidgetRef ref, VehicleState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: state.vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = state.vehicles[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.directions_car_rounded, color: Color(0xFF1E293B)),
            ),
            title: Text(
              vehicle.licensePlate,
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            subtitle: Text(
              'Loại xe: ${vehicle.model}',
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF64748B),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              onPressed: () => _confirmDelete(context, ref, vehicle.id),
            ),
          ),
        );
      },
    );
  }

  void _showAddVehicleDialog(BuildContext context, WidgetRef ref) {
    final plateController = TextEditingController();
    final modelController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          top: 32,
          left: 24,
          right: 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thêm biển số xe mới',
                  style: AppTextStyles.heading3.copyWith(
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhập chính xác biển số để hệ thống nhận diện khi bạn vào bãi.',
                  style: AppTextStyles.caption.copyWith(color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                _buildDialogField(
                  label: 'Biển số xe',
                  hint: 'Ví dụ: 30A-123.45',
                  controller: plateController,
                  icon: Icons.badge_rounded,
                  validator: (val) => (val == null || val.isEmpty) ? 'Vui lòng nhập biển số' : null,
                ),
                const SizedBox(height: 16),
                _buildDialogField(
                  label: 'Loại xe / Hiệu xe',
                  hint: 'Ví dụ: Toyota Camry',
                  controller: modelController,
                  icon: Icons.category_rounded,
                  validator: (val) => (val == null || val.isEmpty) ? 'Vui lòng nhập loại xe' : null,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final success = await ref.read(vehicleProvider.notifier).addVehicle(
                              licensePlate: plateController.text.trim(),
                              model: modelController.text.trim(),
                            );
                        if (context.mounted && success) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      'XÁC NHẬN THÊM',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          style: AppTextStyles.body1,
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Xóa biển số xe?', style: AppTextStyles.subtitle1),
        content: const Text('Bạn có chắc chắn muốn xóa biển số xe này khỏi danh sách quản lý không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('HỦY', style: AppTextStyles.label.copyWith(color: const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(vehicleProvider.notifier).deleteVehicle(id);
            },
            child: Text('XÓA', style: AppTextStyles.label.copyWith(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
