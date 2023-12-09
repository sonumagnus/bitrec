import 'package:bitrec/hive/adapters/attempt.dart';
import 'package:hive/hive.dart';

part 'streak.g.dart';

@HiveType(typeId: 0)
class Streak {
  Streak({this.streakId, this.name, this.attempts});

  @HiveField(0)
  String? streakId;

  @HiveField(1)
  String? name;

  @HiveField(2)
  List<Attempt>? attempts;
}
