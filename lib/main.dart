import 'dart:async';
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
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _checkExistingConnections();
    _startBluetoothScan();
  }

  Future<void> _requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothAdvertise.request();
    await Permission.location.request();
  }

  Future<void> _checkExistingConnections() async {
    try {
      print('Checking for existing connections...');

      // Get list of connected devices
      List<BluetoothDevice> connectedDevices =
          await FlutterBluePlus.connectedDevices;
      print('Found ${connectedDevices.length} connected devices');

      // Also get bonded (paired) devices
      List<BluetoothDevice> bondedDevices = await FlutterBluePlus.bondedDevices;
      print('Found ${bondedDevices.length} bonded devices');

      // Combine both lists and remove duplicates
      Set<BluetoothDevice> allDevices = {...connectedDevices, ...bondedDevices};
      print('Total unique devices: ${allDevices.length}');

      for (var device in allDevices) {
        print('Checking device: ${device.name} (${device.remoteId})');

        // Check for HC-05 specifically
        if (device.name.toLowerCase().contains('hc-05')) {
          print('Found HC-05 device, attempting to connect...');
          try {
            // Try to connect to the device
            await device.connect(timeout: const Duration(seconds: 5));

            setState(() {
              _connectedDevice = device;
              _isConnected = true;
              _deviceName = device.name;
              _statusMessage = 'Connected to HC-05';
            });

            // Set up connection state monitoring
            device.connectionState.listen((state) {
              print('Connection state changed: $state');
              setState(() {
                _isConnected = state == BluetoothConnectionState.connected;
                if (!_isConnected) {
                  _statusMessage = 'Disconnected from HC-05';
                }
              });
            });

            try {
              // Set up notifications for the connected device
              final services = await device.discoverServices();
              print('Discovered ${services.length} services for HC-05');

              // HC-05 typically uses the Serial Port Profile (SPP)
              // Look for the SPP service and its characteristics
              for (BluetoothService service in services) {
                print('Service UUID: ${service.uuid}');
                for (BluetoothCharacteristic characteristic
                    in service.characteristics) {
                  print('Characteristic UUID: ${characteristic.uuid}');

                  // Enable notifications for all readable characteristics
                  if (characteristic.properties.read ||
                      characteristic.properties.notify) {
                    await characteristic.setNotifyValue(true);
                    characteristic.value.listen((value) {
                      if (value.isNotEmpty) {
                        String data = String.fromCharCodes(value);
                        print('Received data: $data');
                        setState(() {
                          _receivedData.add(data);
                          if (_receivedData.length > 100) {
                            _receivedData.removeAt(0);
                          }
                        });
                      }
                    });
                  }
                }
              }
              return; // Exit after setting up the device
            } catch (e) {
              print('Error setting up notifications for HC-05: $e');
            }
          } catch (e) {
            print('Error connecting to HC-05: $e');
          }
        }
      }

      // If we get here, no HC-05 devices were found
      print('No HC-05 devices found');
      setState(() {
        _isConnected = false;
        _statusMessage = 'No HC-05 devices connected';
      });
    } catch (e) {
      print('Error checking existing connections: $e');
      setState(() {
        _isConnected = false;
        _statusMessage = 'Error checking connections: $e';
      });
    }
  }

  void _startBluetoothScan() async {
    try {
      // Stop any existing scan
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();

      setState(() {
        _isScanning = true;
        _availableDevices = [];
        _statusMessage = 'Scanning for devices...';
      });

      // Start new scan with comprehensive configuration
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          print('Found ${results.length} devices');
          for (var result in results) {
            print('Device: ${result.device.name} (${result.device.remoteId})');
          }
          setState(() {
            _availableDevices = results;
          });
        },
        onError: (e) {
          print('Scan error: $e');
          setState(() {
            _isScanning = false;
            _statusMessage = 'Scan error: $e';
          });
        },
      );

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidScanMode: AndroidScanMode.lowLatency,
        androidUsesFineLocation: true,
      );

      print('Scan started successfully');

      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 10));

      setState(() {
        _isScanning = false;
        _statusMessage =
            _availableDevices.isEmpty
                ? 'No devices found. Please ensure your device is powered on and in pairing mode.'
                : 'Scan complete. Found ${_availableDevices.length} devices.';
      });
    } catch (e) {
      print('Scan failed: $e');
      setState(() {
        _isScanning = false;
        _statusMessage = 'Scan failed: $e';
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      setState(() {
        _statusMessage = 'Connecting to ${device.name}...';
      });

      // Cancel any existing connection
      if (_connectedDevice != null) {
        await _connectedDevice?.disconnect();
      }

      // Connect to new device
      await device.connect(timeout: const Duration(seconds: 5));

      setState(() {
        _connectedDevice = device;
        _isConnected = true;
        _deviceName = device.name;
        _statusMessage = 'Connected to ${device.name}';
      });

      // Discover services and characteristics
      final services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.read) {
            await characteristic.setNotifyValue(true);
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
    } catch (e) {
      setState(() {
        _isConnected = false;
        _statusMessage = 'Connection failed: $e';
      });
    }
  }

  Widget _buildDeviceCard(BluetoothDevice device) {
    final bool isHC05 = device.name.toLowerCase().contains('hc-05');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isHC05 ? Colors.blue.shade50 : null,
      child: ListTile(
        leading: Icon(
          isHC05 ? Icons.bluetooth_searching : Icons.bluetooth,
          color: isHC05 ? Colors.blue : Colors.grey,
        ),
        title: Text(
          device.name.isNotEmpty ? device.name : 'Unknown Device',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isHC05 ? Colors.blue : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.remoteId.toString()),
            if (isHC05)
              const Text(
                'HC-05 Bluetooth Module',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _connectToDevice(device),
          child: const Text('Connect'),
        ),
      ),
    );
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
                                      return _buildDeviceCard(device);
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
    _scanSubscription?.cancel();
    _connectedDevice?.disconnect();
    super.dispose();
  }
}
