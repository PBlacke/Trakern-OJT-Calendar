import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' as excel;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/record_provider.dart';
import '../providers/settings_provider.dart';
import '../models/ojt_record.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Helper class for report rows
class _ReportRow {
  final DateTime date;
  final int day;
  final String amIn;
  final String amOut;
  final String pmIn;
  final String pmOut;
  final int undertimeHours;
  final int undertimeMinutes;
  final String? specialText; // "Sun", "Hol", "Abs"

  _ReportRow({
    required this.date,
    required this.day,
    required this.amIn,
    required this.amOut,
    required this.pmIn,
    required this.pmOut,
    required this.undertimeHours,
    required this.undertimeMinutes,
    this.specialText,
  });
}

enum ExportMode { fullMonth, customRange }

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  // Controllers
  final _regularDaysController = TextEditingController();
  final _saturdaysController = TextEditingController();
  bool _calculateUndertime = false;

  ExportMode _exportMode = ExportMode.fullMonth;
  DateTime? _selectedMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  List<OJTRecord> _filteredRecords = [];

  // Generate rows including special days
  List<_ReportRow> _generateRows() {
    // Determine date range
    DateTime rangeStart, rangeEnd;
    if (_exportMode == ExportMode.fullMonth && _selectedMonth != null) {
      rangeStart = _selectedMonth!;
      rangeEnd = DateTime(_selectedMonth!.year, _selectedMonth!.month + 1, 0);
    } else if (_exportMode == ExportMode.customRange && _startDate != null && _endDate != null) {
      rangeStart = _startDate!;
      rangeEnd = _endDate!;
    } else {
      return [];
    }

    // Map existing records
    final existingMap = <DateTime, OJTRecord>{};
    for (var record in _filteredRecords) {
      final dateKey = DateTime(record.date.year, record.date.month, record.date.day);
      existingMap[dateKey] = record;
    }

    List<_ReportRow> rows = [];
    DateTime current = rangeStart;
    while (current.isBefore(rangeEnd.add(const Duration(days: 1)))) {
      final dateKey = DateTime(current.year, current.month, current.day);
      final record = existingMap[dateKey];

      if (record != null) {
        // Existing record
        final amIn = record.timeIn1 ?? '-';
        final amOut = record.timeOut1 ?? '-';
        final pmIn = record.timeIn2 ?? '-';
        final pmOut = record.timeOut2 ?? '-';
        int undertimeHours = 0;
        int undertimeMinutes = 0;

        if (_calculateUndertime && !record.isHoliday && !record.isAbsent) {
          double required = 0;
          if (record.date.weekday == DateTime.saturday) {
            if (_saturdaysController.text.isNotEmpty) {
              required = double.tryParse(_saturdaysController.text) ?? 0;
            }
          } else {
            if (_regularDaysController.text.isNotEmpty) {
              required = double.tryParse(_regularDaysController.text) ?? 0;
            }
          }
          if (required > 0) {
            double actual = record.totalHours;
            if (actual < required) {
              double diff = required - actual;
              undertimeHours = diff.floor();
              undertimeMinutes = ((diff - undertimeHours) * 60).round();
            }
          }
        }

        rows.add(_ReportRow(
          date: record.date,
          day: record.date.day,
          amIn: amIn,
          amOut: amOut,
          pmIn: pmIn,
          pmOut: pmOut,
          undertimeHours: (record.isHoliday || record.isAbsent) ? 0 : undertimeHours,
          undertimeMinutes: (record.isHoliday || record.isAbsent) ? 0 : undertimeMinutes,
          specialText: record.isHoliday ? 'Hol' : (record.isAbsent ? 'Abs' : null),
        ));
      } else if (current.weekday == DateTime.sunday) {
        // Sunday without a record
        rows.add(_ReportRow(
          date: current,
          day: current.day,
          amIn: '-',
          amOut: '-',
          pmIn: '-',
          pmOut: '-',
          undertimeHours: 0,
          undertimeMinutes: 0,
          specialText: 'Sun',
        ));
      }

      current = current.add(const Duration(days: 1));
    }

    rows.sort((a, b) => a.day.compareTo(b.day));
    return rows;
  }

  void _updateFilteredRecords() {
    final records = Provider.of<RecordProvider>(context, listen: false).records;
    setState(() {
      if (_exportMode == ExportMode.fullMonth && _selectedMonth != null) {
        _filteredRecords = records.where((record) =>
            record.date.year == _selectedMonth!.year &&
            record.date.month == _selectedMonth!.month).toList();
      } else if (_exportMode == ExportMode.customRange && _startDate != null && _endDate != null) {
        _filteredRecords = records.where((record) =>
            record.date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
            record.date.isBefore(_endDate!.add(const Duration(days: 1)))).toList();
      } else {
        _filteredRecords = [];
      }
      _filteredRecords.sort((a, b) => a.date.compareTo(b.date));
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _startDate = DateTime(_selectedMonth!.year, _selectedMonth!.month, 1);
    _endDate = DateTime(_selectedMonth!.year, _selectedMonth!.month + 1, 0);
    _updateFilteredRecords();
  }

  @override
  void dispose() {
    _regularDaysController.dispose();
    _saturdaysController.dispose();
    super.dispose();
  }

  // Helper for special text colors in preview
  Color? _getSpecialColor(String? special) {
    if (special == 'Hol') return Colors.blue;
    if (special == 'Abs') return Colors.red;
    if (special == 'Sun') return Colors.orange;
    return null;
  }

  // Data cell that accepts optional style
  Widget _dataCell(String text, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(text, style: style ?? const TextStyle(fontSize: 8)),
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(text, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  // Build preview
  Widget _buildPreview() {
    final rows = _generateRows();
    final monthName = DateFormat('MMMM yyyy').format(_selectedMonth!);
    final settings = Provider.of<SettingsProvider>(context);
    final employeeName = settings.settings.employeeName.trim().isEmpty ? '[Name]' : settings.settings.employeeName;
    final supervisorName = settings.settings.supervisorName.trim().isEmpty ? '_________________________' : settings.settings.supervisorName;
    final regularText = _regularDaysController.text.isEmpty ? '______' : _regularDaysController.text;
    final satText = _saturdaysController.text.isEmpty ? '______' : _saturdaysController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Civil Service Form No. 48', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 10)),
        const SizedBox(height: 4),
        const Text('DAILY TIME RECORD', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const Text('---o0o---', style: TextStyle(letterSpacing: 2, fontSize: 10)),
        const SizedBox(height: 8),
        Text(employeeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const Text('(Name)', style: TextStyle(fontSize: 8)),
        const SizedBox(height: 4),
        if (_exportMode == ExportMode.fullMonth)
          Row(children: [
            const Text('For the month of ', style: TextStyle(fontSize: 10)),
            Text(monthName, style: const TextStyle(fontSize: 10, decoration: TextDecoration.underline)),
          ])
        else
          Row(children: [
            const Text('From ', style: TextStyle(fontSize: 10)),
            Text(DateFormat('yyyy-MM-dd').format(_startDate!), style: const TextStyle(fontSize: 10, decoration: TextDecoration.underline)),
            const Text(' to ', style: TextStyle(fontSize: 10)),
            Text(DateFormat('yyyy-MM-dd').format(_endDate!), style: const TextStyle(fontSize: 10, decoration: TextDecoration.underline)),
          ]),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Official hours for arrival and departure', style: TextStyle(fontSize: 9)),
            Row(children: [
              const Text('Regular days ', style: TextStyle(fontSize: 9)),
              Text(regularText, style: const TextStyle(fontSize: 9, decoration: TextDecoration.underline)),
            ]),
            Row(children: [
              const Text('Saturdays ', style: TextStyle(fontSize: 9)),
              Text(satText, style: const TextStyle(fontSize: 9, decoration: TextDecoration.underline)),
            ]),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade400, width: 0.5),
            columnWidths: const {
              0: FixedColumnWidth(30),
              1: FixedColumnWidth(45),
              2: FixedColumnWidth(45),
              3: FixedColumnWidth(45),
              4: FixedColumnWidth(45),
              5: FixedColumnWidth(40),
              6: FixedColumnWidth(40),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade200),
                children: [
                  _headerCell('Day'),
                  _headerCell('A.M.'),
                  _headerCell(''),
                  _headerCell('P.M.'),
                  _headerCell(''),
                  _headerCell('Undertime'),
                  _headerCell(''),
                ],
              ),
              TableRow(
                children: [
                  _headerCell(''),
                  _headerCell('Arrival'),
                  _headerCell('Departure'),
                  _headerCell('Arrival'),
                  _headerCell('Departure'),
                  _headerCell('Hours'),
                  _headerCell('Minutes'),
                ],
              ),
              ...rows.map((row) {
                final isSpecial = row.specialText != null;
                final displayHours = isSpecial ? row.specialText! : (row.undertimeHours == 0 ? '' : row.undertimeHours.toString());
                final displayMinutes = isSpecial ? '' : (row.undertimeMinutes == 0 ? '' : row.undertimeMinutes.toString());
                final hoursStyle = TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: _getSpecialColor(row.specialText));
                return TableRow(
                  children: [
                    _dataCell(row.day.toString()),
                    _dataCell(row.amIn),
                    _dataCell(row.amOut),
                    _dataCell(row.pmIn),
                    _dataCell(row.pmOut),
                    _dataCell(displayHours, style: hoursStyle),
                    _dataCell(displayMinutes),
                  ],
                );
              }).toList(),
              TableRow(
                children: [
                  _dataCell('Total'),
                  _dataCell(''),
                  _dataCell(''),
                  _dataCell(''),
                  _dataCell(''),
                  _dataCell(''),
                  _dataCell(''),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('I certify on my honor that the above is a true and correct report of the hours of work performed, record of which was made daily at the time of arrival and departure from office.',
            style: TextStyle(fontSize: 8)),
        const SizedBox(height: 8),
        const Text('_________________________', style: TextStyle(decoration: TextDecoration.underline, fontSize: 10)),
        const SizedBox(height: 4),
        const Text('(Signature)', style: TextStyle(fontSize: 8)),
        const SizedBox(height: 8),
        const Text('VERIFIED as to the prescribed office hours:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9)),
        const SizedBox(height: 4),
        Text(supervisorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8)),
        const Text('(In Charge/Supervisor)', style: TextStyle(fontSize: 8)),
      ],
    );
  }

  // Build PDF table
  pw.Widget _buildPdfTable(List<_ReportRow> rows) {
    final columnWidths = {
      0: pw.FixedColumnWidth(30),
      1: pw.FixedColumnWidth(45),
      2: pw.FixedColumnWidth(45),
      3: pw.FixedColumnWidth(45),
      4: pw.FixedColumnWidth(45),
      5: pw.FixedColumnWidth(40),
      6: pw.FixedColumnWidth(40),
    };

    final headers = ['Day', 'A.M.', '', 'P.M.', '', 'Undertime', ''];
    final subHeaders = ['', 'Arrival', 'Departure', 'Arrival', 'Departure', 'Hours', 'Minutes'];

    final tableRows = <pw.TableRow>[];

    tableRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColors.grey300),
        children: headers.map((h) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: pw.Text(h, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        )).toList(),
      ),
    );
    tableRows.add(
      pw.TableRow(
        children: subHeaders.map((h) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: pw.Text(h, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        )).toList(),
      ),
    );

    for (final row in rows) {
      final isSpecial = row.specialText != null;
      final displayHours = isSpecial ? row.specialText! : (row.undertimeHours == 0 ? '' : row.undertimeHours.toString());
      final displayMinutes = isSpecial ? '' : (row.undertimeMinutes == 0 ? '' : row.undertimeMinutes.toString());
      final hoursColor = isSpecial
          ? (row.specialText == 'Hol' ? PdfColors.blue : (row.specialText == 'Abs' ? PdfColors.red : PdfColors.orange))
          : null;

      final cells = <pw.Widget>[
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: pw.Text(row.day.toString(), style: pw.TextStyle(fontSize: 8))),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: pw.Text(row.amIn, style: pw.TextStyle(fontSize: 8))),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: pw.Text(row.amOut, style: pw.TextStyle(fontSize: 8))),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: pw.Text(row.pmIn, style: pw.TextStyle(fontSize: 8))),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: pw.Text(row.pmOut, style: pw.TextStyle(fontSize: 8))),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: pw.Text(displayHours, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: hoursColor))),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: pw.Text(displayMinutes, style: pw.TextStyle(fontSize: 8))),
      ];
      tableRows.add(pw.TableRow(children: cells));
    }

    tableRows.add(
      pw.TableRow(
        children: [
          pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: pw.Text('Total', style: pw.TextStyle(fontSize: 8))),
          for (int i = 0; i < 6; i++) pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: pw.Text('', style: pw.TextStyle(fontSize: 8))),
        ],
      ),
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: columnWidths,
      children: tableRows,
    );
  }

  // PDF export
  Future<void> _exportToPdf() async {
    final rows = _generateRows();
    final monthName = DateFormat('MMMM yyyy').format(_selectedMonth!);
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
    final employeeName = settings.employeeName.trim().isEmpty ? '[Name]' : settings.employeeName;
    final supervisorName = settings.supervisorName.trim().isEmpty ? '_________________________' : settings.supervisorName;
    final regularText = _regularDaysController.text.isEmpty ? '______' : _regularDaysController.text;
    final satText = _saturdaysController.text.isEmpty ? '______' : _saturdaysController.text;

    final pdf = pw.Document();
    final pageFormat = PdfPageFormat(4.25 * 72, 11 * 72, marginAll: 16);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Civil Service Form No. 48', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 9)),
              pw.SizedBox(height: 2),
              pw.Text('DAILY TIME RECORD', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('---o0o---', style: pw.TextStyle(letterSpacing: 2, fontSize: 9)),
              pw.SizedBox(height: 6),
              pw.Text(employeeName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text('(Name)', style: pw.TextStyle(fontSize: 7)),
              pw.SizedBox(height: 2),
              if (_exportMode == ExportMode.fullMonth)
                pw.Row(children: [
                  pw.Text('For the month of ', style: pw.TextStyle(fontSize: 9)),
                  pw.Text(monthName, style: pw.TextStyle(fontSize: 9, decoration: pw.TextDecoration.underline)),
                ])
              else
                pw.Row(children: [
                  pw.Text('From ', style: pw.TextStyle(fontSize: 9)),
                  pw.Text(DateFormat('yyyy-MM-dd').format(_startDate!), style: pw.TextStyle(fontSize: 9, decoration: pw.TextDecoration.underline)),
                  pw.Text(' to ', style: pw.TextStyle(fontSize: 9)),
                  pw.Text(DateFormat('yyyy-MM-dd').format(_endDate!), style: pw.TextStyle(fontSize: 9, decoration: pw.TextDecoration.underline)),
                ]),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Official hours for arrival and departure', style: pw.TextStyle(fontSize: 8)),
                  pw.Row(children: [
                    pw.Text('Regular days ', style: pw.TextStyle(fontSize: 8)),
                    pw.Text(regularText, style: pw.TextStyle(fontSize: 8, decoration: pw.TextDecoration.underline)),
                  ]),
                  pw.Row(children: [
                    pw.Text('Saturdays ', style: pw.TextStyle(fontSize: 8)),
                    pw.Text(satText, style: pw.TextStyle(fontSize: 8, decoration: pw.TextDecoration.underline)),
                  ]),
                ],
              ),
              pw.SizedBox(height: 6),
              _buildPdfTable(rows),
              pw.SizedBox(height: 12),
              pw.Text(
                'I certify on my honor that the above is a true and correct report of the hours of work performed, record of which was made daily at the time of arrival and departure from office.',
                style: pw.TextStyle(fontSize: 7),
              ),
              pw.SizedBox(height: 6),
              pw.Text('_________________________', style: pw.TextStyle(decoration: pw.TextDecoration.underline, fontSize: 9)),
              pw.SizedBox(height: 2),
              pw.Text('(Signature)', style: pw.TextStyle(fontSize: 7)),
              pw.SizedBox(height: 6),
              pw.Text('VERIFIED as to the prescribed office hours:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
              pw.SizedBox(height: 2),
              pw.Text('_________________________', style: pw.TextStyle(decoration: pw.TextDecoration.underline, fontSize: 9)),
              pw.SizedBox(height: 2),
              pw.Text(supervisorName, style: pw.TextStyle(fontSize: 7)),
            ],
          );
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/DTR_${monthName.replaceAll(' ', '_')}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(filePath)], text: 'DTR Report for $monthName');
  }

  // Excel export
  Future<void> _exportToExcel() async {
    final rows = _generateRows();
    final monthName = DateFormat('MMMM yyyy').format(_selectedMonth!);
    final regular = _regularDaysController.text.trim();
    final sat = _saturdaysController.text.trim();

    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
    final employeeName = settings.employeeName.trim().isEmpty ? '[Name]' : settings.employeeName;
    final supervisorName = settings.supervisorName.trim().isEmpty ? '_________________________' : settings.supervisorName;

    var excelDoc = excel.Excel.createExcel();
    var sheet = excelDoc['Sheet1'];

    int rowIdx = 0;
    void setCell(int col, int row, String value) {
      sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value = excel.TextCellValue(value);
    }

    // Header
    setCell(0, rowIdx++, 'Civil Service Form No. 48');
    setCell(0, rowIdx++, 'DAILY TIME RECORD');
    setCell(0, rowIdx++, '---o0o---');
    rowIdx++;
    setCell(0, rowIdx++, employeeName);
    setCell(0, rowIdx++, '(Name)');
    rowIdx++;

    if (_exportMode == ExportMode.fullMonth) {
      setCell(0, rowIdx++, 'For the month of $monthName');
    } else {
      setCell(0, rowIdx++, 'From ${DateFormat('yyyy-MM-dd').format(_startDate!)} to ${DateFormat('yyyy-MM-dd').format(_endDate!)}');
    }
    rowIdx++;

    setCell(0, rowIdx, 'Official hours for arrival and departure');
    setCell(1, rowIdx, 'Regular days: $regular');
    setCell(2, rowIdx, 'Saturdays: $sat');
    rowIdx++;
    rowIdx++;

    final headers = ['Day', 'A.M. Arrival', 'A.M. Departure', 'P.M. Arrival', 'P.M. Departure', 'Undertime Hours', 'Undertime Minutes'];
    for (int i = 0; i < headers.length; i++) {
      setCell(i, rowIdx, headers[i]);
    }
    rowIdx++;

    for (var row in rows) {
      final isSpecial = row.specialText != null;
      final displayHours = isSpecial ? row.specialText! : row.undertimeHours.toString();
      final displayMinutes = isSpecial ? '' : row.undertimeMinutes.toString();
      setCell(0, rowIdx, row.day.toString());
      setCell(1, rowIdx, row.amIn);
      setCell(2, rowIdx, row.amOut);
      setCell(3, rowIdx, row.pmIn);
      setCell(4, rowIdx, row.pmOut);
      setCell(5, rowIdx, displayHours);
      setCell(6, rowIdx, displayMinutes);
      rowIdx++;
    }

    setCell(0, rowIdx, 'Total');
    rowIdx++;

    rowIdx++;
    setCell(0, rowIdx++, 'I certify on my honor that the above is a true and correct report of the hours of work performed, record of which was made daily at the time of arrival and departure from office.');
    rowIdx++;
    setCell(0, rowIdx++, '_________________________');
    setCell(0, rowIdx++, '(Signature)');
    rowIdx++;
    setCell(0, rowIdx++, 'VERIFIED as to the prescribed office hours:');
    rowIdx++;
    setCell(0, rowIdx++, '_________________________');
    setCell(0, rowIdx++, supervisorName);

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/DTR_${monthName.replaceAll(' ', '_')}.xlsx';
    final file = File(filePath);
    file.createSync(recursive: true);
    file.writeAsBytesSync(excelDoc.encode()!);
    await Share.shareXFiles([XFile(filePath)], text: 'DTR Report for $monthName');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export DTR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Export Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<ExportMode>(
              segments: const [
                ButtonSegment<ExportMode>(value: ExportMode.fullMonth, label: Text('Full Month')),
                ButtonSegment<ExportMode>(value: ExportMode.customRange, label: Text('Custom Range')),
              ],
              selected: {_exportMode},
              onSelectionChanged: (Set<ExportMode> newSelection) {
                setState(() {
                  _exportMode = newSelection.first;
                  if (_exportMode == ExportMode.fullMonth) {
                    _startDate = DateTime(_selectedMonth!.year, _selectedMonth!.month, 1);
                    _endDate = DateTime(_selectedMonth!.year, _selectedMonth!.month + 1, 0);
                  } else {
                    if (_startDate == null || _endDate == null) {
                      _startDate = DateTime(_selectedMonth!.year, _selectedMonth!.month, 1);
                      _endDate = DateTime(_selectedMonth!.year, _selectedMonth!.month + 1, 0);
                    }
                  }
                  _updateFilteredRecords();
                });
              },
            ),
            const SizedBox(height: 16),

            if (_exportMode == ExportMode.fullMonth)
              ListTile(
                title: const Text('Select Month'),
                subtitle: Text(DateFormat('MMMM yyyy').format(_selectedMonth!)),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedMonth!,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedMonth = DateTime(picked.year, picked.month, 1);
                      _updateFilteredRecords();
                    });
                  }
                },
              ),

            if (_exportMode == ExportMode.customRange) ...[
              const Text('Start Date', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              ListTile(
                title: Text(_startDate == null ? 'Not set' : DateFormat('yyyy-MM-dd').format(_startDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _startDate = picked;
                      if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
                      _updateFilteredRecords();
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              const Text('End Date', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              ListTile(
                title: Text(_endDate == null ? 'Not set' : DateFormat('yyyy-MM-dd').format(_endDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: _startDate ?? DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _endDate = picked;
                      _updateFilteredRecords();
                    });
                  }
                },
              ),
            ],

            const SizedBox(height: 16),
            TextFormField(
              controller: _regularDaysController,
              decoration: const InputDecoration(
                labelText: 'Regular Days (e.g., 8)',
                hintText: 'Optional, for undertime calculation',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _saturdaysController,
              decoration: const InputDecoration(
                labelText: 'Saturdays (e.g., 4)',
                hintText: 'Optional, for undertime calculation',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Calculate Undertime'),
              value: _calculateUndertime,
              onChanged: (val) {
                setState(() {
                  _calculateUndertime = val ?? false;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text('Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 500,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildPreview(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _exportToExcel,
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Export to Excel'),
                ),
                ElevatedButton.icon(
                  onPressed: _exportToPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export to PDF'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}