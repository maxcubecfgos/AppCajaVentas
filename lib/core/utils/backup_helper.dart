import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class BackupHelper {
  BackupHelper._();

  static const _databaseName = 'pos_database.db';

  /// Ruta actual del archivo de base de datos.
  static Future<File> _databaseFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(join(directory.path, _databaseName));
  }

  /// Exporta la base de datos actual y abre el share sheet.
  static Future<void> exportDatabase() async {
    final dbFile = await _databaseFile();
    if (!await dbFile.exists()) {
      throw Exception('No se encontró la base de datos para exportar.');
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(
      RegExp(r'[: ]'),
      '_',
    );
    final exportFile = File(join(tempDir.path, 'backup_$timestamp.db'));
    await exportFile.writeAsBytes(await dbFile.readAsBytes());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(exportFile.path)],
        text: 'Respaldo de MicroPOS - $timestamp',
        subject: 'Respaldo MicroPOS',
      ),
    );
  }

  /// Permite seleccionar un archivo .db y lo restaura como base de datos actual.
  static Future<void> restoreDatabase() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
    );

    if (result == null || result.files.isEmpty) return;

    final sourceFile = File(result.files.single.path!);
    if (!await sourceFile.exists()) {
      throw Exception('El archivo seleccionado no existe.');
    }

    final dbFile = await _databaseFile();
    await dbFile.writeAsBytes(await sourceFile.readAsBytes());
  }
}
