import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RunEntry {
  const RunEntry(
      {required this.id,
      required this.where,
      required this.person,
      required this.distance,
      required this.createdAt,
      this.imageUrl});
  final String id;
  final String where;
  final String person;
  final int distance;
  final DateTime createdAt;
  final String? imageUrl;

  factory RunEntry.fromMap(Map<String, dynamic> map) => RunEntry(
        id: map['id'].toString(),
        where: map['runWhere'] as String? ?? '',
        person: map['runPreson'] as String? ?? '',
        distance: (map['rinDistance'] as num?)?.toInt() ?? 0,
        imageUrl: map['rinImageUrl'] as String?,
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class RunRepository {
  RunRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;
  static const table = 'run_tb';
  static const bucket = 'run_bk';
  final SupabaseClient _client;

  Future<List<RunEntry>> all() async {
    final rows = await _client
        .from(table)
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => RunEntry.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> create(
      {required String where,
      required String person,
      required int distance,
      XFile? image}) async {
    final imageUrl = image == null ? null : await _upload(image);
    try {
      await _client.from(table).insert({
        'runWhere': where.trim(),
        'runPreson': person.trim(),
        'rinDistance': distance,
        'rinImageUrl': imageUrl
      });
    } catch (_) {
      if (imageUrl != null) await _remove(imageUrl);
      rethrow;
    }
  }

  Future<void> update(
      {required RunEntry entry,
      required String where,
      required String person,
      required int distance,
      XFile? replacementImage}) async {
    final newImageUrl = replacementImage == null
        ? entry.imageUrl
        : await _upload(replacementImage);
    try {
      await _client.from(table).update({
        'runWhere': where.trim(),
        'runPreson': person.trim(),
        'rinDistance': distance,
        'rinImageUrl': newImageUrl
      }).eq('id', entry.id);
    } catch (_) {
      if (replacementImage != null && newImageUrl != null) {
        await _remove(newImageUrl);
      }
      rethrow;
    }
    if (replacementImage != null && entry.imageUrl != null) {
      await _remove(entry.imageUrl!);
    }
  }

  Future<void> delete(RunEntry entry) async {
    await _client.from(table).delete().eq('id', entry.id);
    if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
      await _remove(entry.imageUrl!);
    }
  }

  Future<String> _upload(XFile image) async {
    final Uint8List bytes = await image.readAsBytes();
    final rawExt = image.name.contains('.')
        ? image.name.split('.').last.toLowerCase()
        : 'jpg';
    final ext = RegExp(r'^[a-z0-9]{2,5}$').hasMatch(rawExt) ? rawExt : 'jpg';
    final path = 'runs/${DateTime.now().microsecondsSinceEpoch}.$ext';
    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg'
    };
    await _client.storage.from(bucket).uploadBinary(path, bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: false));
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  String? _objectPath(String imageUrl) {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null) return null;
    final marker = '/$bucket/';
    final index = uri.path.indexOf(marker);
    if (index >= 0) {
      return Uri.decodeComponent(uri.path.substring(index + marker.length));
    }
    if (!uri.hasScheme && !imageUrl.startsWith('/')) {
      return imageUrl;
    }
    return null;
  }

  Future<void> _remove(String imageUrl) async {
    final path = _objectPath(imageUrl);
    if (path != null && path.isNotEmpty) {
      await _client.storage.from(bucket).remove([path]);
    }
  }

  Future<String?> displayUrl(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    final path = _objectPath(imageUrl);
    if (path == null) return imageUrl;
    try {
      return await _client.storage.from(bucket).createSignedUrl(path, 3600);
    } catch (_) {
      return imageUrl;
    }
  }

  String messageFor(Object error) {
    if (error is PostgrestException) {
      if (error.code == '42501') {
        return 'ไม่มีสิทธิ์เข้าถึงข้อมูล กรุณาตรวจสอบ RLS Policy ของ run_tb';
      }
      return error.message;
    }
    if (error is StorageException) {
      if (error.statusCode == '403' || error.statusCode == '404') {
        return 'เข้าถึง Storage ไม่ได้ กรุณาตรวจสอบ bucket run_bk และ Storage Policy';
      }
      return error.message;
    }
    if (error is SocketException) {
      return 'เชื่อมต่ออินเทอร์เน็ตไม่ได้ กรุณาลองอีกครั้ง';
    }
    return error.toString();
  }
}
