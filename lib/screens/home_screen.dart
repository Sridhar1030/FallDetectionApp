import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class HomeScreen extends StatefulWidget {
  final List<String> receivedData;
  final bool isConnected;
  final String statusMessage;
  final String? deviceName;

  const HomeScreen({
    super.key,
    required this.receivedData,
    required this.isConnected,
    required this.statusMessage,
    this.deviceName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fall Detection Status',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  widget.isConnected
                      ? Colors.green.shade50
                      : Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Status: ${widget.isConnected ? "Connected" : "Disconnected"}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),
                if (widget.deviceName != null && widget.isConnected)
                  Text(
                    'Connected Device: ${widget.deviceName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  widget.statusMessage,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: widget.receivedData.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                    title: const Text('Fall Detected'),
                    subtitle: Text(widget.receivedData[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
