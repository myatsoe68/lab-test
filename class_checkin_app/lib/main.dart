import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DemoQrItem {
  const DemoQrItem(this.title, this.value);

  final String title;
  final String value;
}

const List<DemoQrItem> kDemoQrItems = <DemoQrItem>[
  DemoQrItem('Main Class Session', 'CLASS-CS101-SESSION-2026-03-13'),
  DemoQrItem('Alternate Session', 'CLASS-CS101-SESSION-ALT'),
  DemoQrItem('Check-in Only', 'CLASS-CS101-CHECKIN'),
  DemoQrItem('Finish Class Only', 'CLASS-CS101-FINISH'),
];

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Class Check-in App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _recentRecords = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _refreshRecords();
  }

  Future<void> _refreshRecords() async {
    final List<Map<String, dynamic>> data = await LocalRecordStore.getRecords();
    if (!mounted) {
      return;
    }
    setState(() {
      _recentRecords = data.take(8).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Attendance MVP')),
      body: RefreshIndicator(
        onRefresh: _refreshRecords,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const Text(
              'Choose an action',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Check-in (Before Class)'),
              onPressed: () async {
                final bool? saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => const CheckInScreen(),
                  ),
                );
                if (saved == true) {
                  await _refreshRecords();
                }
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.done_all),
              label: const Text('Finish Class (After Class)'),
              onPressed: () async {
                final bool? saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => const FinishClassScreen(),
                  ),
                );
                if (saved == true) {
                  await _refreshRecords();
                }
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Show Demo QR Codes'),
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const DemoQrCodesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Recent Saved Records',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (_recentRecords.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No saved records yet.'),
                ),
              ),
            ..._recentRecords.map((Map<String, dynamic> record) {
              final String phase = (record['phase'] ?? '').toString();
              final String qrValue = (record['qrValue'] ?? '-').toString();
              final String timestamp = (record['timestamp'] ?? '').toString();
              return Card(
                child: ListTile(
                  title: Text('${phase.toUpperCase()} - QR: $qrValue'),
                  subtitle: Text(timestamp),
                  trailing: Text(
                    '(${record['latitude']?.toStringAsFixed(5) ?? '-'}, ${record['longitude']?.toStringAsFixed(5) ?? '-'})',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _previousTopicController =
      TextEditingController();
  final TextEditingController _expectedTopicController =
      TextEditingController();
  int _moodScore = 3;
  String? _qrValue;
  bool _saving = false;

  @override
  void dispose() {
    _previousTopicController.dispose();
    _expectedTopicController.dispose();
    super.dispose();
  }

  Future<void> _scanQr() async {
    final String? value = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const QrScannerScreen()),
    );
    if (value != null && mounted) {
      setState(() {
        _qrValue = value;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_qrValue == null || _qrValue!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan the class QR code.')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final Position position = await LocationHelper.capturePosition();
      final DateTime now = DateTime.now();

      await LocalRecordStore.saveRecord(<String, dynamic>{
        'phase': 'checkin',
        'timestamp': now.toIso8601String(),
        'qrValue': _qrValue,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'previousTopic': _previousTopicController.text.trim(),
        'expectedTopic': _expectedTopicController.text.trim(),
        'moodScore': _moodScore,
        'learnedToday': null,
        'feedback': null,
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in saved successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save check-in: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Before Class Check-in')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: _scanQr,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(
                _qrValue == null ? 'Scan Class QR Code' : 'Scanned: $_qrValue',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _previousTopicController,
              decoration: const InputDecoration(
                labelText: 'Topic covered in previous class',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _expectedTopicController,
              decoration: const InputDecoration(
                labelText: 'Topic expected to learn today',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _moodScore,
              decoration: const InputDecoration(
                labelText: 'Mood before class',
                border: OutlineInputBorder(),
              ),
              items: const <DropdownMenuItem<int>>[
                DropdownMenuItem<int>(
                  value: 1,
                  child: Text('1 - Very negative'),
                ),
                DropdownMenuItem<int>(value: 2, child: Text('2 - Negative')),
                DropdownMenuItem<int>(value: 3, child: Text('3 - Neutral')),
                DropdownMenuItem<int>(value: 4, child: Text('4 - Positive')),
                DropdownMenuItem<int>(
                  value: 5,
                  child: Text('5 - Very positive'),
                ),
              ],
              onChanged: (int? value) {
                if (value != null) {
                  setState(() {
                    _moodScore = value;
                  });
                }
              },
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save Check-in'),
            ),
          ],
        ),
      ),
    );
  }
}

class FinishClassScreen extends StatefulWidget {
  const FinishClassScreen({super.key});

  @override
  State<FinishClassScreen> createState() => _FinishClassScreenState();
}

class _FinishClassScreenState extends State<FinishClassScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _learnedController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  String? _qrValue;
  bool _saving = false;

  @override
  void dispose() {
    _learnedController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _scanQr() async {
    final String? value = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const QrScannerScreen()),
    );
    if (value != null && mounted) {
      setState(() {
        _qrValue = value;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_qrValue == null || _qrValue!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan the class QR code.')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final Position position = await LocationHelper.capturePosition();
      final DateTime now = DateTime.now();

      await LocalRecordStore.saveRecord(<String, dynamic>{
        'phase': 'finish',
        'timestamp': now.toIso8601String(),
        'qrValue': _qrValue,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'previousTopic': null,
        'expectedTopic': null,
        'moodScore': null,
        'learnedToday': _learnedController.text.trim(),
        'feedback': _feedbackController.text.trim(),
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class completion saved successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save completion: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finish Class')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: _scanQr,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(
                _qrValue == null ? 'Scan Class QR Code' : 'Scanned: $_qrValue',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _learnedController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'What did you learn today?',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Feedback about class or instructor',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save Finish-Class Data'),
            ),
          ],
        ),
      ),
    );
  }
}

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        controller: _controller,
        onDetect: (BarcodeCapture capture) {
          if (_handled) {
            return;
          }
          final String? raw = capture.barcodes.firstOrNull?.rawValue;
          if (raw != null && raw.trim().isNotEmpty) {
            _handled = true;
            Navigator.of(context).pop(raw.trim());
          }
        },
      ),
    );
  }
}

class DemoQrCodesScreen extends StatelessWidget {
  const DemoQrCodesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo QR Codes')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: kDemoQrItems.length,
        itemBuilder: (BuildContext context, int index) {
          final DemoQrItem item = kDemoQrItems[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(8),
                      child: QrImageView(
                        data: item.value,
                        version: QrVersions.auto,
                        size: 190,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    item.value,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class LocalRecordStore {
  static const String _key = 'attendance_records_v1';

  static Future<List<Map<String, dynamic>>> getRecords() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .toList()
        .reversed
        .toList();
  }

  static Future<void> saveRecord(Map<String, dynamic> record) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    final List<Map<String, dynamic>> list;
    if (raw == null || raw.isEmpty) {
      list = <Map<String, dynamic>>[];
    } else {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      list = decoded
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    list.add(record);
    await prefs.setString(_key, jsonEncode(list));
  }
}

class LocationHelper {
  static Future<Position> capturePosition() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location service is disabled.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw 'Location permission was denied.';
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission is denied forever.';
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
