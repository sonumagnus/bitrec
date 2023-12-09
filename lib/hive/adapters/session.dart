import 'package:hive/hive.dart';

part 'session.g.dart';

@HiveType(typeId: 3)
class Session {
  Session({
    this.sessionId,
    this.name,
    this.target,
    this.active,
    this.startDateTime,
    this.endDateTime,
  });

  @HiveField(0)
  String? sessionId;

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
