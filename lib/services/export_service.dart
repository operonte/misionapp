import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/visit.dart';
import 'firestore_service.dart';

class ExportService {
  /// Exports all persons + visits to Excel and opens the native Share sheet.
  /// Returns the file path on success, null if there is nothing to export.
  Future<String?> exportToExcel(FirestoreService firestore) async {
    final persons = await firestore.getAllPersonsForExport();
    if (persons.isEmpty) return null;

    // Single pass: fetch all visits and track the maximum count.
    // This halves the Firestore reads compared to the previous N+N approach.
    final allVisits = <String, List<Visit>>{};
    int maxVisits = 0;
    for (final p in persons) {
      final visits = await firestore.getVisitsForPerson(p.id);
      allVisits[p.id] = visits;
      if (visits.length > maxVisits) maxVisits = visits.length;
    }

    final excel = Excel.createExcel();
    final defaultName = excel.sheets.keys.first;
    excel.rename(defaultName, 'Personas');
    final sheet = excel['Personas'];

    // Headers
    int col = 0;
    final headers = [
      'Nombre y apellidos', 'Dirección', 'Teléfono', 'Edad', 'Género',
      'A qué se dedica', 'Cristiano/iglesia', 'Quiere visitas', 'Vicios',
      'Enfermedad mental', 'Enfermedad crónica', 'Complejidad', 'Grupo',
      'Comentarios',
    ];
    for (final h in headers) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0))
          .value = TextCellValue(h);
    }
    for (var v = 0; v < maxVisits; v++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0))
          .value = TextCellValue('Visita ${v + 1} Fecha');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0))
          .value = TextCellValue('Visita ${v + 1} Contenido');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0))
          .value = TextCellValue('Visita ${v + 1} Quién');
    }

    // Rows
    int row = 1;
    for (final p in persons) {
      col = 0;
      final visits = allVisits[p.id] ?? [];
      final cells = [
        p.nombreApellidos, p.direccion, p.telefono, p.edad, p.genero,
        p.aQueSeDedica, p.esCristianoOAsisteIglesia, p.quiereRecibirVisitas,
        p.vicios.join(', '), p.enfermedadMental, p.enfermedadCronica,
        '${p.nivelComplejidad}', p.grupo, p.comentarios,
      ];
      for (final c in cells) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
            .value = TextCellValue(c);
      }
      for (var v = 0; v < maxVisits; v++) {
        if (v < visits.length) {
          final visit = visits[v];
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
              .value = TextCellValue(DateFormat('d/M/yyyy').format(visit.fecha));
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
              .value = TextCellValue(visit.contenido);
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row))
              .value = TextCellValue(visit.visitadoPor);
        } else {
          col += 3;
        }
      }
      row++;
    }

    final bytes = excel.encode();
    if (bytes == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/misionapp_$timestamp.xlsx');
    await file.writeAsBytes(bytes);

    // Open the native share sheet so the user can save or send the file.
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: 'MisionApp — exportación $timestamp',
    );

    // Clean up the temp file once the share sheet has been dismissed.
    try {
      await file.delete();
    } catch (_) {}

    return file.path;
  }
}
