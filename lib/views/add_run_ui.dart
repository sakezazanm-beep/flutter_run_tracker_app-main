import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_run_tracker_app/data/run_repository.dart';
import 'package:image_picker/image_picker.dart';

class AddRunUi extends StatefulWidget {
  const AddRunUi({super.key});
  @override
  State<AddRunUi> createState() => _AddRunUiState();
}

class _AddRunUiState extends State<AddRunUi> {
  final _formKey = GlobalKey<FormState>();
  final _whereController = TextEditingController();
  final _personController = TextEditingController();
  final _distanceController = TextEditingController();
  final _picker = ImagePicker();
  final _repository = RunRepository();
  XFile? _image;
  Uint8List? _imageBytes;
  bool _saving = false;

  @override
  void dispose() {
    _whereController.dispose();
    _personController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
          source: source, imageQuality: 82, maxWidth: 1800);
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (mounted) {
          setState(() {
            _image = image;
            _imageBytes = bytes;
          });
        }
      }
    } catch (error) {
      if (mounted) _notice(_repository.messageFor(error), isError: true);
    }
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
    if (source != null) await _pickImage(source);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _repository.create(
          where: _whereController.text,
          person: _personController.text,
          distance: int.parse(_distanceController.text.trim()),
          image: _image);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _notice(_repository.messageFor(error), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cancel() {
    _whereController.clear();
    _personController.clear();
    _distanceController.clear();
    setState(() {
      _image = null;
      _imageBytes = null;
    });
    Navigator.pop(context);
  }

  void _notice(String message, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : null));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('เพิ่มรายการวิ่ง')),
        body: SafeArea(
            child: Form(
                key: _formKey,
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  const _SectionTitle(
                      title: 'รายละเอียดการวิ่ง',
                      subtitle: 'กรอกข้อมูลให้ครบก่อนบันทึก'),
                  const SizedBox(height: 20),
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
                  const _SectionTitle(
                      title: 'ภาพถ่าย',
                      subtitle: 'เพิ่มภาพประกอบได้ตามต้องการ'),
                  const SizedBox(height: 10),
                  _ImageChooser(
                      imageBytes: _imageBytes,
                      onChoose: _chooseImage,
                      onClear: () => setState(() {
                            _image = null;
                            _imageBytes = null;
                          })),
                  const SizedBox(height: 28),
                  Row(children: [
                    Expanded(
                        child: OutlinedButton(
                            onPressed: _saving ? null : _cancel,
                            child: const Text('ยกเลิก'))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.save_outlined),
                            label:
                                Text(_saving ? 'กำลังบันทึก...' : 'บันทึก'))),
                  ]),
                ]))),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
      ]);
}

class _ImageChooser extends StatelessWidget {
  const _ImageChooser(
      {required this.imageBytes,
      required this.onChoose,
      required this.onClear});
  final Uint8List? imageBytes;
  final VoidCallback onChoose, onClear;
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
        child: imageBytes == null
            ? const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_a_photo_outlined,
                    size: 38, color: Color(0xff090150)),
                SizedBox(height: 8),
                Text('แตะเพื่อถ่ายภาพหรือเลือกรูป')
              ]))
            : Stack(fit: StackFit.expand, children: [
                Image.memory(imageBytes!, fit: BoxFit.cover),
                Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton.filled(
                        onPressed: onClear,
                        icon: const Icon(Icons.close),
                        tooltip: 'นำภาพออก')),
              ]),
      ));
}
