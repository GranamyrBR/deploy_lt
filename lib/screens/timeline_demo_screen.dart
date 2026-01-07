import 'package:flutter/material.dart';
import '../widgets/sales_timeline_widget.dart';
import '../widgets/base_screen_layout.dart';

class TimelineDemoScreen extends StatefulWidget {
  const TimelineDemoScreen({super.key});

  @override
  State<TimelineDemoScreen> createState() => _TimelineDemoScreenState();
}

class _TimelineDemoScreenState extends State<TimelineDemoScreen> {
  int currentStep = 1;
  final List<ActivityItem> activities = [
    const ActivityItem(
      title: 'Lead Capturado',
      description: 'Cliente João Silva demonstrou interesse em pacote para Nova York',
      time: '10:30 - 15/01/2024',
      icon: Icons.person_add,
      color: Colors.blue,
    ),
    const ActivityItem(
      title: 'Proposta Enviada',
      description: 'Orçamento de USD 2.500 enviado por email',
      time: '14:15 - 15/01/2024',
      icon: Icons.description,
      color: Colors.orange,
    ),
    const ActivityItem(
      title: 'Negociação Iniciada',
      description: 'Cliente solicitou desconto de 10%',
      time: '16:45 - 15/01/2024',
      icon: Icons.handshake,
      color: Colors.purple,
    ),
    const ActivityItem(
      title: 'Pagamento Confirmado',
      description: 'Pagamento de BRL 12.500 recebido (taxa 5.0)',
      time: '09:20 - 16/01/2024',
      icon: Icons.payment,
      color: Colors.green,
    ),
    const ActivityItem(
      title: 'Venda Finalizada',
      description: 'Documentação enviada e venda concluída',
      time: '11:00 - 16/01/2024',
      icon: Icons.check_circle,
      color: Colors.teal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Timeline Demo',
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline horizontal de vendas
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Timeline de Vendas (Horizontal)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SalesTimelineWidget(
                        steps: const [
                          TimelineStep(
                            title: 'Lead',
                            description: 'Cliente identificado',
                            icon: Icons.person_add,
                          ),
                          TimelineStep(
                            title: 'Proposta',
                            description: 'Orçamento enviado',
                            icon: Icons.description,
                          ),
                          TimelineStep(
                            title: 'Negociação',
                            description: 'Em processo',
                            icon: Icons.handshake,
                          ),
                          TimelineStep(
                            title: 'Pagamento',
                            description: 'Confirmado',
                            icon: Icons.payment,
                          ),
                          TimelineStep(
                            title: 'Finalizado',
                            description: 'Venda concluída',
                            icon: Icons.check_circle,
                          ),
                        ],
                        currentStep: currentStep,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: currentStep > 0
                                ? () => setState(() => currentStep--)
                                : null,
                            child: const Text('Anterior'),
                          ),
                          ElevatedButton(
                            onPressed: currentStep < 4
                                ? () => setState(() => currentStep++)
                                : null,
                            child: const Text('Próximo'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Timeline vertical de atividades
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Histórico de Atividades (Vertical)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ActivityTimeline(activities: activities),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Exemplo de status de venda
              SaleStatusTimeline(status: 'negociacao'),
            ],
          ),
        ),
      ),
    );
  }
} 
