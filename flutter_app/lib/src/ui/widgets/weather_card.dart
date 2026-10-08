import 'package:flutter/material.dart';
import '../../models/radar_snapshot.dart';
import '../../../themes/app_theme.dart';

class WeatherCard extends StatelessWidget {
  final RadarSnapshot snapshot;

  const WeatherCard({super.key, required this.snapshot});

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
                  Icons.cloud,
                  color: AppTheme.foggyBlue,
                  size: 32,
                ),
                const SizedBox(width: 8),
                Text(
                  'الطقس والضباب',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _WeatherItem(
                  label: 'مستوى الضباب',
                  value: '${snapshot.fogLevel.toStringAsFixed(1)}%',
                  color: AppTheme.foggyBlue,
                ),
                _WeatherItem(
                  label: 'الرؤية',
                  value: '${snapshot.visibilityM.toStringAsFixed(0)}م',
                  color: AppTheme.radarTurquoise,
                ),
                _WeatherItem(
                  label: 'الحرارة',
                  value: '${snapshot.temperatureC.toStringAsFixed(1)}°',
                  color: AppTheme.warningYellow,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _WeatherItem(
                  label: 'الرطوبة',
                  value: '${snapshot.humidityPct.toStringAsFixed(0)}%',
                  color: AppTheme.foggyGray,
                ),
                _WeatherItem(
                  label: 'الرياح',
                  value: '${snapshot.windKph.toStringAsFixed(0)} كم/س',
                  color: AppTheme.radarTurquoise,
                ),
              ],
            ),
            if (snapshot.forecast.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'التوقعات القادمة',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...snapshot.forecast.take(2).map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('+${f['time_offset_minutes']} دقيقة'),
                    Text('ضباب: ${f['fog_level'].toStringAsFixed(0)}%'),
                    Text('${f['temperature_c'].toStringAsFixed(0)}°'),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeatherItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _WeatherItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
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

