import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tripmeter/location_access.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:tripmeter/app_state.dart';
import 'package:tripmeter/menu.dart';
import 'dart:io' show Platform;
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
          actions: [MyCascadingMenu()],
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
  double _splitdistance = 0.0;
  double _speed = 0.0;
  double _splitspeed = 0.0;
  double _totalAvgSpeed = 0.0;
  // Timer? _timer;
  // var _avgSpeed = Vector3D(0.0, 0.0, 0.0);
  double _totalAccl = 0.0;
  var _accl = Vector3D(0.0, 0.0, 0.0);
  DateTime? _lastTimeStamp;
  DateTime? _startTimeStamp;
  DateTime? _splitstartTimeStamp;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (Platform.isAndroid || Platform.isIOS) {
          await WakelockPlus.enable();
          var locSet = await setUpLocation();
          print(0);
          userAccelerometerEventStream().listen(
            (UserAccelerometerEvent event) {
              setState(() {
                if (_lastTimeStamp != null) {
                  int delayms =
                      event.timestamp.millisecondsSinceEpoch -
                      _lastTimeStamp!.millisecondsSinceEpoch;
                  var tempaccl = _accl * (delayms / 1000);
                  print(tempaccl);
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
          if (locSet) {
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
                _splitdistance += newDist;
                _speed = newPos.speed * 3.6;
                _lastPosition = newPos;
              });
            });
          }
        }
        print(0);
        // });
      } on Exception catch (e) {
        print(e);
      } finally {
        _startTimeStamp = DateTime.now();
        _splitstartTimeStamp = DateTime.now();
        void changeSpeed(_) {
          print(0);
          if (_startTimeStamp != null) {
            var timeTaken =
                (DateTime.now().millisecondsSinceEpoch -
                    _startTimeStamp!.millisecondsSinceEpoch) /
                1000;
            var splitTimeTaken =
                (DateTime.now().millisecondsSinceEpoch -
                    _splitstartTimeStamp!.millisecondsSinceEpoch) /
                1000;
            print(timeTaken);
            setState(() {
              _totalAvgSpeed = _distance / timeTaken * 3600;
              _splitspeed = _splitdistance / splitTimeTaken * 3600;
              // print(_totalAvgSpeed)
            });
          }
        }

        print(0);
        // setState(() {
        Timer.periodic(Duration(milliseconds: 100), changeSpeed);
      }
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  spacing: 10,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text("Odo", style: largeFont),
                    Column(
                      children: [
                        Text("Avg Speed", style: largeFont),
                        Text("Instantaneous Spd", style: smallFont),
                      ],
                    ),
                    // Text(_totalAvgSpeed.toStringAsFixed(2), style: largeFont),
                    Text("Split Odo", style: largeFont),
                    // Text(_totalAccl.toStringAsFixed(2), style: largeFont),
                    Text("Split Speed", style: largeFont),
                    Column(
                      children: [
                        Text('lat', style: largeFont),
                        Text('long', style: smallFont),
                      ],
                    ),
                  ],
                ),
                Column(
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
                    Column(
                      children: [
                        Text(
                          _totalAvgSpeed.toStringAsFixed(2),
                          style: largeFont,
                        ),
                        Text(_speed.toStringAsFixed(2), style: smallFont),
                      ],
                    ),
                    // Text(_totalAvgSpeed.toStringAsFixed(2), style: largeFont),
                    Text(_splitdistance.toStringAsFixed(2), style: largeFont),
                    // Text(_totalAccl.toStringAsFixed(2), style: largeFont),
                    Text(_splitspeed.toStringAsFixed(2), style: largeFont),
                    Column(
                      children: [
                        Text('$lat', style: largeFont),
                        Text('$long', style: smallFont),
                      ],
                    ),
                  ],
                ),
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
                      setState(() {
                        _distance -= 0.01;
                        _splitdistance -= 0.01;
                      });
                    },
                    child: Text('-10', style: theme.textTheme.bodySmall),
                  ),
                ),
                SizedBox(
                  width: boxConstraints.maxWidth * 0.3,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _splitdistance = 0.0;
                        _splitspeed = 0.0;
                        _splitstartTimeStamp = DateTime.now();
                      });
                    },
                    child: Text('Reset', style: theme.textTheme.bodySmall),
                  ),
                ),
                SizedBox(
                  height: boxConstraints.maxHeight * 0.1,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _distance += 0.01;
                        _splitdistance += 0.01;
                      });
                    },
                    child: Text('+10', style: theme.textTheme.bodySmall),
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
