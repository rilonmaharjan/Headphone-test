import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:headphonetest/main.dart';
import 'package:headset_connection_event/headset_event.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';


class HeadsetDetection extends StatefulWidget {
  const HeadsetDetection({Key? key}) : super(key: key);

  @override
  State<HeadsetDetection> createState() => _HeadsetDetectionState();
}

class _HeadsetDetectionState extends State<HeadsetDetection> with WidgetsBindingObserver {
  bool popStatus = false;
  final numberCon = TextEditingController();
  late String savedNum;
  var phoneNumber;

  ReceivePort? _receivePort;

  // saveNumber() async{
  //   final SharedPreferences _prefs = await _prefs;
  //   savedNum = _prefs.setString('action', 'Start');
  // }

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
    numberCon.dispose();
    super.dispose();
  }



  final headsetPlugin = HeadsetEvent();
  HeadsetState? _headsetState;

  @override
  void initState() {
    super.initState();
    //Check if the user has inputed a number
    initialize();

    ///Request Permissions (Required for Android 12)
    headsetPlugin.requestPermission();

    // /// if headset is plugged
    // headsetPlugin.getCurrentState.then((val) {
    //   setState(() {
    //     _headsetState = val;
    //   });
    // });

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

  initialize()async{
    //Check if phone number is empty
    var checkNo = await getStoredNumber();
    if(checkNo == null || checkNo == ""){
      popStatus = false;
      showPopUp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20,),
              Icon(
                Icons.headset,
                color: _headsetState == HeadsetState.CONNECT
                    ? Colors.green
                    : Colors.red,
              ),
              const SizedBox(height: 10,),
              Text('State : ${_headsetState ?? "Not Connected"}\n'),
              const SizedBox(height: 20,),
              //Change Number
              InkWell(
                child: Container(
                  height: 45,
                  width: 150,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(
                    left: 10.0,
                    right: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromARGB(255, 223, 223, 223),
                        offset: Offset(0, 5),
                        blurRadius: 5
                      )
                    ]
                  ),
                  child: const Text("Change Number", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),)
                ),
                onTap: (){
                  showPopUp();
                },
              ),
              //Test Call
              const SizedBox(height: 20,),
              InkWell(
                child: Container(
                  height: 60,
                  width: 150,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromARGB(255, 223, 223, 223),
                        offset: Offset(0, 5),
                        blurRadius: 5
                      )
                    ]
                  ),
                  child: const Text("Test Saved Number", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500), textAlign: TextAlign.center,)
                ),
                onTap: (){
                  callNumber();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Call number
  callNumber() async{//set the number here
  var contact = await getStoredNumber();
    await FlutterPhoneDirectCaller.callNumber(contact ?? "9863021878");
  }

  //Store number
  Future<void> storeNumber(String number) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('phoneNumber', number);
  }

  //Return Number to retrieve store number 
  getStoredNumber() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? storedNumber = prefs.getString('phoneNumber');
    return storedNumber;
  }

  showPopUp() async{
    var checkNumber = await getStoredNumber();
    if(checkNumber == null || checkNumber == ""){
      popStatus = false;
      return showDialog(
        context: context, 
        builder: (context){
          return WillPopScope(
            onWillPop: ()async => popStatus,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
              title: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Enter a Contact that you want to call", style: TextStyle(fontSize: 18), textAlign: TextAlign.center,),
                      const SizedBox(height: 20,),
                      Container(
                        height: 60,
                        width: 200,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.only(
                          left: 10.0,
                          right: 10.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromARGB(255, 223, 223, 223),
                              offset: Offset(0, 5),
                              blurRadius: 5
                            )
                          ]
                        ),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.all(15),
                            border: InputBorder.none,
                            labelText: "Enter a contact",
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (val){
                            phoneNumber = val;
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 20,),
                      //Save Contact to Shared prefrence
                      ElevatedButton(
                        onPressed: () {
                          if(phoneNumber != "" && phoneNumber!=null){
                            setState(() {
                              storeNumber(phoneNumber);
                              popStatus = true;
                            });
                            Navigator.pop(context);
                          } else{
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: const Duration(milliseconds: 1000),
                                backgroundColor: Colors.red.withOpacity(0.9),
                                dismissDirection: DismissDirection.up,
                                margin: EdgeInsets.only(
                                  bottom: MediaQuery.of(context).size.height - 100,
                                  right: 20,
                                  left: 20),
                                behavior: SnackBarBehavior.floating,
                                content: const Text("Please fill all the Dimensions.", style: TextStyle(color: Colors.white),),
                              )
                            );
                          }
                        }, 
                        child: const Text("Save")
                      ),
                    ],
                  ),
                ),
              )
            ),
          );
        },
      );
    } else{
      popStatus = true;
      return showDialog(
        context: context, 
        builder: (context){
          return WillPopScope(
            onWillPop: ()async => popStatus,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
              title: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Enter a Contact that you want to call", style: TextStyle(fontSize: 18), textAlign: TextAlign.center,),
                      const SizedBox(height: 20,),
                      Container(
                        height: 60,
                        width: 200,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.only(
                          left: 10.0,
                          right: 10.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromARGB(255, 223, 223, 223),
                              offset: Offset(0, 5),
                              blurRadius: 5
                            )
                          ]
                        ),
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.all(15),
                            border: InputBorder.none,
                            labelText: "Enter a contact",
                          ),
                          onChanged: (val){
                            phoneNumber = val;
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 20,),
                      //Save Contact to Shared prefrence
                      ElevatedButton(
                        onPressed: () {
                          if(phoneNumber != "" && phoneNumber!=null){
                            setState(() {
                              storeNumber(phoneNumber);
                              popStatus = true;
                            });
                            Navigator.pop(context);
                          } else{
                            setState(() {
                              storeNumber(checkNumber);
                              popStatus = true;
                            });
                            Navigator.pop(context);
                          }
                        }, 
                        child: const Text("Save")
                      ),
                    ],
                  ),
                ),
              )
            ),
          );
        },
      );
    }
  }
}