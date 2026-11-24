import 'package:flutter/material.dart';
import 'package:flutter_run_tracker_app/data/run_repository.dart';
import 'package:flutter_run_tracker_app/views/add_run_ui.dart';
import 'package:flutter_run_tracker_app/views/update_delete_run_ui.dart';

class ShowAllRunUI extends StatefulWidget {
  const ShowAllRunUI({super.key});
  @override
  State<ShowAllRunUI> createState() => _ShowAllRunUIState();
}

class _ShowAllRunUIState extends State<ShowAllRunUI> {
  final _repository = RunRepository();
  late Future<List<RunEntry>> _runs;
  @override
  void initState() {
    super.initState();
    _runs = _repository.all();
  }

  Future<void> _refresh() async {
    final next = _repository.all();
    setState(() {
      _runs = next;
    });
    await next;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Run Tracker')),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xff090150),
          foregroundColor: Colors.white,
          onPressed: () async {
            await Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AddRunUi()));
            if (mounted) _refresh();
          },
          child: const Icon(Icons.add),
        ),
        body: FutureBuilder<List<RunEntry>>(
          future: _runs,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _StatusView(
                icon: Icons.cloud_off_outlined,
                title: 'โหลดข้อมูลไม่สำเร็จ',
                detail: _repository.messageFor(snapshot.error!),
                action: FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('ลองอีกครั้ง')),
              );
            }
            final runs = snapshot.data ?? const <RunEntry>[];
            if (runs.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 112),
                    children: [
                      Image.asset('assests/images/logo.png',
                          width: 138, height: 138),
                      const SizedBox(height: 18),
                      Text('วิ่งกันเถอะ',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(
                          'ยังไม่มีรายการวิ่ง\nกดปุ่มด้านล่างเพื่อบันทึกการวิ่งครั้งแรก',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade700, height: 1.6)),
                    ]),
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 104),
                itemCount: runs.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) return const _RunHeader();
                  final entry = runs[index - 1];
                  return _RunCard(
                    entry: entry,
                    repository: _repository,
                    onTap: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => UpdateDeleteRunUi(entry: entry)));
                      if (mounted) _refresh();
                    },
                  );
                },
              ),
            );
          },
        ),
      );
}

class _RunHeader extends StatelessWidget {
  const _RunHeader();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 2),
        child: Column(
          children: [
            Image.asset('assests/images/logo.png', width: 138, height: 138),
            const SizedBox(height: 18),
            Text(
              'วิ่งกันเถอะ',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
}

class _RunCard extends StatelessWidget {
  const _RunCard(
      {required this.entry, required this.repository, required this.onTap});
  final RunEntry entry;
  final RunRepository repository;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xffe9f6ed),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _RunThumbnail(imageUrl: entry.imageUrl, repository: repository),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'วิ่งที่ไหน: ${entry.where}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'ชื่อผู้วิ่ง: ${entry.person}  •  ระยะทาง: ${entry.distance} กม.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.grey.shade800, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'วันที่: ${_formatDate(entry.createdAt)}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ),
      );
}

class _RunThumbnail extends StatelessWidget {
  const _RunThumbnail({required this.imageUrl, required this.repository});
  final String? imageUrl;
  final RunRepository repository;
  @override
  Widget build(BuildContext context) {
    final hasPhoto = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return SizedBox(
      width: 72,
      height: 72,
      child: hasPhoto
          ? FutureBuilder<String?>(
              future: repository.displayUrl(imageUrl),
              builder: (context, snapshot) {
                if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return _photoPlaceholder();
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(snapshot.data!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder()),
                );
              },
            )
          : _placeholder(),
    );
  }

  Widget _photoPlaceholder() => DecoratedBox(
        decoration: BoxDecoration(
            color: const Color(0xffeeeeF5),
            borderRadius: BorderRadius.circular(12)),
      );

  Widget _placeholder() => DecoratedBox(
        decoration: BoxDecoration(
            color: const Color(0xffeeeeF5),
            borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.directions_run,
            color: Color(0xff090150), size: 34),
      );
}

class _StatusView extends StatelessWidget {
  const _StatusView(
      {required this.icon,
      required this.title,
      required this.detail,
      this.action});
  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 54, color: const Color(0xff090150)),
              const SizedBox(height: 14),
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(detail, textAlign: TextAlign.center),
              if (action != null) ...[const SizedBox(height: 18), action!],
            ],
          )));
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
