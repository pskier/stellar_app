import 'package:flutter/material.dart';
import 'package:stellar_pi/model/dancer.dart';

class DancerDetailsScreen extends StatelessWidget {
  final Dancer dancer;

  const DancerDetailsScreen({Key? key, required this.dancer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${dancer.firstName} ${dancer.lastName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Imię: ${dancer.firstName}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Nazwisko: ${dancer.lastName}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('ID grupy: ${dancer.groupId}', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
