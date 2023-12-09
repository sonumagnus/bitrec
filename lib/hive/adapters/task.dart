import 'package:bitrec/hive/adapters/session.dart';
import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 2)
class Task {
  Task({this.taskId, this.name, this.sessions});

  @HiveField(0)
  String? taskId;

  @HiveField(1)
  String? name;

  @HiveField(2)
  DateTime? createDate;

  @HiveField(3)
  List<Session>? sessions;
}
