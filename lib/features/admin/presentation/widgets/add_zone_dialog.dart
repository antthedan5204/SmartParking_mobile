import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/location_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../parking/domain/entities/parking_lot.dart';
import '../providers/user_management_provider.dart';

class AddZoneDialog extends ConsumerStatefulWidget {
  final ParkingLot? lot;
  const AddZoneDialog({super.key, this.lot});

  @override
  ConsumerState<AddZoneDialog> createState() => _AddZoneDialogState();
}

class _AddZoneDialogState extends ConsumerState<AddZoneDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _slotsController;
  late final TextEditingController _priceController;
  int? _selectedManagerId;
  bool _hasEvStation = false;
  
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.lot?.name);
    _addressController = TextEditingController(text: widget.lot?.address);
    _slotsController = TextEditingController(text: widget.lot?.totalSlots.toString());
    _priceController = TextEditingController(text: widget.lot?.pricePerHour.toStringAsFixed(0));
    _selectedManagerId = widget.lot?.managerId;
    _hasEvStation = widget.lot?.hasEvStation ?? false;
    
    if (widget.lot?.latitude != null && widget.lot?.longitude != null) {
      _selectedLocation = LatLng(widget.lot!.latitude!, widget.lot!.longitude!);
    }

    // Load users only if Admin (to populate manager selection)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAdmin = ref.read(authProvider).user?.isAdmin ?? false;
      if (isAdmin) {
        ref.read(userManagementProvider.notifier).loadUsers();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _slotsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      bool success;
      if (widget.lot != null) {
        success = await ref.read(userManagementProvider.notifier).updateParkingLot(
              id: widget.lot!.id,
              name: _nameController.text.trim(),
              address: _addressController.text.trim(),
              totalSlots: int.parse(_slotsController.text),
              pricePerHour: double.parse(_priceController.text),
              managerId: _selectedManagerId,
              latitude: _selectedLocation?.latitude,
              longitude: _selectedLocation?.longitude,
              hasEvStation: _hasEvStation,
            );
      } else {
        success = await ref.read(userManagementProvider.notifier).createParkingLot(
              name: _nameController.text.trim(),
              address: _addressController.text.trim(),
              totalSlots: int.parse(_slotsController.text),
              pricePerHour: double.parse(_priceController.text),
              managerId: _selectedManagerId,
              latitude: _selectedLocation?.latitude,
              longitude: _selectedLocation?.longitude,
              hasEvStation: _hasEvStation,
            );
      }

      if (mounted && success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _locateAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    setState(() => _isLocating = true);

    final location = await LocationService.getCoordinatesFromAddress(address);

    if (mounted) {
      setState(() {
        _isLocating = false;
        if (location != null) {
          _selectedLocation = location;
          // Ensure map is rendered before moving
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(location, 16);
            }
          });
        } else {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('locationNotFound'))),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final userState = ref.watch(userManagementProvider);
    final isEdit = widget.lot != null;
    
    // Filter managers for the dropdown
    final managers = userState.users.where((u) => u.isManager).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEdit ? l10n.translate('updateParkingLot') : l10n.translate('addParkingLot'),
                  style: AppTextStyles.heading3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('lotNameLabel'),
                    prefixIcon: const Icon(Icons.business_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 16),
                
                // Address
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: l10n.translate('addressLabel'),
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) =>
                            (value == null || value.isEmpty) ? l10n.fieldRequired : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _isLocating ? null : _locateAddress,
                        icon: _isLocating 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.search_rounded, color: AppColors.primary),
                        tooltip: l10n.locateOnMap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Mini Map Picker
                if (_selectedLocation != null) ...[
                  Text(l10n.precisePosition, style: AppTextStyles.caption),
                  const SizedBox(height: 8),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedLocation!,
                        initialZoom: 16,
                        onTap: (tapPosition, point) {
                          setState(() => _selectedLocation = point);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.smartparking.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation!,
                              width: 40,
                              height: 40,
                              alignment: Alignment.topCenter,
                              child: const Icon(Icons.location_on, color: AppColors.danger, size: 40),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                Row(
                  children: [
                    // Total Slots
                    Expanded(
                      child: TextFormField(
                        controller: _slotsController,
                        decoration: InputDecoration(
                          labelText: l10n.translate('totalSlotsLabel'),
                          prefixIcon: const Icon(Icons.local_parking),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return l10n.fieldRequired;
                          if (int.tryParse(value) == null) return l10n.translate('invalidNumber');
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Price
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: l10n.translate('pricePerHourLabel'),
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return l10n.fieldRequired;
                          if (double.tryParse(value) == null) return l10n.translate('invalidNumber');
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // EV Station Toggle
                SwitchListTile(
                  title: Text(l10n.evChargingSpots),
                  value: _hasEvStation,
                  onChanged: (value) {
                    setState(() {
                      _hasEvStation = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                ),
                const SizedBox(height: 16),
                
                // Manager Selection (Only for Admin)
                if (ref.watch(authProvider).user?.isAdmin ?? false) ...[
                  DropdownButtonFormField<int>(
                    value: _selectedManagerId,
                    decoration: InputDecoration(
                      labelText: l10n.translate('managerLabel'),
                      prefixIcon: const Icon(Icons.person_pin_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: managers.map((user) {
                      return DropdownMenuItem<int>(
                        value: user.id,
                        child: Text(user.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedManagerId = value);
                    },
                    validator: (value) => value == null ? l10n.translate('pleaseSelectManager') : null,
                  ),
                ],
                
                if (userState.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    userState.errorMessage!,
                    style: const TextStyle(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: userState.isCreating ? null : () => Navigator.of(context).pop(),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: userState.isCreating ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: userState.isCreating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isEdit ? l10n.translate('update') : l10n.translate('createNew')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
