import 'package:flutter/material.dart';
import 'package:headset_connection_event/headset_event.dart';


class HeadsetDetection extends StatefulWidget {
  const HeadsetDetection({Key? key}) : super(key: key);

  @override
  State<HeadsetDetection> createState() => _HeadsetDetectionState();
}

class _HeadsetDetectionState extends State<HeadsetDetection> {

  final _headsetPlugin = HeadsetEvent();
  HeadsetState? _headsetState;

  @override
  void initState() {
    super.initState();

    ///Request Permissions (Required for Android 12)
    _headsetPlugin.requestPermission();

    /// if headset is plugged
    _headsetPlugin.getCurrentState.then((_val) {
      setState(() {
        _headsetState = _val;
      });
    });

    /// Detect the moment headset is plugged or unplugged
    _headsetPlugin.setListener((_val) {
      setState(() {
        _headsetState = _val;
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
          ],
        ),
      ),
    );
  }
}