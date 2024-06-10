import 'dart:io';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:open_file/open_file.dart';
import 'package:dio/dio.dart';
import 'package:vocsy_epub_viewer/epub_viewer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AES Encryption',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? downloadedFile;
  File? encryptedFile;
  File? decryptedFile;
  final encrypt.Key key = encrypt.Key.fromLength(32);
  final encrypt.IV iv = encrypt.IV.fromLength(16);
  final encrypt.Encrypter encrypter = encrypt.Encrypter(encrypt.AES(
      encrypt.Key.fromLength(32),
      mode: encrypt.AESMode.cbc,
      padding: 'PKCS7'));

  Future<void> _downloadFile(String url) async {
    try {
      final dio = Dio();
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, path.basename(url));
      await dio.download(url, filePath);
      setState(() {
        downloadedFile = File(filePath);
        encryptedFile = null;
        decryptedFile = null;
      });
      _showMessage('File downloaded: ${downloadedFile!.path}');
    } catch (e) {
      _showMessage('Error: $e');
    }
  }

  Future<void> _encryptFile() async {
    if (downloadedFile == null) return;
    final bytes = await downloadedFile!.readAsBytes();
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);
    final directory = await getApplicationDocumentsDirectory();
    encryptedFile = File(path.join(
        directory.path, '${path.basename(downloadedFile!.path)}.aes'));
    await encryptedFile!.writeAsBytes(encrypted.bytes);
    _showMessage('File encrypted: ${encryptedFile!.path}');
  }

  Future<void> _decryptFile() async {
    if (encryptedFile == null) return;
    final bytes = await encryptedFile!.readAsBytes();
    final decrypted = encrypter.decryptBytes(encrypt.Encrypted(bytes), iv: iv);
    final directory = await getApplicationDocumentsDirectory();
    decryptedFile = File(path.join(directory.path,
        path.basename(encryptedFile!.path).replaceAll('.aes', '')));
    await decryptedFile!.writeAsBytes(decrypted);
    _showMessage('File decrypted: ${decryptedFile!.path}');
  }

  void _viewDecryptedFile() {
    if (decryptedFile == null) {
      _showMessage('No decrypted file to view');
      return;
    }
    if (path.extension(decryptedFile!.path).toLowerCase() == '.epub') {
      // ignore: avoid_print
      print('_________________________________${decryptedFile!.path}');
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => EPUBViewerPage(filePath: decryptedFile!.path),
      ));
    } else {
      OpenFile.open(decryptedFile!.path);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (downloadedFile != null)
              Text('Downloaded file: ${downloadedFile!.path}'),
            ElevatedButton(
              onPressed: () => _downloadFile(
                  'https://vocsyinfotech.in/envato/cc/flutter_ebook/uploads/22566_The-Racketeer---John-Grisham.epub'),
              child: const Text('Download File'),
            ),
            ElevatedButton(
              onPressed: _encryptFile,
              child: const Text('Encrypt File'),
            ),
            ElevatedButton(
              onPressed: _decryptFile,
              child: const Text('Decrypt File'),
            ),
            ElevatedButton(
              onPressed: _viewDecryptedFile,
              child: const Text('View Decrypted File'),
            ),
          ],
        ),
      ),
    );
  }
}

class EPUBViewerPage extends StatefulWidget {
  final String filePath;

  const EPUBViewerPage({super.key, required this.filePath});

  @override
  State<EPUBViewerPage> createState() => _EPUBViewerPageState();
}

class _EPUBViewerPageState extends State<EPUBViewerPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("EPUB Viewer"),
      ),
      body: VocsyEpub.open(
          widget.filePath,
           lastLocation: EpubLocator.fromJson({
	   "bookId": "2239",
	   "href": "/OEBPS/ch06.xhtml",
	   "created": 1539934158390,
	   "locations": {
		"cfi": "epubcfi(/0!/4/4[simple_book]/2/2/6)"
	          }
	    }), // first page will open up if the value is null
        );

    );
  }
}