import 'package:flutter/material.dart';

class InformationScreen extends StatelessWidget {
  const InformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Important Information',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildInfoCard(
                  'What to do in case of a fall',
                  '1. Stay calm and try to remain still\n2. Check for injuries\n3. Call for help if possible\n4. Use emergency button if available',
                  Icons.warning,
                ),
                _buildInfoCard(
                  'Device Maintenance',
                  '• Charge device daily\n• Keep device clean and dry\n• Check for updates regularly',
                  Icons.settings,
                ),
                _buildInfoCard(
                  'Emergency Procedures',
                  '• Press and hold emergency button for 3 seconds\n• System will automatically alert emergency contacts\n• Stay on the line with emergency services',
                  Icons.emergency,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 32, color: Colors.blue),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(content, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
