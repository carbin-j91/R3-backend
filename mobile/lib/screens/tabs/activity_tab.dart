import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/models/stats.dart'
    as stats_model; // 1. 이름 충돌을 피하기 위해 별칭(alias) 사용
import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/format_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/screens/run_detail_screen.dart';
import 'package:intl/intl.dart';

enum StatsPeriod { weekly, monthly, yearly, all }

class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  StatsPeriod _selectedPeriod = StatsPeriod.weekly;
  Future<stats_model.Stats>? _statsFuture;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  void _fetchStats() {
    setState(() {
      _statsFuture = ApiService.getUserStats(_selectedPeriod.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildPeriodSelector(),
              const SizedBox(height: 24),
              FutureBuilder<stats_model.Stats>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text(AppStrings.activityStatsError));
                  }
                  if (!snapshot.hasData || snapshot.data!.chartData.isEmpty) {
                    return const Center(child: Text(AppStrings.activityNoData));
                  }
                  final stats = snapshot.data!;
                  return Column(
                    children: [
                      _buildStatsSummary(stats),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 200,
                        child: _buildBarChart(stats.chartData),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
        // 2. RunningRecordsList를 여기에 직접 포함시킵니다.
        const RunningRecordsList(),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return SegmentedButton<StatsPeriod>(
      segments: const <ButtonSegment<StatsPeriod>>[
        ButtonSegment(
          value: StatsPeriod.weekly,
          label: Text(AppStrings.activityPeriodWeekly),
        ),
        ButtonSegment(
          value: StatsPeriod.monthly,
          label: Text(AppStrings.activityPeriodMonthly),
        ),
        ButtonSegment(
          value: StatsPeriod.yearly,
          label: Text(AppStrings.activityPeriodYearly),
        ),
        ButtonSegment(
          value: StatsPeriod.all,
          label: Text(AppStrings.activityPeriodAll),
        ),
      ],
      selected: {_selectedPeriod},
      onSelectionChanged: (Set<StatsPeriod> newSelection) {
        setState(() {
          _selectedPeriod = newSelection.first;
          _fetchStats();
        });
      },
    );
  }

  Widget _buildStatsSummary(stats_model.Stats stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatColumn(
          '거리',
          FormatUtils.formatDistance(stats.totalDistanceKm * 1000),
        ),
        _buildStatColumn('횟수', '${stats.totalRuns}회'),
        _buildStatColumn('평균 페이스', FormatUtils.formatPace(stats.avgPacePerKm)),
        _buildStatColumn(
          '시간',
          FormatUtils.formatDuration(stats.totalDurationSeconds),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildBarChart(List<stats_model.BarChartData> chartData) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= chartData.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta, // ← axisSide 대신 meta 사용!
                  child: Text(
                    chartData[idx].label,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: chartData.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: Colors.blueAccent,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// 4. 러닝 기록 목록 관련 위젯들을 이 파일로 이동시킵니다.
class RunningRecordsList extends StatefulWidget {
  const RunningRecordsList({super.key});
  @override
  State<RunningRecordsList> createState() => _RunningRecordsListState();
}

class _RunningRecordsListState extends State<RunningRecordsList> {
  Future<List<Run>>? runsFuture;

  @override
  void initState() {
    super.initState();
    runsFuture = ApiService.getRuns();
  }

  void refreshRuns() {
    setState(() {
      runsFuture = ApiService.getRuns();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Run>>(
      future: runsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('기록을 불러오는데 실패했습니다: ${snapshot.error}'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: refreshRuns,
                  child: const Text(AppStrings.activityTryAgain),
                ),
              ],
            ),
          );
        }
        if (snapshot.hasData) {
          final runs = snapshot.data!;
          if (runs.isEmpty) {
            return const Center(
              child: Text(
                AppStrings.activityNoRuns,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            // ListView 안에 ListView를 넣을 때 필요한 설정
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: runs.length,
            itemBuilder: (context, index) {
              return RunListItem(
                run: runs[index],
                onRecordDeleted: refreshRuns,
              );
            },
          );
        }
        return const Center(child: Text('기록을 불러올 수 없습니다.'));
      },
    );
  }
}

class RunListItem extends StatelessWidget {
  final Run run;
  final VoidCallback onRecordDeleted;
  const RunListItem({
    super.key,
    required this.run,
    required this.onRecordDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          run.title ?? FormatUtils.formatDate(run.createdAt),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '거리: ${FormatUtils.formatDistance(run.distance)} / 시간: ${FormatUtils.formatDuration(run.duration)}',
        ),
        onTap: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => RunDetailScreen(runId: run.id),
            ),
          );
          if (result == true) {
            onRecordDeleted();
          }
        },
      ),
    );
  }
}
