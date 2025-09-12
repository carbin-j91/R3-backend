import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/format_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:mobile/widgets/route_thumbnail.dart';
import 'package:mobile/screens/community_screen.dart' show _ComposerResult;

enum OverlayTemplate { minimal, card, bold }

class AlbumComposerScreen extends StatefulWidget {
  const AlbumComposerScreen({super.key});

  @override
  State<AlbumComposerScreen> createState() => _AlbumComposerScreenState();
}

class _AlbumComposerScreenState extends State<AlbumComposerScreen> {
  final _previewKey = GlobalKey();
  final _picker = ImagePicker();

  XFile? _picked;
  Run? _selectedRun;
  OverlayTemplate _template = OverlayTemplate.minimal;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // 도장 아이콘 프리로드(도장/썸네일 깜빡임 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/images/app_icon.png'), context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _picked != null && _selectedRun != null && !_saving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('앨범 만들기'),
        actions: [
          TextButton(
            onPressed: canSave ? _save : null,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildPhotoPicker(),
          const SizedBox(height: 12),
          _buildRunPicker(),
          const SizedBox(height: 12),
          _buildTemplateSelector(),
          const SizedBox(height: 12),
          _buildOverlayPreview(),
        ],
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.photo),
            label: Text(_picked == null ? '갤러리에서 선택' : '사진 변경'),
            onPressed: _pickImage,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('카메라'),
            onPressed: _takePhoto,
          ),
        ),
      ],
    );
  }

  Widget _buildRunPicker() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.directions_run),
      label: Text(_selectedRun == null ? '러닝 기록 선택' : '기록 변경'),
      onPressed: _selectRun,
    );
  }

  Widget _buildTemplateSelector() {
    return SegmentedButton<OverlayTemplate>(
      segments: const [
        ButtonSegment(value: OverlayTemplate.minimal, label: Text('Minimal')),
        ButtonSegment(value: OverlayTemplate.card, label: Text('Card')),
        ButtonSegment(value: OverlayTemplate.bold, label: Text('Bold')),
      ],
      selected: {_template},
      onSelectionChanged: (s) => setState(() => _template = s.first),
    );
  }

  Widget _buildOverlayPreview() {
    final picked = _picked;
    final run = _selectedRun;

    return AspectRatio(
      aspectRatio: 1, // 정사각 미리보기(인스타 대비). 필요시 4:5/16:9 토글 확장 가능
      child: RepaintBoundary(
        key: _previewKey,
        child: Container(
          color: Colors.black, // 배경(사진 없을 때)
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (picked != null)
                Image.file(File(picked.path), fit: BoxFit.cover)
              else
                const Center(
                  child: Text(
                    '사진을 선택하세요',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),

              // 오버레이: 러닝 정보 (run 있을 때만 표기)
              if (run != null) _buildOverlayForTemplate(run),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayForTemplate(Run run) {
    // distance(m) → km, pace: FormatUtils 사용(초/킬로 추정), duration(s)
    final distanceStr = FormatUtils.formatDistance(run.distance ?? 0);
    final durationStr = FormatUtils.formatDuration(run.duration ?? 0);
    final paceStr = run.avgPace != null
        ? FormatUtils.formatPace(run.avgPace!) // 초/킬로 가정
        : (run.distance > 0
              ? FormatUtils.formatPace(
                  (run.duration ?? 0) / (run.distance / 1000),
                )
              : '-');

    final dateStr = FormatUtils.formatDate(run.createdAt);

    switch (_template) {
      case OverlayTemplate.minimal:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              // 우상단: 경로 미니맵 카드
              Positioned(right: 0, top: 0, child: _RouteCard(run: run)),
              // 좌하단: 반투명 정보 카드
              Positioned(
                left: 0,
                bottom: 0,
                child: _InfoCard(
                  title: dateStr ?? '',
                  lines: [
                    '거리 $distanceStr',
                    '시간 $durationStr',
                    '페이스 $paceStr',
                    if ((run.notes ?? '').trim().isNotEmpty)
                      '메모 ${run.notes!.trim()}',
                  ],
                ),
              ),
            ],
          ),
        );

      case OverlayTemplate.card:
        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _WideInfoCard(
              date: dateStr ?? '',
              distance: distanceStr,
              duration: durationStr,
              pace: paceStr,
              notes: (run.notes ?? '').trim(),
              route: run.route,
            ),
          ),
        );

      case OverlayTemplate.bold:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              // 큰 타이포
              Positioned(
                left: 0,
                bottom: 0,
                child: Text(
                  distanceStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                bottom: 56,
                child: Text(
                  dateStr ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                  ),
                ),
              ),
              Positioned(right: 0, top: 0, child: _RouteCard(run: run)),
            ],
          ),
        );
    }
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _picked = x);
  }

  Future<void> _takePhoto() async {
    final x = await _picker.pickImage(source: ImageSource.camera);
    if (x != null) setState(() => _picked = x);
  }

  Future<void> _selectRun() async {
    final chosen = await showModalBottomSheet<Run>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _RunPickerSheet(),
    );
    if (chosen != null) {
      setState(() => _selectedRun = chosen);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final file = await _capturePreviewToFile(_previewKey);
      if (!mounted) return;
      Navigator.pop(context, file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지 저장 중 오류: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ===== 미리보기 캡처 유틸 =====
Future<File> _capturePreviewToFile(GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary; // ✅ OK
  final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
  final ByteData? byteData = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  final bytes = byteData!.buffer.asUint8List();

  final dir = await getTemporaryDirectory();
  final path =
      '${dir.path}/rrr_album_${DateTime.now().millisecondsSinceEpoch}.png';
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

// ===== 오버레이 조각들 =====
class _RouteCard extends StatelessWidget {
  final Run run;
  const _RouteCard({required this.run});

  @override
  Widget build(BuildContext context) {
    final hasRoute = run.route != null && run.route!.length >= 2;
    return Card(
      color: Colors.white.withValues(alpha: 0.9),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 120,
        height: 80,
        child: hasRoute
            ? Padding(
                padding: const EdgeInsets.all(6),
                child: RouteThumbnail(
                  route: (run.route!).cast<Map<String, dynamic>>(),
                  borderRadius: 8,
                ),
              )
            : Center(child: Icon(Icons.map, color: Colors.grey.shade500)),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  const _InfoCard({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withValues(alpha: 0.45),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white, height: 1.25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              ...lines.map(
                (t) => Text(
                  t,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WideInfoCard extends StatelessWidget {
  final String date, distance, duration, pace, notes;
  final List<dynamic>? route;
  const _WideInfoCard({
    required this.date,
    required this.distance,
    required this.duration,
    required this.pace,
    required this.notes,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withValues(alpha: 0.45),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 좌측 요약 텍스트
            Expanded(
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text('거리 $distance · 시간 $duration · 페이스 $pace'),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(notes, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 우측 미니맵
            SizedBox(
              width: 120,
              height: 80,
              child: route != null && route!.length >= 2
                  ? Padding(
                      padding: const EdgeInsets.all(6),
                      child: RouteThumbnail(
                        route: route!.cast<Map<String, dynamic>>(),
                        borderRadius: 8,
                      ),
                    )
                  : Center(child: Icon(Icons.map, color: Colors.grey.shade300)),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== 러닝 기록 선택 시트 =====
class _RunPickerSheet extends StatefulWidget {
  const _RunPickerSheet();

  @override
  State<_RunPickerSheet> createState() => _RunPickerSheetState();
}

class _RunPickerSheetState extends State<_RunPickerSheet> {
  Future<List<Run>>? _runsF;

  @override
  void initState() {
    super.initState();
    _runsF = ApiService.getRuns();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) {
          return Material(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    '러닝 기록 선택',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder<List<Run>>(
                    future: _runsF,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(child: Text('기록을 불러오지 못했습니다.'));
                      }
                      final runs = (snap.data ?? [])
                        ..sort(
                          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                            a.createdAt ?? DateTime(0),
                          ),
                        );
                      if (runs.isEmpty) {
                        return const Center(child: Text('러닝 기록이 없습니다.'));
                      }
                      return ListView.builder(
                        controller: controller,
                        itemCount: runs.length,
                        itemBuilder: (context, i) {
                          final r = runs[i];
                          final title =
                              r.title ??
                              (r.createdAt.toIso8601String() ?? '러닝');
                          final distance = FormatUtils.formatDistance(
                            r.distance ?? 0,
                          );
                          final duration = FormatUtils.formatDuration(
                            r.duration ?? 0,
                          );
                          return ListTile(
                            title: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text('$distance · $duration'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pop(context, r),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
