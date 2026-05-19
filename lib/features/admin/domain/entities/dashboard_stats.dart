import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int totalSlots;
  final int availableSlots;
  final double occupancyPercent;
  final double revenue7Days;
  final List<DailyStats> dailyStats;
  final List<HourlyOccupancy> hourlyOccupancy;

  const DashboardStats({
    required this.totalSlots,
    required this.availableSlots,
    required this.occupancyPercent,
    required this.revenue7Days,
    this.dailyStats = const [],
    this.hourlyOccupancy = const [],
  });

  @override
  List<Object?> get props => [
        totalSlots, availableSlots, occupancyPercent,
        revenue7Days, dailyStats, hourlyOccupancy,
      ];
}

class DailyStats extends Equatable {
  final String day;
  final double revenue;
  final double occupancy;

  const DailyStats({
    required this.day,
    required this.revenue,
    required this.occupancy,
  });

  @override
  List<Object?> get props => [day, revenue, occupancy];
}

class HourlyOccupancy extends Equatable {
  final int hour;
  final double occupancy;

  const HourlyOccupancy({
    required this.hour,
    required this.occupancy,
  });

  @override
  List<Object?> get props => [hour, occupancy];
}
