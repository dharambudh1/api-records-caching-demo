import 'package:rxdart/rxdart.dart';

class Bloc {
  Bloc() {
    loadingFunction(false);
  }

  final loadingBehaviour = BehaviorSubject<bool>();

  Function(bool) get loadingFunction {
    return loadingBehaviour.sink.add;
  }
}
