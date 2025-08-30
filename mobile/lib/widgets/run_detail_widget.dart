import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/utils/format_utils.dart';

class RunDetailWidget extends StatelessWidget {
  final Run run;
  const RunDetailWidget({super.key, required this.run});

  @override
  Widget build(BuildContext context) {
    final routePoints = (run.route ?? [])
        .map((p) => NLatLng(p['lat'], p['lng']))
        .toList();
    final splits = run.splits ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 300,
            color: Colors.grey.shade200,
            child: NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: routePoints.isNotEmpty
                      ? routePoints[routePoints.length ~/ 2]
                      : const NLatLng(37.5665, 126.9780),
                  zoom: 15,
                ),
              ),
              onMapReady: (controller) {
                if (routePoints.isNotEmpty) {
                  // ----> 이 부분을 수정합니다! <----
                  controller.updateCamera(
                    NCameraUpdate.fitBounds(
                      NLatLngBounds.from(routePoints),
                      padding: const EdgeInsets.all(
                        50,
                      ), // 50 -> const EdgeInsets.all(50)
                    ),
                  );
                  controller.addOverlay(
                    NPolylineOverlay(
                      id: 'path',
                      coords: routePoints,
                      color: Colors.blueAccent,
                      width: 5,
                    ),
                  );

                  for (var split in splits) {
                    final int km = split['split'];
                    if (km > 0 &&
                        run.chartData != null &&
                        run.chartData!.isNotEmpty) {
                      final pointData = run.chartData!.firstWhere(
                        (d) => (d['distance'] / 1000).floor() == km,
                        orElse: () => null,
                      );
                      if (pointData != null) {
                        controller.addOverlay(
                          NMarker(
                            id: 'split_$km',
                            position: NLatLng(
                              pointData['lat'],
                              pointData['lng'],
                            ),
                            caption: NOverlayCaption(text: '$km'),
                          ),
                        );
                      }
                    }
                  }
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (run.title != null && run.title!.isNotEmpty) ...[
                  Text(
                    run.title!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  FormatUtils.formatDate(run.createdAt),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                Text(
                  FormatUtils.formatDistance(run.distance),
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatColumn(
                        AppStrings.runTime,
                        FormatUtils.formatDuration(run.duration),
                      ),
                    ),
                    Expanded(
                      child: _buildStatColumn(
                        AppStrings.runAvgPace,
                        FormatUtils.formatPace(run.avgPace),
                      ),
                    ),
                    Expanded(
                      child: _buildStatColumn(
                        AppStrings.runCalories,
                        run.caloriesBurned?.toStringAsFixed(0) ?? '--',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildDetailRow(
                  AppStrings.runElevation,
                  '${run.totalElevationGain?.toStringAsFixed(1) ?? '--'} m',
                ),
                _buildDetailRow(
                  AppStrings.runCadence,
                  '${run.avgCadence?.toString() ?? '--'} spm',
                ),
                _buildDetailRow(AppStrings.runBPM, '--'),
                if (run.notes != null && run.notes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    '메모',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(run.notes!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
