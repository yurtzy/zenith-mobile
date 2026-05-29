import 'package:hive/hive.dart';

part 'streak_history.g.dart';

@HiveType(typeId: 1)
class StreakHistory extends HiveObject {
  @HiveField(0)
  final DateTime startDate;

  @HiveField(1)
  final DateTime endDate;

  @HiveField(2)
  final int durationDays;

  StreakHistory({
    required this.startDate,
    required this.endDate,
    required this.durationDays,
  });

  Map<String, dynamic> toJson() => {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'durationDays': durationDays,
      };

  factory StreakHistory.fromJson(Map<String, dynamic> json) => StreakHistory(
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        durationDays: json['durationDays'],
      );
}
