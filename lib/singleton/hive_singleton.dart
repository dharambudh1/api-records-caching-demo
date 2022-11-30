import 'package:api_caching/model/pokemon.dart';
import 'package:api_caching/model/results.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveSingleton {
  static final HiveSingleton _singleton = HiveSingleton._internal();
  factory HiveSingleton() {
    return _singleton;
  }

  HiveSingleton._internal() {
    Hive.registerAdapter<Pokemon>(PokemonAdapter());
    Hive.registerAdapter<Results>(ResultsAdapter());
  }

  late Box<Pokemon> pokemonBox;
  late Box<Results> resultsBox;

  Future<void> initHiveSingleton() async {
    pokemonBox = await Hive.openBox<Pokemon>("PokemonAdapter");
    resultsBox = await Hive.openBox<Results>("ResultsAdapter");
    return Future.value();
  }
}
