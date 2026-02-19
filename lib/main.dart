
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'dart:collection';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MeanifyApp(),
    ),
  );
}

class MeanifyApp extends StatelessWidget {
  const MeanifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Meanify',
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeProvider.accentColor,
              brightness: Brightness.light,
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: themeProvider.accentColor,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: Colors.black,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: const ActivityTrackerScreen(),
        );
      },
    );
  }
}

class ActivityLog {
  final String id;
  int duration;
  final DateTime timestamp;

  ActivityLog({required this.id, required this.duration, required this.timestamp});
}

enum TimerStatus { initial, running, paused }

class ActivityTrackerScreen extends StatefulWidget {
  const ActivityTrackerScreen({super.key});

  @override
  _ActivityTrackerScreenState createState() => _ActivityTrackerScreenState();
}

class _ActivityTrackerScreenState extends State<ActivityTrackerScreen> {
  final Map<String, List<ActivityLog>> _activityLogs = {};
  final Map<String, double> _activityMeans = {};
  final _activityController = TextEditingController();
  String? _selectedActivity;
  final Stopwatch _stopwatch = Stopwatch();
  late final _timer;
  TimerStatus _timerStatus = TimerStatus.initial;

  @override
  void initState() {
    super.initState();
    _timer = Stream.periodic(const Duration(milliseconds: 30), (v) => v);
    _activityController.addListener(() {
      setState(() {}); // Rebuild to show/hide the add button
    });
  }

  @override
  void dispose() {
    _activityController.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  void _onActivitySelected(String selection) {
    setState(() {
      _selectedActivity = selection;
      if (!_activityLogs.containsKey(selection)) {
        _activityLogs[selection] = [];
        _activityMeans[selection] = 0.0;
      }
    });
  }

  void _startTimer() {
    if (_selectedActivity != null) {
      setState(() {
        _timerStatus = TimerStatus.running;
      });
      _stopwatch.start();
    }
  }

  void _pauseTimer() {
    setState(() {
      _timerStatus = TimerStatus.paused;
    });
    _stopwatch.stop();
  }

  void _stopTimer() {
    _stopwatch.stop();
    final elapsedMilliseconds = _stopwatch.elapsedMilliseconds;
    if (elapsedMilliseconds > 0) {
      setState(() {
        final newLog = ActivityLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          duration: elapsedMilliseconds,
          timestamp: DateTime.now(),
        );

        if (_activityLogs[_selectedActivity!]!.length >= 30) {
          _activityLogs[_selectedActivity!]!.removeAt(0);
        }
        _activityLogs[_selectedActivity!]!.add(newLog);

        _calculateMean(_selectedActivity!);
      });
    }
    _stopwatch.reset();
    setState(() {
      _timerStatus = TimerStatus.initial;
    });
  }

  void _calculateMean(String activity) {
    final logs = _activityLogs[activity]!;
    if (logs.isEmpty) {
      _activityMeans[activity] = 0.0;
    } else {
      final totalDuration = logs.fold<int>(0, (sum, log) => sum + log.duration);
      _activityMeans[activity] = totalDuration / logs.length;
    }
  }

  void _deleteLog(String activity, ActivityLog log) {
    setState(() {
      _activityLogs[activity]!.remove(log);
      _calculateMean(activity);
    });
    // This will pop the details screen and show the updated list
    Navigator.of(context).pop();
  }


  void _editLog(String activity, ActivityLog log, int newDuration) {
    setState(() {
      log.duration = newDuration;
      _calculateMean(activity);
    });
  }

  String _formatDuration(int milliseconds) {
    final seconds = milliseconds / 1000;
    return '${seconds.toStringAsFixed(2)}s';
  }

  void _navigateToLogDetails(String activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogDetailsScreen(
          activity: activity,
          logs: _activityLogs[activity]!,
          onDelete: (log) => _deleteLog(activity, log),
          onEdit: (log, newDuration) => _editLog(activity, log, newDuration),
        ),
      ),
    );
  }

  Widget _buildTimerControls(Color accentColor) {
    switch (_timerStatus) {
      case TimerStatus.initial:
        return FloatingActionButton.large(
          onPressed: _startTimer,
          backgroundColor: Colors.green,
          child: const Icon(Icons.play_arrow, size: 50),
        );
      case TimerStatus.running:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              onPressed: _pauseTimer,
              backgroundColor: accentColor,
              child: const Icon(Icons.pause),
            ),
            const SizedBox(width: 20),
            FloatingActionButton(
              onPressed: _stopTimer,
              backgroundColor: Colors.red,
              child: const Icon(Icons.stop),
            ),
          ],
        );
      case TimerStatus.paused:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              onPressed: _startTimer,
              backgroundColor: Colors.green,
              child: const Icon(Icons.play_arrow),
            ),
            const SizedBox(width: 20),
            FloatingActionButton(
              onPressed: _stopTimer,
              backgroundColor: Colors.red,
              child: const Icon(Icons.stop),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: const [
            SizedBox(
              width: 40,
              height: 40,
              child: Placeholder(),
            ),
            SizedBox(width: 10),
            Text('Meanify'),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.black, Colors.grey[900]!]
                : [Colors.grey[200]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                 Row(
                  children:[
                    Expanded(
                      child:  RawAutocomplete<String>(
                  textEditingController: _activityController,
                  focusNode: FocusNode(),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return _activityLogs.keys.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    _onActivitySelected(selection);
                     _activityController.text = selection;
                  },
                  fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Activity',
                        border: const OutlineInputBorder(),
                        suffixIcon: textEditingController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  if (textEditingController.text.isNotEmpty) {
                                    _onActivitySelected(textEditingController.text);
                                    textEditingController.clear();
                                    focusNode.unfocus();
                                  }
                                },
                              )
                            : null,
                      ),
                       onFieldSubmitted: (String value) {
                        _onActivitySelected(value);
                      },
                    );
                  },
                  optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        child: SizedBox(
                          height: 200.0,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return InkWell(
                                onTap: () {
                                  onSelected(option);
                                },
                                child: ListTile(
                                  title: Text(option),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                    )
                  ],
                ),
               
                const Spacer(),
                StreamBuilder(
                  stream: _timer,
                  builder: (context, snapshot) {
                    return Text(
                      _formatDuration(_stopwatch.elapsedMilliseconds),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w200),
                    );
                  },
                ),
                const SizedBox(height: 24),
                _buildTimerControls(accentColor),
                const Spacer(),
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    itemCount: _activityLogs.length,
                    itemBuilder: (context, index) {
                      final activity = _activityLogs.keys.elementAt(index);
                      final mean = _activityMeans[activity]!;
                      return GlassmorphicContainer(
                        width: double.infinity,
                        height: 80,
                        borderRadius: 12,
                        blur: 10,
                        alignment: Alignment.center,
                        border: 1,
                        linearGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                           colors: [
                            Theme.of(context).colorScheme.surface.withOpacity(0.1),
                            Theme.of(context).colorScheme.surface.withOpacity(0.2),
                          ],
                        ),
                        borderGradient: LinearGradient(
                           begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                           Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                            Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          ],
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(activity, style: Theme.of(context).textTheme.titleMedium),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Mean: ${_formatDuration(mean.toInt())}', style: Theme.of(context).textTheme.bodyLarge),
                              IconButton(
                                icon: const Icon(Icons.history),
                                onPressed: () => _navigateToLogDetails(activity),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showColorPicker(BuildContext context, ThemeProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick an Accent Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: provider.accentColor,
              onColorChanged: (color) => provider.setAccentColor(color),
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          ListTile(
            title: const Text('Accent Color'),
            trailing: CircleAvatar(backgroundColor: themeProvider.accentColor),
            onTap: () => _showColorPicker(context, themeProvider),
          ),
          const Divider(),
          const ExpansionTile(
            title: Text('About Dev'),
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class LogDetailsScreen extends StatefulWidget {
  final String activity;
  final List<ActivityLog> logs;
  final Function(ActivityLog) onDelete;
  final Function(ActivityLog, int) onEdit;

  const LogDetailsScreen({
    super.key,
    required this.activity,
    required this.logs,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  _LogDetailsScreenState createState() => _LogDetailsScreenState();
}

class _LogDetailsScreenState extends State<LogDetailsScreen> {
  
  String _formatDuration(int milliseconds) {
    final seconds = milliseconds / 1000;
    return '${seconds.toStringAsFixed(2)}s';
  }

  void _showEditDialog(ActivityLog log) {
    final textController = TextEditingController(text: (log.duration / 1000).toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Log'),
          content: TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Duration in seconds',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newDuration = (double.tryParse(textController.text) ?? 0) * 1000;
                widget.onEdit(log, newDuration.toInt());
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
       extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Logs for ${widget.activity}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
         decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.black, Colors.grey[900]!]
                : [Colors.grey[200]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView.builder(
            itemCount: widget.logs.length,
            itemBuilder: (context, index) {
              final log = widget.logs[widget.logs.length - 1 - index];
              return GlassmorphicContainer(
                width: double.infinity,
                height: 80,
                borderRadius: 12,
                blur: 10,
                alignment: Alignment.center,
                border: 1,
                 linearGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                           colors: [
                            Theme.of(context).colorScheme.surface.withOpacity(0.1),
                            Theme.of(context).colorScheme.surface.withOpacity(0.2),
                          ],
                        ),
                        borderGradient: LinearGradient(
                           begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                           Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                            Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          ],
                        ),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text('Duration: ${_formatDuration(log.duration)}'),
                  subtitle: Text(log.timestamp.toIso8601String().substring(0, 16)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditDialog(log),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Colors.redAccent,
                        onPressed: () => widget.onDelete(log),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
