import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tripmeter/location_access.dart';
import 'package:intl/intl.dart';

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
        theme: ThemeData(
          // This is the theme of your application.
          //
          // TRY THIS: Try running your application with "flutter run". You'll see
          // the application has a purple toolbar. Then, without quitting the app,
          // try changing the seedColor in the colorScheme below to Colors.green
          // and then invoke "hot reload" (save your changes or press the "hot
          // reload" button in a Flutter-supported IDE, or press "r" if you used
          // the command line to start the app).
          //
          // Notice that the counter didn't reset back to zero; the application
          // state is not lost during the reload. To reset the state, use hot
          // restart instead.
          //
          // This works for code too, not just values: Most code changes can be
          // tested with just a hot reload.
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        ),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var timeString = DateFormat('HH:mm:ss').format(DateTime.now());
  MyAppState() {
    Future<void> updateTime() async {
      timeString = DateFormat('HH:mm:ss').format(DateTime.now());
      notifyListeners();
      Timer(Duration(seconds: 1), updateTime);
    }

    Timer(Duration(seconds: 1), updateTime);
    notifyListeners();
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
    var appState = context.watch<MyAppState>();
    var theme = Theme.of(context);
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return LayoutBuilder(
      builder: (context, boxConstraints) => Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () {
                print('hello');
              },
              icon: Icon(Icons.menu),
            ),
          ],
          title: Center(child: TimeLabel()),
          backgroundColor: theme.secondaryHeaderColor,
          foregroundColor: theme.primaryColor,
        ),
        bottomNavigationBar: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // mainAxisSize: MainAxisSize.max
          // labelPadding: EdgeInsets.all(100),
          children: [
            SizedBox(
              height: boxConstraints.maxHeight * 0.05,
              child: ElevatedButton(
                onPressed: () {
                  print('hello');
                },
                child: Text('-10'),
              ),
            ),
            SizedBox(width: boxConstraints.maxWidth * 0.6),
            SizedBox(
              height: boxConstraints.maxHeight * 0.05,
              child: ElevatedButton(
                onPressed: () {
                  print('hello');
                },
                child: Text('+10'),
              ),
            ),
          ],
        ),
        backgroundColor: theme.primaryColor,
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
        color: theme.colorScheme.primary,
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

class Vector3D {
  double x = 0;
  double y = 0;
  double z = 0;
  Vector3D(this.x, this.y, this.z);

  Vector3D operator *(num scalar) =>
      Vector3D(scalar * x, scalar * y, scalar * z);
  Vector3D operator +(Vector3D vect) =>
      Vector3D(vect.x + x, vect.y + y, vect.z + z);
  double magnitude() => sqrt(x * x + y * y + z * z);
}

class _BodyWidgetState extends State<BodyWidget> {
  Position? _lastPosition;
  double _distance = 0.0;
  double _speed = 0.0;
  double _totalAvgSpeed = 0.0;
  Timer? _timer;
  var _avgSpeed = Vector3D(0.0, 0.0, 0.0);
  double _totalAccl = 0.0;
  var _accl = Vector3D(0.0, 0.0, 0.0);
  DateTime? _lastTimeStamp;
  DateTime? _startTimeStamp;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await setUpLocation();
      userAccelerometerEventStream().listen(
        (UserAccelerometerEvent event) {
          setState(() {
            if (_lastTimeStamp != null) {
              int delayms =
                  event.timestamp.millisecondsSinceEpoch -
                  _lastTimeStamp!.millisecondsSinceEpoch;
              var tempaccl = _accl * (delayms / 1000);
              print('accl ${tempaccl.x} ${tempaccl.y} ${tempaccl.z}');
              _avgSpeed += _accl * (delayms / 1000);
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
        if (_totalAccl > 0.4) {
          setState(() {
            if (_lastPosition != null) {
              _distance +=
                  Geolocator.distanceBetween(
                    _lastPosition!.latitude,
                    _lastPosition!.longitude,
                    newPos.latitude,
                    newPos.longitude,
                  ) /
                  1000;
            }
          });
        }
        _speed = newPos.speed * 3.6;
        _lastPosition = newPos;
      });
      setState(() {
        _timer = Timer(Duration(milliseconds: 100), () {
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
      });
      _startTimeStamp = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    // var appState = context.watch<MyAppState>();
    var lat = _lastPosition?.latitude.toStringAsFixed(4);
    var long = _lastPosition?.longitude.toStringAsFixed(4);
    return Center(
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    '$lat',
                    style: widget.theme.textTheme.headlineLarge!.copyWith(
                      color: widget.theme.colorScheme.onPrimary,
                    ),
                  ),
                  Text(
                    '$long',
                    style: widget.theme.textTheme.bodySmall!.copyWith(
                      color: widget.theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    _distance.toStringAsFixed(2),
                    style: widget.theme.textTheme.headlineLarge!.copyWith(
                      color: widget.theme.colorScheme.onPrimary,
                    ),
                  ),
                  Text(
                    _speed.toStringAsFixed(2),
                    style: widget.theme.textTheme.bodySmall!.copyWith(
                      color: widget.theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    _totalAccl.toStringAsFixed(2),
                    style: widget.theme.textTheme.headlineLarge!.copyWith(
                      color: widget.theme.colorScheme.onPrimary,
                    ),
                  ),
                  Text(
                    _totalAvgSpeed.toStringAsFixed(2),
                    style: widget.theme.textTheme.bodySmall!.copyWith(
                      color: widget.theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'hello world4',
                    style: widget.theme.textTheme.headlineLarge!.copyWith(
                      color: widget.theme.colorScheme.onPrimary,
                    ),
                  ),
                  Text(
                    'hello world4.1',
                    style: widget.theme.textTheme.bodySmall!.copyWith(
                      color: widget.theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Text(
          //   // '$_counter',
          //   ''
          //   style: Theme.of(context).textTheme.headlineMedium,
          // ),
        ],
      ),
    );
  }
}
