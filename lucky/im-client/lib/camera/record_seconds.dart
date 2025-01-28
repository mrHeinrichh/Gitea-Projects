import 'package:flutter/material.dart';

class RecordSeconds extends StatefulWidget {
  RecordSeconds({super.key});

  Function(double seconds) updateSeconds = (double seconds) {};

  @override
  State<RecordSeconds> createState() => _RecordSecondsState();
}

class _RecordSecondsState extends State<RecordSeconds> {
  double seconds = -1;

  @override
  void initState() {
    widget.updateSeconds = (double seconds) {
      if (mounted) {
        setState(() {
          this.seconds = seconds;
        });
      }
    };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (seconds < 0) {
      return const SizedBox();
    }
    return Container(
      alignment: const Alignment(0, 0),
      height: 25,
      width: 80,
      decoration: const BoxDecoration(
        color: Color(0xffEB4B35),
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
      ),
      child: Text(
        formatDuration(seconds),
        style: const TextStyle(
            color: Colors.white, fontSize: 17, decoration: TextDecoration.none),
      ),
    );
  }

  String formatDuration(double seconds) {
    // Convert the double to an integer for precise calculations
    int totalSeconds = seconds.toInt();

    // Calculate hours, minutes, and seconds
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int secs = totalSeconds % 60;

    // Format the result as HH:MM:SS
    String formatted = [
      if (hours < 10) '0$hours' else '$hours',
      if (minutes < 10) '0$minutes' else '$minutes',
      if (secs < 10) '0$secs' else '$secs'
    ].join(':');

    return formatted;
  }
}
