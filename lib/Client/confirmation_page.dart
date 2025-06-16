import 'package:flutter/material.dart';
import 'package:car_mobile/Client/homeClient.dart';

class ConfirmationPage extends StatelessWidget {
  final dynamic demande;
  final bool isFixed;

  const ConfirmationPage({
    Key? key,
    required this.demande,
    required this.isFixed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Demande confirmée !',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text('Référence: #${demande['id']}'),
            Text('Statut: ${demande['status']}'),
            if (isFixed && demande['atelier'] != null)
              Text('Atelier: ${demande['atelier']['nom_commercial']}'),
            if (demande['date_maintenance'] != null)
              Text('Date: ${demande['date_maintenance']}'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => ClientHomePage()),
                    (route) => false,
              ),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}