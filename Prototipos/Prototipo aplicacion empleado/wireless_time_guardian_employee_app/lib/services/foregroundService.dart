import 'dart:async';
import 'dart:isolate';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ForegroundTaskService {
  static init() {
    FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
            channelId: 'foreground_service',
            channelName: 'Foreground Service Notification',
            channelDescription:
                'This notification appears when the foreground service is running.',
            channelImportance: NotificationChannelImportance.LOW,
            priority: NotificationPriority.LOW,
            iconData: const NotificationIconData(
                resType: ResourceType.mipmap,
                resPrefix: ResourcePrefix.ic,
                name: 'launcher'),
            buttons: [
              const NotificationButton(id: 'sendButton', text: 'Send'),
              const NotificationButton(id: "testButton", text: 'Test')
            ]),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: const ForegroundTaskOptions(
          interval: 5000,
          isOnceEvent: false,
          autoRunOnBoot: true,
          allowWakeLock: true,
          allowWifiLock: true,
        ));
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
}

class FirstTaskHandler extends TaskHandler {
  SendPort? _sendPort;

  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
    print('STARTING TASK FROM onStart');
    final customData =
        await FlutterForegroundTask.getData<String>(key: 'customData');
    print('Custom data: $customData');
    sendPort?.send('startTask');
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    sendPort?.send(timestamp);
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) async {
    print('DESTROYING TASK FROM onDestroy');
    FlutterForegroundTask.stopService();
  }

  @override
  void onNotificationButtonPressed(String id) {
    print('Notification button pressed: $id');
    _sendPort?.send("killTask");
  }

  @override
  void onNotificationPressed() {
    print('NOTIFICATION PRESSED');
    _sendPort?.send("onNotificationPressed");
    FlutterForegroundTask.stopService();
  }
}
