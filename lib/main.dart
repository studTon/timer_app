import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart'; // Import the audioplayers package
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  int _workDuration = 25; // Default timer duration in minutes
  static const String _durationKey = 'work_duration';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load the saved duration from disk
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _workDuration = prefs.getInt(_durationKey) ?? 25;
    });
  }

  // Save the new duration to disk
  Future<void> _updateDuration(int newDuration) async {
    setState(() {
      _workDuration = newDuration;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_durationKey, newDuration);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      TimerPage(initialMinutes: _workDuration),
      SettingsPage(
        currentDuration: _workDuration,
        onDurationChanged: _updateDuration,
      ),
    ];

    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF333745),
        scaffoldBackgroundColor: const Color.fromARGB(255, 9, 67, 168),
      ),
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color.fromARGB(255, 9, 67, 168),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Timer'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Set up'),
          ],
        ),
      ),
    );
  }
}

class TimerPage extends StatefulWidget {
  final int initialMinutes;
  const TimerPage({super.key, required this.initialMinutes});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  late int _secondsRemaining;
  Timer? _timer;
  bool _isRunning = false;
  final AudioPlayer _audioPlayer = AudioPlayer(); // Initialize AudioPlayer

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.initialMinutes * 60;
  }

  // Reset the timer if the settings change
  @override
  void didUpdateWidget(TimerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMinutes != widget.initialMinutes) {
      _stopTimer();
      setState(() {
        _secondsRemaining = widget.initialMinutes * 60;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Dispose the audio player when the widget is removed
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _stopTimer();
          _audioPlayer.play(AssetSource('sounds/alarm.mp3')); // Play sound when timer finishes
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _stopTimer();
    setState(() => _secondsRemaining = widget.initialMinutes * 60);
  }

  @override
  Widget build(BuildContext context) {
    String minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    String seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$minutes:$seconds', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 64,
                icon: Icon(_isRunning ? Icons.pause_circle : Icons.play_circle),
                onPressed: _toggleTimer,
              ),
              IconButton(
                iconSize: 64,
                icon: const Icon(Icons.refresh),
                onPressed: _resetTimer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final int currentDuration;
  final Function(int) onDurationChanged;

  const SettingsPage({
    super.key,
    required this.currentDuration,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 80),
          const Text('Set up', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          Text('Duration: $currentDuration min'),
          Slider(
            activeColor: const Color.fromARGB(255, 255, 255, 255),
            inactiveColor: const Color.fromARGB(255, 0, 4, 128),
            value: currentDuration.toDouble(),
            min: 1,
            max: 60,
            divisions: 59,
            label: currentDuration.toString(),
            onChanged: (value) => onDurationChanged(value.toInt()),
          ),
        ],
      ),
    );
  }
}
