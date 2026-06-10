class ApiEndpoints {
  ApiEndpoints._();

  // ── Địa chỉ Backend ──────────────────────────────────────────────
  // Thiết bị thật + hotspot/WiFi: đổi IP bên dưới thành IP của laptop
  //   → Mở cmd/terminal, gõ: ipconfig  → lấy dòng "IPv4 Address"
  // Android Emulator: để nguyên 10.0.2.2
  // ───────────────────────────────────────────────────────────────────
  static const String baseUrl = 'https://parkingmanagement-fco2.onrender.com';
  static final String notificationHub = '$baseUrl/notificationHub';

  // Auth
  static const String login = '/api/Auth/login';
  static const String register = '/api/Auth/register';
  static const String googleLogin = '/api/Auth/google-login';
  static const String forgotPassword = '/api/Auth/forgot-password';
  static const String verifyResetToken = '/api/Auth/verify-reset-token';
  static const String resetPassword = '/api/Auth/reset-password';
  static const String verifyEmail = '/api/Auth/verify-email';
  static const String sendVerificationEmail =
      '/api/Auth/send-verification-email';

  // Users
  static const String users = '/api/Users';
  static const String createStaff = '/api/Users/staff';
  static const String userProfile = '/api/Users/profile';
  static String userById(int id) => '/api/Users/$id';

  // Parking Lots
  static const String parkingLots = '/api/parking-lots';
  static String parkingLotById(int id) => '/api/parking-lots/$id';

  // Parking Slots
  static const String parkingSlots = '/api/parking-slots';
  static String parkingSlotsByLot(int lotId) =>
      '/api/parking-slots/by-lot/$lotId';
  static String parkingSlotById(int id) => '/api/parking-slots/$id';
  static String parkingSlotStatus(int id) => '/api/parking-slots/$id/status';

  // Bookings
  static const String bookings = '/api/Bookings';
  static const String allBookings = '/api/Bookings/all';
  static String bookingById(int id) => '/api/Bookings/$id';
  static String cancelBooking(int id) => '/api/Bookings/$id/cancel';
  static String checkinBooking(int id) => '/api/Bookings/$id/checkin';
  static String completeBooking(int id) => '/api/Bookings/$id/complete';

  // Reports
  static const String exportPdf = '$baseUrl/api/Reports/export-pdf';
  static const String exportExcel = '$baseUrl/api/Reports/export-excel';

  // Payments
  static const String payments = '/api/Payments';
  static String paymentById(int id) => '/api/Payments/$id';
  static String paymentByBooking(int bookingId) =>
      '/api/Payments/by-booking/$bookingId';

  // Vehicles
  static const String vehicles = '/api/Vehicles';
  static String vehicleById(int id) => '/api/Vehicles/$id';
}
