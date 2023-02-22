import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:headphonetest/main.dart';
import 'package:headset_connection_event/headset_event.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';


class HeadsetDetection extends StatefulWidget {
  const HeadsetDetection({Key? key}) : super(key: key);

  @override
  State<HeadsetDetection> createState() => _HeadsetDetectionState();
}

class _HeadsetDetectionState extends State<HeadsetDetection> with WidgetsBindingObserver {

  ReceivePort? _receivePort;

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
          backgroundColor: Colors.orange,
        ),
        buttons: [
          const NotificationButton(id: 'sendButton', text: 'Send'),
          const NotificationButton(id: 'testButton', text: 'Test'),
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
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<bool> _startForegroundTask() async {
    // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
    // onNotificationPressed function to be called.
    //
    // When the notification is pressed while permission is denied,
    // the onNotificationPressed function is not called and the app opens.
    //
    // If you do not use the onNotificationPressed or launchApp function,
    // you do not need to write this code.
    if (!await FlutterForegroundTask.canDrawOverlays) {
      final isGranted =
          await FlutterForegroundTask.openSystemAlertWindowSettings();
      if (!isGranted) {
        debugPrint('SYSTEM_ALERT_WINDOW permission denied!');
        return false;
      }
    }

    // You can save data using the saveData function.
    await FlutterForegroundTask.saveData(key: 'customData', value: 'hello');

    // Register the receivePort before starting the service.
    final ReceivePort? receivePort = FlutterForegroundTask.receivePort;
    final bool isRegistered = _registerReceivePort(receivePort);
    if (!isRegistered) {
      debugPrint('Failed to register receivePort!');
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

  // Future<bool> _stopForegroundTask() {
  //   return FlutterForegroundTask.stopService();
  // }

  bool _registerReceivePort(ReceivePort? newReceivePort) {
    if (newReceivePort == null) {
      return false;
    }

    _closeReceivePort();

    _receivePort = newReceivePort;
    _receivePort?.listen((message) {
      if (message is int) {
        debugPrint('eventCount: $message');
      } else if (message is String) {
        if (message == 'onNotificationPressed') {
          Navigator.of(context).pushNamed('/resume-route');
        }
      } else if (message is DateTime) {
        debugPrint('timestamp: ${message.toString()}');
      }
    });

    return _receivePort != null;
  }

  void _closeReceivePort() {
    _receivePort?.close();
    _receivePort = null;
  }

  T? _ambiguate<T>(T? value) => value;

  @override
  void dispose() {
    _closeReceivePort();
    super.dispose();
  }



  final headsetPlugin = HeadsetEvent();
  HeadsetState? _headsetState;

  @override
  void initState() {
    super.initState();

    ///Request Permissions (Required for Android 12)
    headsetPlugin.requestPermission();

    /// if headset is plugged
    headsetPlugin.getCurrentState.then((val) {
      setState(() {
        _headsetState = val;
      });
    });

    /// Detect the moment headset is plugged or unplugged
    headsetPlugin.setListener((val) {
      setState(() {
        _headsetState = val;
        _headsetState == HeadsetState.CONNECT
          ? (){}
          : callNumber();
      });
    });

    _initForegroundTask();
    _ambiguate(WidgetsBinding.instance)?.addPostFrameCallback((_) async {
      // You can get the previous ReceivePort without restarting the service.
      if (await FlutterForegroundTask.isRunningService) {
        final newReceivePort = FlutterForegroundTask.receivePort;
        _registerReceivePort(newReceivePort);
      }
    });

    _startForegroundTask();
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.headset,
                color: _headsetState == HeadsetState.CONNECT
                    ? Colors.green
                    : Colors.red,
              ),
              Text('State : $_headsetState\n'),
              const SizedBox(height: 20,),
              InkWell(
                onTap: (){
                  call();
                },
                child: const Icon(Icons.phone)
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Call number
  callNumber() async{
    const number = '9861333461'; //set the number here
    await FlutterPhoneDirectCaller.callNumber(number);
  }

  call() async{
    const number = '9863021878'; //set the number here
    await FlutterPhoneDirectCaller.callNumber(number);
  }
}