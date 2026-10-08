import 'package:flutter/material.dart';
import '../../models/radar_snapshot.dart';
import '../../../themes/app_theme.dart';

class RadarSummaryCard extends StatelessWidget {
  final RadarSnapshot snapshot;

  const RadarSummaryCard({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.radar,
                  color: AppTheme.radarTurquoise,
                  size: 32,
                ),
                const SizedBox(width: 8),
                Text(
                  'ملخص الرادار',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  icon: Icons.warning,
                  label: 'العوائق',
                  value: '${snapshot.obstacles.length}',
                  color: AppTheme.warningYellow,
                ),
                _SummaryItem(
                  icon: Icons.directions_car,
                  label: 'المركبات',
                  value: '${snapshot.vehicles.length}',
                  color: AppTheme.radarTurquoise,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

