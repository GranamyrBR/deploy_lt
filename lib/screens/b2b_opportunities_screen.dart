import 'package:flutter/material.dart';
import '../widgets/base_screen_layout.dart';

class B2BOpportunitiesScreen extends StatelessWidget {
  const B2BOpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Oportunidades B2B',
      child: Center(
        child: Text(
          'Em breve: Oportunidades B2B',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
} 
