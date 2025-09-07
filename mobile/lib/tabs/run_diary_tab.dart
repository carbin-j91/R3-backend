import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/format_utils.dart';

class RunDiaryTab extends StatefulWidget {
  const RunDiaryTab({super.key});

  @override
  State<RunDiaryTab> createState() => _RunDiaryTabState();
}

class _RunDiaryTabState extends State<RunDiaryTab> {
  DateTime _focusedMonth = DateUtils.dateOnly(DateTime.now());
  DateTime? _selectedDate;
  Future<List<Run>>? _runsFuture;
  List<Run> _allRuns = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(DateTime.now());
    _runsFuture = _loadRuns(); // 최초 한번 전체 로드 (필요시 월별 API로 대체 가능)
  }

  Future<List<Run>> _loadRuns() async {
    final runs = await ApiService.getRuns();
    // createdAt이 null일 수 있다면 방어
    _allRuns = runs.where((r) => r.createdAt != null).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _allRuns;
  }

  List<Run> _runsOfDate(DateTime day) {
    return _allRuns.where((r) {
      final d = DateUtils.dateOnly(r.createdAt);
      return d == DateUtils.dateOnly(day);
    }).toList();
  }

  double _sumDistanceOfDate(DateTime day) {
    return _runsOfDate(
      day,
    ).fold<double>(0.0, (sum, r) => sum + (r.distance ?? 0));
  }

  bool _hasDiary(DateTime day) {
    // 임시: notes가 존재하면 “일기 있음”으로 간주
    return _runsOfDate(
      day,
    ).any((r) => (r.notes != null && r.notes!.trim().isNotEmpty));
  }

  void _goToPrevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
      // 선택일은 유지(같은 일자 존재 보장 X) → 월 이동 시 1일로 맞추기
      _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
      _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Run>>(
      future: _runsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text('${AppStrings.activityStatsError}\n${snap.error}'),
          );
        }

        return SafeArea(
          // ✅ 하단 시스템 패딩 반영
          bottom: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxH = constraints.maxHeight;

              // 헤더 예상 고정치 (디바이스/폰트 따라 약간 차이 → 여유치 포함)
              const double kMonthHeaderH = 52;
              const double kWeekdayHeaderH = 26;
              const double kGaps = 16; // SizedBox(8)+SizedBox(8)
              const double kDividerH = 1;
              final double headerH = kMonthHeaderH + kWeekdayHeaderH + kGaps;

              // 패널 높이: 화면 0.32 비중, [200, 320] 범위, 그리고 '헤더+캘린더 최소' 여백 고려하여 clamp
              final double tentativePanel = (maxH * 0.32).clamp(200.0, 320.0);
              // 캘린더 최소 높이(5주 × 최소 셀 높이 22 + 간격) 대략 5*22 + 4*8 ≈ 148
              const double kCalendarMin = 148;
              final double panelH = (maxH - headerH - kDividerH - kCalendarMin)
                  .clamp(160.0, tentativePanel);

              return Column(
                children: [
                  _buildMonthHeader(),
                  const SizedBox(height: 8),
                  _buildWeekdayHeader(),
                  const SizedBox(height: 8),

                  // ✅ 캘린더는 남은 높이를 꽉 채우게
                  Expanded(
                    child: _buildCalendarGrid5x7(), // 아래 B 섹션
                  ),

                  const Divider(height: kDividerH),

                  // ✅ 하단 패널: 고정 높이 + 내부 스크롤
                  SizedBox(
                    height: panelH,
                    child: _buildDayDetailPanelScrollable(),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCalendarGrid5x7() {
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );

    // Flutter weekday: Mon=1..Sun=7 → Sun=0 기준
    final int startWeekday = firstOfMonth.weekday % 7; // 0=Sun, 1=Mon, ...
    const int rows = 5;
    const int cols = 7;
    const int totalCells = rows * cols; // 35

    // 앞쪽(이전달) 채움 개수
    final int leading = startWeekday; // Sun 시작이면 0
    // 뒤쪽(다음달) 채움 개수(음수면 6주가 필요하단 뜻 → 5주에 맞게 자릅니다)
    int trailing = totalCells - leading - daysInMonth;

    // 생성 셀들
    final List<_CalendarCell> cells = [];

    // 1) 이전 달 날짜 채우기 (연속성/탁상달력 느낌 유지)
    final prevMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    final prevDays = DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);
    for (int i = 0; i < leading; i++) {
      final dayNum = prevDays - leading + 1 + i;
      final day = DateTime(prevMonth.year, prevMonth.month, dayNum);
      cells.add(
        _CalendarCell(
          day: day,
          inThisMonth: false,
          isSelected:
              _selectedDate != null && DateUtils.isSameDay(_selectedDate!, day),
          isToday: DateUtils.isSameDay(DateTime.now(), day),
          totalDistanceMeters: _sumDistanceOfDate(day),
          hasDiary: _hasDiary(day),
          onTap: () => setState(() => _selectedDate = day),
        ),
      );
    }

    // 2) 이번 달 날짜
    // 6주가 필요한 달의 경우, 마지막 주 일부가 잘릴 수 있음(요구사항: 최대 5주)
    final int maxThisMonthCount =
        (totalCells - leading - (trailing < 0 ? 0 : trailing)).clamp(
          0,
          daysInMonth,
        );
    for (int d = 1; d <= maxThisMonthCount; d++) {
      final day = DateTime(_focusedMonth.year, _focusedMonth.month, d);
      cells.add(
        _CalendarCell(
          day: day,
          inThisMonth: true,
          isSelected:
              _selectedDate != null && DateUtils.isSameDay(_selectedDate!, day),
          isToday: DateUtils.isSameDay(DateTime.now(), day),
          totalDistanceMeters: _sumDistanceOfDate(day),
          hasDiary: _hasDiary(day),
          onTap: () => setState(() => _selectedDate = day),
        ),
      );
    }

    // 3) 다음 달 날짜로 나머지 채우기 (trailing<0이면 6주 필요 → 5주 제한으로 잘라서 안 채움)
    if (cells.length < totalCells) {
      final nextMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + 1,
        1,
      );
      int nd = 1;
      while (cells.length < totalCells) {
        final day = DateTime(nextMonth.year, nextMonth.month, nd++);
        cells.add(
          _CalendarCell(
            day: day,
            inThisMonth: false,
            isSelected:
                _selectedDate != null &&
                DateUtils.isSameDay(_selectedDate!, day),
            isToday: DateUtils.isSameDay(DateTime.now(), day),
            totalDistanceMeters: _sumDistanceOfDate(day),
            hasDiary: _hasDiary(day),
            onTap: () => setState(() => _selectedDate = day),
          ),
        );
      }
    }

    // ✅ 현재 가용 영역에 맞춰 셀 비율 계산 → 칸이 빡빡해도 5줄 안에서 안전
    return LayoutBuilder(
      builder: (context, cons) {
        const double spacing = 8.0;
        final double padH = 16.0; // 좌우 padding 8+8
        final usableW = (cons.maxWidth - padH) - (cols - 1) * spacing;
        final usableH = (cons.maxHeight) - (rows - 1) * spacing;

        final cellW = usableW / cols;
        final cellH = usableH / rows;
        final childAspectRatio = (cellW / cellH).clamp(0.75, 1.4);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GridView.count(
            crossAxisCount: cols,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
            physics: const NeverScrollableScrollPhysics(), // 캘린더는 스크롤 없음
            children: cells,
          ),
        );
      },
    );
  }

  Widget _buildDayDetailPanelScrollable() {
    final selected = _selectedDate ?? DateTime.now();
    final runs = _runsOfDate(selected);
    final totalDistance = runs.fold<double>(
      0.0,
      (s, r) => s + (r.distance ?? 0),
    );

    return Container(
      width: double.infinity,
      color: const Color(0xFFF7F7F9),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  FormatUtils.formatDate(selected),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${AppStrings.activityRuns}: ${runs.length} · '
                  '${FormatUtils.formatDistance(totalDistance)}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (runs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  AppStrings.activityNoRuns,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              ...runs.map((r) => _DayRunTile(run: r)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    final y = _focusedMonth.year;
    final m = _focusedMonth.month;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _goToPrevMonth,
          ),
          Expanded(
            child: Center(
              child: Text(
                '$y.${m.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _goToNextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    // 일~토 (원하시면 현지화/월요일 시작으로 변경 가능)
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: List.generate(7, (i) {
          final isWeekend = (i == 0) || (i == 6);
          return Expanded(
            child: Center(
              child: Text(
                labels[i],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isWeekend ? Colors.redAccent : Colors.grey.shade700,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCalendarGrid({double childAspectRatio = 1.0}) {
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    final int startWeekday = firstOfMonth.weekday % 7; // Sun=0

    const totalCells = 42;
    final cells = List.generate(totalCells, (index) {
      final dayNum = index - startWeekday + 1;
      DateTime? day;
      bool inThisMonth = (dayNum >= 1 && dayNum <= daysInMonth);
      if (inThisMonth) {
        day = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
      } else {
        if (dayNum < 1) {
          final prevMonth = DateTime(
            _focusedMonth.year,
            _focusedMonth.month - 1,
            1,
          );
          final prevDays = DateUtils.getDaysInMonth(
            prevMonth.year,
            prevMonth.month,
          );
          final d = prevDays + dayNum;
          day = DateTime(prevMonth.year, prevMonth.month, d);
        } else {
          final nextMonth = DateTime(
            _focusedMonth.year,
            _focusedMonth.month + 1,
            1,
          );
          final d = dayNum - daysInMonth;
          day = DateTime(nextMonth.year, nextMonth.month, d);
        }
      }

      return _CalendarCell(
        day: day,
        inThisMonth: inThisMonth,
        isSelected:
            _selectedDate != null && DateUtils.isSameDay(_selectedDate!, day),
        isToday: DateUtils.isSameDay(DateTime.now(), day),
        totalDistanceMeters: _sumDistanceOfDate(day),
        hasDiary: _hasDiary(day),
        onTap: () {
          setState(() {
            _selectedDate = day;
          });
        },
      );
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.count(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: childAspectRatio, // ✅ 셀 비율 조정 가능
        physics: const NeverScrollableScrollPhysics(), // ✅ 내부 스크롤 금지
        shrinkWrap: true, // ✅ 부모 높이 내에서만 배치
        children: cells,
      ),
    );
  }

  Widget _buildDayDetailPanel() {
    final selected = _selectedDate ?? DateTime.now();
    final runs = _runsOfDate(selected);
    final totalDistance = runs.fold<double>(
      0.0,
      (s, r) => s + (r.distance ?? 0),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: const Color(0xFFF7F7F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 라인: 날짜 + 총합
          Row(
            children: [
              Text(
                FormatUtils.formatDate(selected), // YYYY-MM-DD 같은 기존 포맷 사용
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${AppStrings.activityRuns}: ${runs.length} · ${FormatUtils.formatDistance(totalDistance)}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 리스트
          if (runs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                AppStrings.activityNoRuns,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            ...runs.map((r) => _DayRunTile(run: r)),
        ],
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  final DateTime day;
  final bool inThisMonth;
  final bool isSelected;
  final bool isToday;
  final double totalDistanceMeters;
  final bool hasDiary;
  final VoidCallback onTap;

  const _CalendarCell({
    required this.day,
    required this.inThisMonth,
    required this.isSelected,
    required this.isToday,
    required this.totalDistanceMeters,
    required this.hasDiary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // "그날 달리기 여부" 판정: 총 거리 > 0이면 달리기 있음으로 간주
    final hasRun = totalDistanceMeters > 0;

    final baseColor = inThisMonth ? Colors.black : Colors.grey.shade400;
    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.transparent;
    final todayMark = isToday
        ? const TextStyle(fontWeight: FontWeight.w800)
        : const TextStyle();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 2),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
              : null,
        ),
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 날짜 + 일기 아이콘
            Row(
              children: [
                Text(
                  '${day.day}',
                  style: todayMark.merge(TextStyle(color: baseColor)),
                ),
                const SizedBox(width: 4),
                if (hasDiary)
                  const Icon(Icons.edit_note, size: 14, color: Colors.orange),
              ],
            ),

            const Spacer(),

            // 하단 오른쪽: 달리기 '도장' (앱 아이콘)
            Align(
              alignment: Alignment.bottomRight,
              child: Opacity(
                opacity: inThisMonth ? 1.0 : 0.35, // 이번 달이 아니면 흐리게
                child: hasRun
                    ? Image.asset(
                        'assets/images/app_icon.png',
                        width: 18, // 필요에 따라 16~20 사이로 조절
                        height: 18,
                        filterQuality: FilterQuality.high,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayRunTile extends StatelessWidget {
  final Run run;
  const _DayRunTile({required this.run});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // 왼쪽: 작은 아이콘/원형 배지
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_run,
              size: 18,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(width: 10),
          // 가운데: 타이틀/세부
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  run.title ?? AppStrings.activityRun, // 제목 없으면 기본 레이블
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${FormatUtils.formatDistance(run.distance ?? 0)} · '
                  '${FormatUtils.formatDuration(run.duration ?? 0)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if ((run.notes ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    run.notes!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 오른쪽: 화살표
          const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        ],
      ),
    );
  }
}
