import 'package:flutter/material.dart';
import '../widgets/base_screen_layout.dart';

class InfotravelScreen extends StatelessWidget {
  const InfotravelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Integração Infotravel',
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            Text(
              'Página em Construção',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Integração com Infotravel em desenvolvimento',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 32),
            Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sobre a Infotravel:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'A Infotravel e uma plataforma B2B especializada em solucoes turisticas, oferecendo:\n'
                      '• Sistema de reservas online\n'
                      '• Gestao de hoteis e voos\n'
                      '• Ferramentas para operadoras de turismo\n'
                      '• Integracao com fornecedores turisticos',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}