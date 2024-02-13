import 'package:flutter/material.dart';

class MyProgressMeter extends StatefulWidget {
  @override
  _MyProgressMeterState createState() => _MyProgressMeterState();
}

class _MyProgressMeterState extends State<MyProgressMeter> {
  double _progressValue = 0; // Set the initial progress value (between 0 and 1)

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LinearProgressIndicator(
          value: _progressValue,
          minHeight: 10.0, // Set the minimum height of the progress bar
          backgroundColor: Colors.grey[300], // Set the background color
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue), // Set the progress color
        ),
      ],
    );
  }

  void _updateProgress() {
    // Simulate progress change (replace this with your actual logic)
    setState(() {
      _progressValue += 0.1;
      if (_progressValue > 1.0) {
        _progressValue = 0.0;
      }
    });
  }
}
