import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
import 'screens/emergency_contacts_screen.dart';
import 'screens/information_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fall Detection System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<String> _receivedData = [];
  BluetoothDevice? _connectedDevice;
  bool _isConnected = false;
  String _statusMessage = 'Waiting for data...';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _startBluetoothScan();
  }

  Future<void> _requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothAdvertise.request();
  }

  void _startBluetoothScan() {
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.name.contains('HC-06')) {
          _connectToDevice(result.device);
          break;
        }
      }
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        _connectedDevice = device;
        _isConnected = true;
        _statusMessage = 'Connected to ${device.name}';
      });
      _listenForData(device);
    } catch (e) {
      setState(() {
        _statusMessage = 'Connection failed: $e';
      });
    }
  }

  void _listenForData(BluetoothDevice device) {
    device.discoverServices().then((services) {
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.read) {
            characteristic.setNotifyValue(true);
            characteristic.value.listen((value) {
              if (value.isNotEmpty) {
                setState(() {
                  _receivedData.add(String.fromCharCodes(value));
                  if (_receivedData.length > 100) {
                    _receivedData.removeAt(0);
                  }
                });
              }
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fall Detection System'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body:
          _selectedIndex == 0
              ? HomeScreen(
                receivedData: _receivedData,
                isConnected: _isConnected,
                statusMessage: _statusMessage,
              )
              : _selectedIndex == 1
              ? const EmergencyContactsScreen()
              : const InformationScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_phone),
            label: 'Emergency',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Information'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connectedDevice?.disconnect();
    super.dispose();
  }
}
