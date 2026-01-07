import 'package:flutter/material.dart';
import '../widgets/base_screen_layout.dart';

class B2BDocumentsScreen extends StatelessWidget {
  const B2BDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Documentos B2B',
      child: Center(
        child: Text(
          'Em breve: Documentos B2B',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
} 
