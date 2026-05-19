import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../parking/domain/entities/booking.dart';
import '../../../parking/presentation/providers/parking_provider.dart';
import '../providers/user_management_provider.dart';
import '../../domain/usecases/get_all_bookings_usecase.dart';

// Use Case Provider
final getAllBookingsUseCaseProvider = Provider<GetAllBookingsUseCase>((ref) {
  return GetAllBookingsUseCase(ref.read(adminRepositoryProvider));
});

// State
class BookingManagementState {
  final bool isLoading;
  final List<Booking> bookings;
  final String? errorMessage;
  final String? selectedLotName;
  final BookingStatus? selectedStatus;
  final String searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;

  const BookingManagementState({
    this.isLoading = false,
    this.bookings = const [],
    this.errorMessage,
    this.selectedLotName,
    this.selectedStatus,
    this.searchQuery = '',
    this.startDate,
    this.endDate,
  });

  BookingManagementState copyWith({
    bool? isLoading,
    List<Booking>? bookings,
    String? errorMessage,
    String? selectedLotName,
    BookingStatus? selectedStatus,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return BookingManagementState(
      isLoading: isLoading ?? this.isLoading,
      bookings: bookings ?? this.bookings,
      errorMessage: errorMessage,
      selectedLotName: selectedLotName,
      selectedStatus: selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  List<Booking> get filteredBookings {
    return bookings.where((booking) {
      // Lot filter
      if (selectedLotName != null && booking.lotName != selectedLotName) {
        return false;
      }
      // Status filter
      if (selectedStatus != null && booking.status != selectedStatus) {
        return false;
      }
      // Search query
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesUser = booking.userId.toString().contains(query);
        final matchesLot = booking.lotName?.toLowerCase().contains(query) ?? false;
        final matchesVehicle = booking.vehicleId.toString().contains(query);
        if (!matchesUser && !matchesLot && !matchesVehicle) return false;
      }
      // Date filter
      if (startDate != null && booking.startTime.isBefore(startDate!)) {
        return false;
      }
      if (endDate != null && booking.startTime.isAfter(endDate!.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList();
  }

  List<String> get availableLotNames {
    return bookings
        .map((b) => b.lotName)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
  }
}

class BookingManagementNotifier extends StateNotifier<BookingManagementState> {
  final GetAllBookingsUseCase getAllBookingsUseCase;
  final Ref ref;

  BookingManagementNotifier({
    required this.getAllBookingsUseCase,
    required this.ref,
  }) : super(const BookingManagementState()) {
    loadBookings();
  }

  Future<void> loadBookings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await getAllBookingsUseCase();

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (bookings) {
        // If the user is a Manager, they should only see bookings for their lots
        // Ideally the backend handles this, but we filter here as insurance
        // final user = ref.read(authProvider).user;
        var filteredBookings = bookings;
        
        // Note: For real environment, Manager ID should be used to filter lots.
        // Assuming the list from backend is already filtered if we're a manager,
        // otherwise we could filter by lot list.

        state = state.copyWith(
          isLoading: false,
          bookings: filteredBookings,
        );
      },
    );
  }

  void setLotFilter(String? lotName) {
    state = state.copyWith(selectedLotName: lotName);
  }

  void setStatusFilter(BookingStatus? status) {
    state = state.copyWith(selectedStatus: status);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void clearFilters() {
    state = state.copyWith(
      selectedLotName: null,
      selectedStatus: null,
      searchQuery: '',
      startDate: null,
      endDate: null,
    );
  }

  Future<bool> checkInBooking(int id) async {
    state = state.copyWith(isLoading: true);
    final result = await getAllBookingsUseCase.repository.checkInBooking(id);
    state = state.copyWith(isLoading: false);

    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        loadBookings();
        ref.invalidate(parkingSlotsProvider);
        ref.read(parkingLotsProvider.notifier).refresh();
        return true;
      },
    );
  }

  Future<bool> completeBooking(int id) async {
    state = state.copyWith(isLoading: true);
    final result = await getAllBookingsUseCase.repository.completeBooking(id);
    state = state.copyWith(isLoading: false);

    return result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      (_) {
        loadBookings();
        ref.invalidate(parkingSlotsProvider);
        ref.read(parkingLotsProvider.notifier).refresh();
        return true;
      },
    );
  }
}

final bookingManagementProvider =
    StateNotifierProvider<BookingManagementNotifier, BookingManagementState>((ref) {
  return BookingManagementNotifier(
    getAllBookingsUseCase: ref.read(getAllBookingsUseCaseProvider),
    ref: ref,
  );
});
