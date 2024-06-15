import 'dart:async';

class SomeTask {
  Timer? timer;

  void performTask() {
    timer = Timer.periodic(Duration(seconds: 5), (timer) {
      print("Executing in foreground");
    });
  }

  void killTask() {
    timer?.cancel();
  }
}
