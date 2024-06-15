// import 'dart:async';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:uuid/uuid.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:elegant_notification/elegant_notification.dart';
// import 'dart:convert';


// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'UUID App',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: const MyHomePage(),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key});

//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   String? uuid;
//   String? serverIP;
//   DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//   //StompClient? client;
//   WebSocketChannel? channel;

//   @override
//   void initState() {
//     super.initState();
//     _getSavedUUID();
//     _startListeningForServerIP();
//     _connectWebSocket();
//   }

//   @override
//   void dispose() {
//     channel?.sink.close();
//     super.dispose();
//   }

//   void _startListeningForServerIP() {
//     Timer.periodic(const Duration(seconds: 1), (_) {
//       if (serverIP == null) {
//         _getServerIP();
//       }
//     });
//   }

//   void _getServerIP() async {
//     await _getServerIPBroadcast();
//   }

//   Future<String> _getServerIPBroadcast() async {
//     RawDatagramSocket? socket;
//     try {
//       socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 12345);
//       socket.listen((RawSocketEvent event) {
//         if (event == RawSocketEvent.read) {
//           Datagram? packet = socket!.receive();
//           if (packet != null) {
//             String ip = utf8.decode(packet.data);
//             socket.close();
//             setState(() {
//               serverIP = ip;
//             });
//             return;
//           }
//         }
//       });
//       socket.broadcastEnabled = true;
//       socket.send(utf8.encode(''), InternetAddress('255.255.255.255'), 12345);
//     } catch (e) {
//       print('Error al obtener la dirección IP del servidor: $e');
//       socket?.close();
//       return '';
//     }
//     return '';
//   }

//   void _notifyConnection() {
//     ElegantNotification(
//       title: const Text('Conexión establecida'),
//       description: const Text('Se ha establecido la conexión con el servidor'),
//       icon: const Icon(
//         Icons.connect_without_contact,
//         color: Colors.green,
//       ),
//     ).show(context);
//   }

//   void _connectWebSocket() {
//     if (serverIP != null) {
//       channel = WebSocketChannel.connect(
//         Uri.parse('ws://${serverIP!}:8080/ws'),
//       );

//       _notifyConnection();

//       channel!.stream.listen((message) {
//         ElegantNotification(
//           title: const Text('Roll Call'),
//           description: const Text('Se ha recibido un mensaje de roll call'),
//           icon: const Icon(
//             Icons.notifications,
//             color: Colors.blue,
//           ),
//         ).show(context);

//         sendMessage();
//       });
//     } else {
//       Timer(const Duration(seconds: 5), () {
//         _connectWebSocket();
//       });
//     }
//   }

//   void sendMessage() {
//     if (uuid != null && channel != null) {
//       final message = {'content': uuid};
//       channel!.sink.add(jsonEncode(message));
//     }
//     print('MENSAJE ENVIADO');
//   }

//   _getSavedUUID() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       uuid = prefs.getString('uuid');
//       if (uuid == null) {
//         uuid = const Uuid().v4();
//         prefs.setString('uuid', uuid!);
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('UUID App'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'UUID del dispositivo:',
//             ),
//             Text(
//               uuid ?? 'Cargando...',
//               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             //Show device info
//             //ternary operator if device is android or ios

//             FutureBuilder(
//               future: deviceInfo.androidInfo,
//               builder: (context, AsyncSnapshot<AndroidDeviceInfo> snapshot) {
//                 if (snapshot.hasData) {
//                   return Column(
//                     children: [
//                       const SizedBox(height: 20),
//                       const Text(
//                         'Información del dispositivo:',
//                       ),
//                       Text(
//                         'Modelo: ${snapshot.data!.model}',
//                         style: const TextStyle(fontSize: 16),
//                       ),
//                       Text(
//                         'Marca: ${snapshot.data!.manufacturer}',
//                         style: const TextStyle(fontSize: 16),
//                       ),
//                       Text(
//                         'Versión de Android: ${snapshot.data!.version.release}',
//                         style: const TextStyle(fontSize: 16),
//                       ),
//                       //more info
//                       Text(
//                         'ID: ${snapshot.data!.id}',
//                         style: const TextStyle(fontSize: 16),
//                       ),
//                       Text(
//                         'Tipo: ${snapshot.data!.type}',
//                         style: const TextStyle(fontSize: 16),
//                       ),
//                       Text(
//                         'Versión de la base de datos: ${snapshot.data!.version.incremental}',
//                         style: const TextStyle(fontSize: 16),
//                       ),
//                       TextButton(
//                         onPressed: sendMessage,
//                         child: const Text('Enviar mensaje de roll call'),
//                       ),         
//                     ],
//                   );
//                 } else {
//                   return const CircularProgressIndicator();
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void main() {
  runApp(const MyApp());
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  WebSocketChannel? _channel;
  String? _uuid;

  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    final prefs = await SharedPreferences.getInstance();
    _uuid = prefs.getString('uuid');

    final serverIP = await FlutterForegroundTask.getData<String>(key: 'serverIP');
    if (serverIP != null) {
      _connectWebSocket(serverIP);
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {
    FlutterForegroundTask.updateService(
      notificationTitle: 'WebSocket Service',
      notificationText: 'Running',
    );
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) async {
    _channel?.sink.close();
  }

  void _connectWebSocket(String serverIP) {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://$serverIP:8080/ws'),
    );

    _channel!.stream.listen((message) {
      if (_sendPort != null) {
        _sendPort!.send('Received message: $message');
      }
      sendMessage();
    });
  }

  void sendMessage() {
    if (_uuid != null && _channel != null) {
      final message = {'content': _uuid};
      _channel!.sink.add(jsonEncode(message));
       print(message);
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UUID App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? uuid;
  String? serverIP;
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  WebSocketChannel? channel;
  ReceivePort? _receivePort;

  @override
  void initState() {
    super.initState();
    _initForegroundTask();
    _getSavedUUID();
    _startListeningForServerIP();
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription: 'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
          backgroundColor: Colors.orange,
        ),
        buttons: [
          const NotificationButton(
            id: 'sendButton',
            text: 'Send',
            textColor: Colors.orange,
          ),
          const NotificationButton(
            id: 'testButton',
            text: 'Test',
            textColor: Colors.grey,
          ),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  @override
  void dispose() {
    _closeReceivePort();
    channel?.sink.close();
    super.dispose();
  }

  void _startListeningForServerIP() {
    Timer.periodic(const Duration(seconds: 1), (_) {
      if (serverIP == null) {
        _getServerIP();
      }
    });
  }

  void _getServerIP() async {
    await _getServerIPBroadcast();
  }

  Future<String> _getServerIPBroadcast() async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 12345);
      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? packet = socket!.receive();
          if (packet != null) {
            String ip = utf8.decode(packet.data);
            socket.close();
            setState(() {
              serverIP = ip;
            });

            _startForegroundTask();
            _notifyConnection();
            //_connectWebSocket();
            return;
          }
        }
      });
      socket.broadcastEnabled = true;
      socket.send(utf8.encode(''), InternetAddress('255.255.255.255'), 12345);
    } catch (e) {
      print('Error al obtener la dirección IP del servidor: $e');
      socket?.close();
      return '';
    }
    return '';
  }

  void _notifyConnection() {
    ElegantNotification(
      title: const Text('Conexión establecida'),
      description: const Text('Se ha establecido la conexión con el servidor'),
      icon: const Icon(
        Icons.connect_without_contact,
        color: Colors.green,
      ),
    ).show(context);
  }

  void _connectWebSocket() {
    if (serverIP != null) {
      channel = WebSocketChannel.connect(
        Uri.parse('ws://${serverIP!}:8080/ws'),
      );

      _notifyConnection();

      channel!.stream.listen((message) {
        ElegantNotification(
          title: const Text('Roll Call'),
          description: const Text('Se ha recibido un mensaje de roll call'),
          icon: const Icon(
            Icons.notifications,
            color: Colors.blue,
          ),
        ).show(context);

        sendMessage();
      });

      _startForegroundTask();
    } else {
      Timer(const Duration(seconds: 5), () {
        _connectWebSocket();
      });
    }
  }

  void sendMessage() {
    if (uuid != null && channel != null) {
      final message = {'content': uuid};
      channel!.sink.add(jsonEncode(message));
    }
    print('MENSAJE ENVIADO');
  }

  Future<void> _getSavedUUID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      uuid = prefs.getString('uuid');
      if (uuid == null) {
        uuid = const Uuid().v4();
        prefs.setString('uuid', uuid!);
      }
    });
  }

  Future<bool> _startForegroundTask() async {
    if (serverIP == null) return false;

    await FlutterForegroundTask.saveData(key: 'serverIP', value: serverIP!);
    final receivePort = FlutterForegroundTask.receivePort;
    final isRegistered = _registerReceivePort(receivePort);
    if (!isRegistered) {
      print('Failed to register receivePort!');
      return false;
    }

    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
      );
    }
  }

  Future<bool> _stopForegroundTask() {
    return FlutterForegroundTask.stopService();
  }

  bool _registerReceivePort(ReceivePort? newReceivePort) {
    if (newReceivePort == null) return false;

    _closeReceivePort();

    _receivePort = newReceivePort;
    _receivePort?.listen((data) {
      if (data is String) {
        print(data);
      }
    });

    return _receivePort != null;
  }

  void _closeReceivePort() {
    _receivePort?.close();
    _receivePort = null;
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('UUID App'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'UUID del dispositivo:',
              ),
              Text(
                uuid ?? 'Cargando...',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              FutureBuilder(
                future: deviceInfo.androidInfo,
                builder: (context, AsyncSnapshot<AndroidDeviceInfo> snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text('Información del dispositivo:'),
                        Text('Modelo: ${snapshot.data!.model}', style: const TextStyle(fontSize: 16)),
                        Text('Marca: ${snapshot.data!.manufacturer}', style: const TextStyle(fontSize: 16)),
                        Text('Versión de Android: ${snapshot.data!.version.release}', style: const TextStyle(fontSize: 16)),
                        Text('ID: ${snapshot.data!.id}', style: const TextStyle(fontSize: 16)),
                        Text('Tipo: ${snapshot.data!.type}', style: const TextStyle(fontSize: 16)),
                        Text('Versión de la base de datos: ${snapshot.data!.version.incremental}', style: const TextStyle(fontSize: 16)),
                        TextButton(
                          onPressed: sendMessage,
                          child: const Text('Enviar mensaje de roll call'),
                        ),
                      ],
                    );
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
              serverIP != null ?
              ElevatedButton(
                onPressed: _startForegroundTask,
                child: const Text('Iniciar Servicio en Primer Plano'),
              )
              : const Text('Esperando dirección IP del servidor...'),
              ElevatedButton(
                onPressed: _stopForegroundTask,
                child: const Text('Detener Servicio en Primer Plano'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
