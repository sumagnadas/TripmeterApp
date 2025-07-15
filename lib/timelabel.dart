import 'package:flutter/material.dart';
import 'package:ntp/ntp.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class TimeLabel extends StatefulWidget {
  const TimeLabel({super.key});

  @override
  State<TimeLabel> createState() => _TimeLabelState();
}

class _TimeLabelState extends State<TimeLabel> {
  DateTime? _ntpTime;
  int? _offset;
  late Timer _timer;
  late StreamController<DateTime> _clockStreamController;

  @override
  void initState() async {
    super.initState();
    _clockStreamController = StreamController<DateTime>();
    await _initializeNTP();
    _startClockUpdates();
  }

  @override
  void dispose() {
    _timer.cancel();
    _clockStreamController.close();
    super.dispose();
  }

  Future<void> _initializeNTP() async {
    try {
      // Get the NTP time
      final DateTime ntpStartTime = await NTP.now();
      // Get the device's current time
      final DateTime deviceStartTime = DateTime.now();

      // Calculate the offset
      _offset = ntpStartTime.difference(deviceStartTime).inMilliseconds;
      _ntpTime = deviceStartTime.add(Duration(milliseconds: _offset!));

      print('NTP Time: $ntpStartTime');
      print('Device Time: $deviceStartTime');
      print('Offset (ms): $_offset');

      // Immediately update the stream with the first synchronized time
      _clockStreamController.add(_ntpTime!);
    } catch (e) {
      print('Error synchronizing with NTP: $e');
      // Fallback to device time if NTP fails
      _ntpTime = DateTime.now();
      _offset = 0;
      _clockStreamController.add(_ntpTime!);
    }
  }

  void _startClockUpdates() {
    // Update the clock every 10 milliseconds for hh:mm:ss.00 precision
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (_offset != null) {
        final DateTime deviceCurrentTime = DateTime.now();
        // Add the calculated offset to the device's current time
        final DateTime synchronizedTime = deviceCurrentTime.add(
          Duration(milliseconds: _offset!),
        );
        _clockStreamController.add(synchronizedTime);
      } else {
        // If NTP not yet synchronized, show device time (or a loading indicator)
        _clockStreamController.add(DateTime.now());
      }
    });
  }

  Future<void> _synchronizeAgain() async {
    setState(() {
      _offset = null; // Clear offset to show "Synchronizing..."
    });
    await _initializeNTP();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: _clockStreamController.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // Format the time to hh:mm:ss.00
          final String formattedTime = DateFormat(
            'HH:mm:ss.S',
          ).format(snapshot.data!);
          // Manually format milliseconds to ensure two digits
          final String milliseconds = (snapshot.data!.millisecond ~/ 10)
              .toString()
              .padLeft(2, '0');

          return Text(
            '${formattedTime.substring(0, formattedTime.length - 1)}$milliseconds',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          );
        } else if (_offset == null) {
          return const Text(
            'Synchronizing with NTP...',
            style: TextStyle(fontSize: 24, fontStyle: FontStyle.italic),
          );
        } else {
          return const Text(
            'Error: Could not get time.',
            style: TextStyle(fontSize: 24, color: Colors.red),
          );
        }
      },
    );
  }
}
