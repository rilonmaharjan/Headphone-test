import 'package:flutter/material.dart';
import 'package:headset_connection_event/headset_event.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';


class HeadsetDetection extends StatefulWidget {
  const HeadsetDetection({Key? key}) : super(key: key);

  @override
  State<HeadsetDetection> createState() => _HeadsetDetectionState();
}

class _HeadsetDetectionState extends State<HeadsetDetection> with WidgetsBindingObserver {

  final _headsetPlugin = HeadsetEvent();
  HeadsetState? _headsetState;
  bool isInForeground = true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    isInForeground = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);

    ///Request Permissions (Required for Android 12)
    _headsetPlugin.requestPermission();

    /// if headset is plugged
    _headsetPlugin.getCurrentState.then((val) {
      setState(() {
        _headsetState = val;
      });
    });

    /// Detect the moment headset is plugged or unplugged
    _headsetPlugin.setListener((val) {
      setState(() {
        _headsetState = val;
        _headsetState == HeadsetState.CONNECT
          ? (){}
          : callNumber();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                callNumber();
              },
              child: const Icon(Icons.phone)),
            
          ],
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