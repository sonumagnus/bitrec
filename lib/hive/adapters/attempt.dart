import 'package:hive/hive.dart';

part 'attempt.g.dart';

@HiveType(typeId: 1)
class Attempt {
  Attempt({
    this.attemptId,
    this.name,
    this.target,
    this.active,
    this.startDateTime,
    this.endDateTime,
  });

  @HiveField(0)
  String? attemptId;

  @HiveField(1)
  String? name;

  @HiveField(2)
  int? target;

  @HiveField(3)
  bool? active;

  @HiveField(4)
  DateTime? startDateTime;

  @HiveField(5)
  DateTime? endDateTime;
}
