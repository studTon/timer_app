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
  int _workMinutes = 25;
  int _workSeconds = 0;
  static const String _minutesKey = 'work_minutes';
  static const String _secondsKey = 'work_seconds';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _workMinutes = prefs.getInt(_minutesKey) ?? 25;
      _workSeconds = prefs.getInt(_secondsKey) ?? 0;
      _isInitialized = true;
    });
  }

  Future<void> _updateSettings(int newMinutes, int newSeconds) async {
    setState(() {
      _workMinutes = newMinutes;
      _workSeconds = newSeconds;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_minutesKey, newMinutes);
    await prefs.setInt(_secondsKey, newSeconds);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }

    final List<Widget> screens = [
      TimerPage(initialSeconds: (_workMinutes * 60) + _workSeconds),
      SettingsPage(
        currentMinutes: _workMinutes,
        currentSeconds: _workSeconds,
        onSettingsChanged: _updateSettings,
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
  final int initialSeconds;
  const TimerPage({super.key, required this.initialSeconds});

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
    _secondsRemaining = widget.initialSeconds;
  }

  // Reset the timer if the settings change
  @override
  void didUpdateWidget(TimerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSeconds != widget.initialSeconds) {
      _stopTimer();
      setState(() {
        _secondsRemaining = widget.initialSeconds;
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
    setState(() => _secondsRemaining = widget.initialSeconds);
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

class SettingsPage extends StatefulWidget {
  final int currentMinutes;
  final int currentSeconds;
  final Function(int, int) onSettingsChanged;

  const SettingsPage({
    super.key,
    required this.currentMinutes,
    required this.currentSeconds,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late int _tempMinutes;
  late int _tempSeconds;

  @override
  void initState() {
    super.initState();
    _tempMinutes = widget.currentMinutes;
    _tempSeconds = widget.currentSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 80),
          const Text('Set up',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          Text('Minutes: $_tempMinutes'),
          Slider(
            activeColor: const Color.fromARGB(255, 255, 255, 255),
            inactiveColor: const Color.fromARGB(255, 0, 4, 128),
            value: _tempMinutes.toDouble(),
            min: 0,
            max: 60,
            divisions: 59,
            label: _tempMinutes.toString(),
            onChanged: (value) {
              setState(() {
                _tempMinutes = value.toInt();
              });
            },
          ),
          const SizedBox(height: 10),
          Text('Seconds: $_tempSeconds'),
          Slider(
            activeColor: const Color.fromARGB(255, 255, 255, 255),
            inactiveColor: const Color.fromARGB(255, 0, 4, 128),
            value: _tempSeconds.toDouble(),
            min: 0,
            max: 59,
            divisions: 59,
            label: _tempSeconds.toString(),
            onChanged: (value) {
              setState(() {
                _tempSeconds = value.toInt();
              });
            },
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                foregroundColor: const Color.fromARGB(255, 9, 67, 168),
              ),
              onPressed: () {
                widget.onSettingsChanged(_tempMinutes, _tempSeconds);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Saved with success!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.save_as_rounded),
              label: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }
}
