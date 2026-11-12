import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/about/about_downloads.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this.assets);

  final Map<String, Uint8List> assets;
  final List<String> requestedKeys = [];

  @override
  Future<ByteData> load(String key) async {
    requestedKeys.add(key);
    final bytes = assets[key];
    if (bytes == null) {
      throw StateError('Missing asset: $key');
    }
    return ByteData.sublistView(bytes);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('versionedDownloadFileName changes when bundled PDF bytes change', () {
    final oldBytes = Uint8List.fromList(utf8.encode('%PDF-old-material-book'));
    final newBytes = Uint8List.fromList(utf8.encode('%PDF-new-material-book'));

    final oldName = versionedDownloadFileName('NetLearn_Buku_Materi.pdf', oldBytes);
    final newName = versionedDownloadFileName('NetLearn_Buku_Materi.pdf', newBytes);

    expect(oldName, startsWith('NetLearn_Buku_Materi_'));
    expect(oldName, endsWith('.pdf'));
    expect(newName, startsWith('NetLearn_Buku_Materi_'));
    expect(newName, endsWith('.pdf'));
    expect(oldName, isNot(newName));
    expect(
      versionedDownloadFileName('NetLearn_Buku_Materi.pdf', newBytes),
      equals(newName),
    );
  });

  test('openAboutDownload loads netlearn_material_book.pdf with versioned filename', () async {
    final expectedBytes = Uint8List.fromList(utf8.encode('%PDF-1.7 new content'));
    final fakeBundle = _FakeAssetBundle({
      'assets/downloads/netlearn_material_book.pdf': expectedBytes,
    });

    Uint8List? savedBytes;
    String? savedName;

    await openAboutDownload(
      AboutDownloadResource.materialBook,
      bundle: fakeBundle,
      saveAndOpen: (bytes, fileName) async {
        savedBytes = bytes;
        savedName = fileName;
      },
    );

    expect(
      fakeBundle.requestedKeys,
      ['assets/downloads/netlearn_material_book.pdf'],
    );
    expect(savedBytes, orderedEquals(expectedBytes));
    expect(
      savedName,
      versionedDownloadFileName('NetLearn_Buku_Materi.pdf', expectedBytes),
    );
  });

  test('bundled netlearn_material_book.pdf is readable and valid PDF', () async {
    Uint8List? savedBytes;
    String? savedName;

    await openAboutDownload(
      AboutDownloadResource.materialBook,
      saveAndOpen: (bytes, fileName) async {
        savedBytes = bytes;
        savedName = fileName;
      },
    );

    expect(savedBytes, isNotNull);
    expect(savedBytes!.length, greaterThan(1000));
    expect(ascii.decode(savedBytes!.sublist(0, 5)), '%PDF-');
    expect(savedName, startsWith('NetLearn_Buku_Materi_'));
    expect(savedName, endsWith('.pdf'));
  });
}

