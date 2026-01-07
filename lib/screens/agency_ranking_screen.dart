import 'package:flutter/material.dart';
import '../widgets/base_screen_layout.dart';

class AgencyRankingScreen extends StatelessWidget {
  const AgencyRankingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Ranking de Agências',
      child: Center(
        child: Text(
          'Em breve: Ranking de Agências',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
} 
