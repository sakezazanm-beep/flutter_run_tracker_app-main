import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_run_tracker_app/data/run_repository.dart';
import 'package:image_picker/image_picker.dart';

class UpdateDeleteRunUi extends StatefulWidget {
  const UpdateDeleteRunUi({super.key, required this.entry});
  final RunEntry entry;
  @override
  State<UpdateDeleteRunUi> createState() => _UpdateDeleteRunUiState();
}

class _UpdateDeleteRunUiState extends State<UpdateDeleteRunUi> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _whereController;
  late final TextEditingController _personController;
  late final TextEditingController _distanceController;
  final _picker = ImagePicker();
  final _repository = RunRepository();
  XFile? _replacementImage;
  Uint8List? _replacementImageBytes;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _whereController = TextEditingController(text: widget.entry.where);
    _personController = TextEditingController(text: widget.entry.person);
    _distanceController =
        TextEditingController(text: widget.entry.distance.toString());
  }

  @override
  void dispose() {
    _whereController.dispose();
    _personController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
                child: Wrap(children: [
              ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('ถ่ายภาพ'),
                  onTap: () => Navigator.pop(context, ImageSource.camera)),
              ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('เลือกจากคลังภาพ'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery)),
            ])));
    if (source == null) return;
    try {
      final image = await _picker.pickImage(
          source: source, imageQuality: 82, maxWidth: 1800);
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (mounted) {
          setState(() {
            _replacementImage = image;
            _replacementImageBytes = bytes;
          });
        }
      }
    } catch (error) {
      if (mounted) _notice(_repository.messageFor(error), isError: true);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _repository.update(
          entry: widget.entry,
          where: _whereController.text,
          person: _personController.text,
          distance: int.parse(_distanceController.text.trim()),
          replacementImage: _replacementImage);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _notice(_repository.messageFor(error), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('ลบรายการวิ่ง?'),
              content: const Text('รายการนี้จะถูกลบ รวมถึงภาพที่จัดเก็บไว้'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('ยกเลิก')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('ลบ')),
              ],
            ));
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await _repository.delete(widget.entry);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _notice(_repository.messageFor(error), isError: true);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _notice(String message, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : null));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('แก้ไข / ลบรายการ')),
        body: SafeArea(
            child: Form(
                key: _formKey,
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  Text('แก้ไขรายละเอียด',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 18),
                  TextFormField(
                      controller: _whereController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          labelText: 'สถานที่วิ่ง',
                          prefixIcon: Icon(Icons.place_outlined)),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'กรุณาระบุสถานที่วิ่ง'
                              : null),
                  const SizedBox(height: 14),
                  TextFormField(
                      controller: _personController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          labelText: 'ชื่อผู้วิ่ง',
                          prefixIcon: Icon(Icons.person_outline)),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'กรุณาระบุชื่อผู้วิ่ง'
                              : null),
                  const SizedBox(height: 14),
                  TextFormField(
                      controller: _distanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'ระยะทาง (กิโลเมตร)',
                          prefixIcon: Icon(Icons.straighten)),
                      validator: (value) {
                        final distance = int.tryParse((value ?? '').trim());
                        if (distance == null || distance <= 0) {
                          return 'ระยะทางต้องเป็นจำนวนเต็มมากกว่า 0';
                        }
                        return null;
                      }),
                  const SizedBox(height: 22),
                  Text('ภาพถ่าย',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _PhotoPanel(
                      entry: widget.entry,
                      replacement: _replacementImage,
                      replacementBytes: _replacementImageBytes,
                      repository: _repository,
                      onChoose: _chooseImage,
                      onClear: _replacementImage == null
                          ? null
                          : () => setState(() {
                                _replacementImage = null;
                                _replacementImageBytes = null;
                              })),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                      onPressed: _saving || _deleting ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined),
                      label:
                          Text(_saving ? 'กำลังบันทึก...' : 'บันทึกการแก้ไข')),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                      onPressed: _saving || _deleting ? null : _delete,
                      icon: _deleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.delete_outline),
                      label: Text(_deleting ? 'กำลังลบ...' : 'ลบรายการ'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700)),
                ]))),
      );
}

class _PhotoPanel extends StatelessWidget {
  const _PhotoPanel(
      {required this.entry,
      required this.replacement,
      required this.replacementBytes,
      required this.repository,
      required this.onChoose,
      required this.onClear});
  final RunEntry entry;
  final XFile? replacement;
  final Uint8List? replacementBytes;
  final RunRepository repository;
  final VoidCallback onChoose;
  final VoidCallback? onClear;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onChoose,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 190,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffe5e5ee))),
        clipBehavior: Clip.antiAlias,
        child: replacement != null
            ? Stack(fit: StackFit.expand, children: [
                Image.memory(replacementBytes!, fit: BoxFit.cover),
                _closeButton()
              ])
            : entry.imageUrl == null || entry.imageUrl!.isEmpty
                ? const Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_a_photo_outlined,
                        size: 38, color: Color(0xff090150)),
                    SizedBox(height: 8),
                    Text('แตะเพื่อเพิ่มภาพ')
                  ]))
                : FutureBuilder<String?>(
                    future: repository.displayUrl(entry.imageUrl),
                    builder: (context, snapshot) => snapshot.data == null
                        ? const Center(child: CircularProgressIndicator())
                        : Stack(fit: StackFit.expand, children: [
                            Image.network(snapshot.data!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image_outlined))),
                            _closeButton()
                          ]),
                  ),
      ));
  Widget _closeButton() => Positioned(
      right: 8,
      top: 8,
      child: IconButton.filled(
          onPressed: onClear,
          icon: const Icon(Icons.close),
          tooltip: 'ยกเลิกภาพใหม่'));
}
