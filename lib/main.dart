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
  String? _deviceName;
  List<ScanResult> _availableDevices = [];
  bool _isScanning = false;

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
    setState(() {
      _isScanning = true;
      _availableDevices = [];
    });

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _availableDevices = results;
      });
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4)).then((_) {
      setState(() {
        _isScanning = false;
      });
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        _connectedDevice = device;
        _isConnected = true;
        _deviceName = device.name;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _startBluetoothScan,
          ),
        ],
      ),
      body:
          _selectedIndex == 0
              ? Column(
                children: [
                  Expanded(
                    child: HomeScreen(
                      receivedData: _receivedData,
                      isConnected: _isConnected,
                      statusMessage: _statusMessage,
                      deviceName: _deviceName,
                    ),
                  ),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Available Devices',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_isScanning)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child:
                              _availableDevices.isEmpty
                                  ? Center(
                                    child: Text(
                                      _isScanning
                                          ? 'Scanning for devices...'
                                          : 'No devices found',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  )
                                  : ListView.builder(
                                    itemCount: _availableDevices.length,
                                    itemBuilder: (context, index) {
                                      final device =
                                          _availableDevices[index].device;
                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: ListTile(
                                          title: Text(
                                            device.name.isNotEmpty
                                                ? device.name
                                                : 'Unknown Device',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            device.remoteId.toString(),
                                          ),
                                          trailing: ElevatedButton(
                                            onPressed:
                                                () => _connectToDevice(device),
                                            child: const Text('Connect'),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
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
