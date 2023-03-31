import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_arduino_ble/flutter_arduino_ble.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int heartRate = 0;
  double _ledIntensity = 0.0;
  DateTime startDate;
  DateTime endDate;
  final arduino = FlutterArduinoBle();

  @override
  void initState() {
    super.initState();
    startDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      endDate = DateTime.now();
    });
    _initHeartRateMonitor();
    _initArduinoConnection();
  }

  void _initHeartRateMonitor() async {
    HealthStore healthStore = HealthStore();

    // Request authorization for heart rate data

    HealthAuthorizationStatus authorizationStatus = await healthStore
        .requestAuthorization(dataType: HealthDataType.HEART_RATE);
    if (authorizationStatus == HealthAuthorizationStatus.AUTHORIZED) {
      // Read heart rate data

      Stream<HealthDataSample> heartRateSample = healthStore
          .getHeartRateSamples(startDate: startDate, endDate: endDate);
      heartRateSample.listen((sample) {
        int _heartRate = sample.value;
        if (mounted) {
          setState(() {
            _heartRate = heartRate;
            _ledIntensity = _mapHeartRateToIntensity(heartRate);
            arduino.writeCharacteristic("10,${_ledIntensity.toInt()}");
          });
        }
      });
    } else if (authorizationStatus == HealthAuthorizationStatus.DENIED) {
      // Show a message or an alert dialog to inform the user that the app needs access to heart rate data to function properly

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Access to heart rate data is denied"),
            content: const Text(
                "The app needs access to heart rate data to function properly. Please grant access in the Health app."),
            actions: <Widget>[
              FlatButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _initArduinoConnection() async {
    await arduino.connect();
  }

  double _mapHeartRateToIntensity(int heartRate) {
    if (heartRate <= 55) {
      return 3.0;
    } else if (heartRate > 56 && heartRate <= 70) {
      return 5.0;
    } else {
      return min(10.0, max(0.0, heartRate / 15.0));
    }
  }

  @override
  void dispose() {
    arduino.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Monitor',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Health Monitor'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Heart rate:',
              ),
              Text(
                '$heartRate bpm',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
