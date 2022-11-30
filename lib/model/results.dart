import 'package:hive/hive.dart';

part 'results.g.dart';

@HiveType(typeId: 1)
class Results {
  Results({
    this.name,
    this.url,
  });

  Results.fromJson(dynamic json) {
    name = json['name'];
    url = json['url'];
  }

  @HiveField(0)
  String? name;

  @HiveField(1)
  String? url;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['url'] = url;
    return map;
  }
}
