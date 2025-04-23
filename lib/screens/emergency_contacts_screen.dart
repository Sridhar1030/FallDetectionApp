import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emergency Contacts',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildContactCard(
                  'Emergency Services',
                  '911',
                  Icons.emergency,
                  Colors.red,
                  () => _makePhoneCall('911'),
                ),
                _buildContactCard(
                  'Family Member 1',
                  '+91 7303150080',
                  Icons.person,
                  Colors.blue,
                  () => _makePhoneCall('+917303150080'),
                ),
                _buildContactCard(
                  'Family Member 2',
                  '+91 9321420928',
                  Icons.person,
                  Colors.blue,
                  () => _makePhoneCall('+919321420928'),
                ),
                _buildContactCard(
                  'Family Member 3',
                  '+91 9820225307',
                  Icons.person,
                  Colors.blue,
                  () => _makePhoneCall('+919820225307'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    String name,
    String number,
    IconData icon,
    Color color,
    VoidCallback onCall,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(name, style: const TextStyle(fontSize: 18)),
        subtitle: Text(number, style: const TextStyle(fontSize: 16)),
        trailing: IconButton(icon: const Icon(Icons.phone), onPressed: onCall),
      ),
    );
  }
}
