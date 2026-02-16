import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/person.dart';
import 'firestore_service.dart';

class ExportService {
  Future<String?> exportToExcel(FirestoreService firestore) async {
    final persons = await firestore.getAllPersonsForExport();
    if (persons.isEmpty) return null;

    final excel = Excel.createExcel();
    final defaultName = excel.sheets.keys.first;
    excel.rename(defaultName, 'Personas');
    final sheet = excel['Personas'];

    // Encabezados: 12 datos + columnas dinámicas para visitas (fecha, contenido, quien)
    final maxVisits = await _maxVisits(firestore, persons);
    int col = 0;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0)).value = TextCellValue('Nombre y apellidos');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0)).value = TextCellValue('Dirección');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0)).value = TextCellValue('Teléfono');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0)).value = TextCellValue('Edad');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0)).value = TextCellValue('Género');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0)).value = TextCellValue('A qué se dedica');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0)).value = TextCellValue('Cristiano/iglesia');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0)).value = TextCellValue('Quiere visitas');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0)).value = TextCellValue('Vicios');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0)).value = TextCellValue('Enfermedad mental');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0)).value = TextCellValue('Enfermedad crónica');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0)).value = TextCellValue('Complejidad');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0)).value = TextCellValue('Grupo');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0)).value = TextCellValue('Comentarios');
    for (var v = 0; v < maxVisits; v++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0)).value = TextCellValue('Visita ${v + 1} Fecha');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0)).value = TextCellValue('Visita ${v + 1} Contenido');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: 0)).value = TextCellValue('Visita ${v + 1} Quién');
    }

    int row = 1;
    for (final p in persons) {
      final visits = await firestore.getVisitsForPerson(p.id);
      col = 0;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(p.nombreApellidos);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(p.direccion);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(p.telefono);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(p.edad);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(p.genero);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(p.aQueSeDedica);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(p.esCristianoOAsisteIglesia);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(p.quiereRecibirVisitas);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(p.vicios.join(', '));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(p.enfermedadMental);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(p.enfermedadCronica);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue('${p.nivelComplejidad}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(p.grupo);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(p.comentarios);
      for (var v = 0; v < maxVisits; v++) {
        if (v < visits.length) {
          final visit = visits[v];
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(DateFormat('d/M/yyyy').format(visit.fecha));
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(visit.contenido);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: row)).value = TextCellValue(visit.visitadoPor);
        } else {
          col += 3;
        }
      }
      row++;
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/misionapp_export_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    final bytes = excel.encode();
    if (bytes == null) return null;
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<int> _maxVisits(FirestoreService firestore, List<Person> persons) async {
    int max = 0;
    for (final p in persons) {
      final visits = await firestore.getVisitsForPerson(p.id);
      if (visits.length > max) max = visits.length;
    }
    return max;
  }
}
