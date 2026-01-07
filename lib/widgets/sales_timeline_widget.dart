import 'package:flutter/material.dart';

class SalesTimelineWidget extends StatelessWidget {
  final List<TimelineStep> steps;
  final int currentStep;

  const SalesTimelineWidget({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldScroll = steps.length * 160 > constraints.maxWidth;
        
        Widget timelineRow = Row(
          mainAxisAlignment: shouldScroll ? MainAxisAlignment.start : MainAxisAlignment.center,
          mainAxisSize: shouldScroll ? MainAxisSize.max : MainAxisSize.min,
          children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;
          final isFuture = index > currentStep;

          return Row(
            children: [
              // Indicador
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? Colors.green 
                      : isCurrent 
                          ? Colors.blue 
                          : Colors.grey[300],
                  shape: BoxShape.circle,
                  border: isCurrent 
                      ? Border.all(color: Colors.blue, width: 2)
                      : null,
                ),
                child: Icon(
                  isCompleted 
                      ? Icons.check 
                      : step.icon ?? Icons.circle,
                  color: isCompleted || isCurrent ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
              ),
              
              // Conteúdo
              Container(
                width: 110,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isCompleted || isCurrent 
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.description,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Conector (exceto para o último item)
              if (index < steps.length - 1)
                Container(
                  width: 40,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: isCompleted ? Colors.green : Colors.grey[300],
                ),
            ],
          );
        }).toList(),
        );

        return shouldScroll 
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: timelineRow,
            )
          : timelineRow;
      },
    );
  }
}

class TimelineStep {
  final String title;
  final String description;
  final IconData? icon;

  const TimelineStep({
    required this.title,
    required this.description,
    this.icon,
  });
}

// Exemplo de uso para status de venda
class SaleStatusTimeline extends StatelessWidget {
  final String status;

  const SaleStatusTimeline({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      const TimelineStep(
        title: 'Lead Capturado',
        description: 'Cliente interessado identificado',
        icon: Icons.person_add,
      ),
      const TimelineStep(
        title: 'Proposta Enviada',
        description: 'Orçamento enviado ao cliente',
        icon: Icons.description,
      ),
      const TimelineStep(
        title: 'Negociação',
        description: 'Em processo de negociação',
        icon: Icons.handshake,
      ),
      const TimelineStep(
        title: 'Pagamento',
        description: 'Pagamento confirmado',
        icon: Icons.payment,
      ),
      const TimelineStep(
        title: 'Finalizado',
        description: 'Venda concluída com sucesso',
        icon: Icons.check_circle,
      ),
    ];

    int currentStep = 0;
    switch (status.toLowerCase()) {
      case 'lead':
        currentStep = 0;
        break;
      case 'proposta':
        currentStep = 1;
        break;
      case 'negociacao':
        currentStep = 2;
        break;
      case 'pagamento':
        currentStep = 3;
        break;
      case 'finalizado':
        currentStep = 4;
        break;
      default:
        currentStep = 0;
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status da Venda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            SalesTimelineWidget(
              steps: steps,
              currentStep: currentStep,
            ),
          ],
        ),
      ),
    );
  }
}

// Timeline vertical para histórico de atividades - versão nativa
class ActivityTimeline extends StatelessWidget {
  final List<ActivityItem> activities;

  const ActivityTimeline({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: activities.asMap().entries.map((entry) {
        final index = entry.key;
        final activity = entry.value;
        final isLast = index == activities.length - 1;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador com linha
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: activity.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    activity.icon,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                                  if (!isLast)
                    Container(
                      width: 2,
                      height: 60,
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
              ],
            ),
            const SizedBox(width: 16),
            // Conteúdo
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.description,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.time,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class ActivityItem {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color color;

  const ActivityItem({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.color,
  });
} 
