import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tripmeter/location_access.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:ntp/ntp.dart';
// ...

// The following line will enable the Android and iOS wakelock.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData.dark(),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var timeString = DateFormat('HH:mm:ss').format(DateTime.now());
  Duration _offset = Duration(seconds: 0);
  Future<void> _initializeNTP() async {
    try {
      // Get the NTP time
      final DateTime ntpStartTime = await NTP.now(
        lookUpAddress: "time.google.com",
      );
      // Get the device's current time
      final DateTime deviceStartTime = DateTime.now();

      // Calculate the offset
      _offset = ntpStartTime.difference(deviceStartTime);
      // _ntpTime = deviceStartTime.add(Duration(milliseconds: _offset!));

      print('NTP Time: $ntpStartTime');
      print('Device Time: $deviceStartTime');
      print('Offset (ms): $_offset');

      // Immediately update the stream with the first synchronized time
      // _clockStreamController.add(_ntpTime!);
    } catch (e) {
      print('Error synchronizing with NTP: $e');
      // Fallback to device time if NTP fails
      // _ntpTime = DateTime.now();
      // _offset = 0;
      // _clockStreamController.add(_ntpTime!);
    }
  }

  MyAppState() {
    unawaited(_initializeNTP());
    void updateTime(_) {
      print(_offset);
      int start = DateTime.now().millisecondsSinceEpoch;
      DateTime syncedTime = DateTime.now().add(_offset);
      int end = DateTime.now().millisecondsSinceEpoch;
      // syncedTime.add;
      timeString = DateFormat('HH:mm:ss.S').format(syncedTime);
      _offset += Duration(milliseconds: end - start);
      notifyListeners();
    }

    Timer.periodic(Duration(milliseconds: 100), updateTime);
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return LayoutBuilder(
      builder: (context, boxConstraints) => Scaffold(
        appBar: AppBar(
          actions: [
            ElevatedButton(
              onPressed: () {
                // print('hello');
              },
              child: Icon(Icons.menu),
            ),
          ],
          title: Center(child: TimeLabel()),
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
        ),
        backgroundColor: theme.colorScheme.surface,
        body: BodyWidget(theme: theme),
        // floatingActionButton: FloatingActionButton(
        //   onPressed: _incrementCounter,
        //   tooltip: 'Increment',
        //   child: const Icon(Icons.add),
        // ), // This trailing comma makes auto-formatting nicer for build methods.
      ), //;
    );
  }
}

class TimeLabel extends StatefulWidget {
  // String timeString = "";
  const TimeLabel({super.key});
  @override
  State<TimeLabel> createState() => _TimeLabelState();
}

class _TimeLabelState extends State<TimeLabel> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);
    return Text(
      appState.timeString,
      style: theme.textTheme.headlineLarge!.copyWith(
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

class BodyWidget extends StatefulWidget {
  const BodyWidget({super.key, required this.theme});

  final ThemeData theme;
  @override
  State<BodyWidget> createState() => _BodyWidgetState();
}

class _BodyWidgetState extends State<BodyWidget> {
  Position? _lastPosition;
  double _distance = 0.0;
  double _speed = 0.0;
  double _totalAvgSpeed = 0.0;
  // Timer? _timer;
  // var _avgSpeed = Vector3D(0.0, 0.0, 0.0);
  double _totalAccl = 0.0;
  var _accl = Vector3D(0.0, 0.0, 0.0);
  DateTime? _lastTimeStamp;
  DateTime? _startTimeStamp;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await WakelockPlus.enable();
      await setUpLocation();
      userAccelerometerEventStream().listen(
        (UserAccelerometerEvent event) {
          setState(() {
            if (_lastTimeStamp != null) {
              int delayms =
                  event.timestamp.millisecondsSinceEpoch -
                  _lastTimeStamp!.millisecondsSinceEpoch;
              var tempaccl = _accl * (delayms / 1000);
              // print('accl ${tempaccl.x} ${tempaccl.y} ${tempaccl.z}');
              // _avgSpeed += _accl * (delayms / 1000);
            }
            // print('avgspeed ${_avgSpeed.x} ${_avgSpeed.y} ${_avgSpeed.z}');
            _accl = Vector3D(event.x, event.y, event.z);
            _totalAccl = _accl.magnitude();
            // _totalAvgSpeed = _avgSpeed.magnitude();
            _lastTimeStamp = event.timestamp;
          });
        },
        onError: (error) {
          print(error);
        },
      );
      var settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      );
      Geolocator.getPositionStream(locationSettings: settings).listen((
        Position newPos,
      ) {
        double newDist = 0;
        if (_totalAccl > 0.4) {
          if (_lastPosition != null) {
            newDist =
                Geolocator.distanceBetween(
                  _lastPosition!.latitude,
                  _lastPosition!.longitude,
                  newPos.latitude,
                  newPos.longitude,
                ) /
                1000;
          }
        }
        setState(() {
          _distance += newDist;
          _speed = newPos.speed * 3.6;
          _lastPosition = newPos;
        });
      });
      // setState(() {
      Timer(Duration(milliseconds: 100), () {
        if (_startTimeStamp != null) {
          setState(() {
            _totalAvgSpeed =
                _distance /
                (DateTime.now().millisecondsSinceEpoch -
                    _startTimeStamp!.millisecondsSinceEpoch) *
                1000;
          });
        }
      });
      // });
      _startTimeStamp = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    // var appState = context.watch<MyAppState>();
    var lat = _lastPosition?.latitude.toStringAsFixed(4);
    var long = _lastPosition?.longitude.toStringAsFixed(4);
    var theme = Theme.of(context);
    var largeFont = widget.theme.textTheme.headlineLarge!.copyWith(
      color: widget.theme.colorScheme.onSurface,
      fontSize: 50,
    );
    var smallFont = widget.theme.textTheme.headlineLarge!.copyWith(
      color: widget.theme.colorScheme.onSurface,
      // has a fontSize 30
    );
    return LayoutBuilder(
      builder: (context, boxConstraints) => Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          spacing: 10,
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(_distance.toStringAsFixed(2), style: largeFont),
            Text(_speed.toStringAsFixed(2), style: largeFont),
            Text(_totalAccl.toStringAsFixed(2), style: largeFont),
            Text(_totalAvgSpeed.toStringAsFixed(2), style: largeFont),
            Column(
              children: [
                Text('$lat', style: largeFont),
                Text('$long', style: smallFont),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              // mainAxisSize: MainAxisSize.max
              // labelPadding: EdgeInsets.all(100),
              children: [
                SizedBox(
                  height: boxConstraints.maxHeight * 0.1,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _distance -= 0.01);
                    },
                    child: Text('-10', style: theme.textTheme.displayMedium),
                  ),
                ),
                // SizedBox(width: boxConstraints.maxWidth * 0.6),
                SizedBox(
                  height: boxConstraints.maxHeight * 0.1,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _distance += 0.01);
                    },
                    child: Text('+10', style: theme.textTheme.displayMedium),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
