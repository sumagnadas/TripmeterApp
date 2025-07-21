import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:ntp/ntp.dart';

class MyAppState extends ChangeNotifier {
  var timeString = DateFormat('HH:mm:ss').format(DateTime.now());
  Duration _offset = Duration(seconds: 0);
  Future<void> initializeNTP() async {
    try {
      // Get the NTP time
      final DateTime ntpStartTime = await NTP.now(
        lookUpAddress: "time.google.com",
      );
      // Get the device's current time
      final DateTime deviceStartTime = DateTime.now();

      // Calculate the _offset
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
    unawaited(initializeNTP());
    void updateTime(_) {
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
