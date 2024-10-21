import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:universal_html/html.dart' as html;
import 'package:intl/intl.dart';
import '../model/employee.dart';

class EmployeeReportPage extends StatelessWidget {
  final List<Employee> employees = [
    Employee(id: '001', name: 'Ahmet Yilmaz', position: 'Yazilim Gelistirici', hireDate: DateTime(2020, 3, 15), salary: 100000),
    Employee(id: '002', name: 'Ayse Demir', position: 'Proje Yoneticisi', hireDate: DateTime(2018, 7, 1), salary: 120000),
    Employee(id: '003', name: 'Mehmet Kaya', position: 'Veri Analisti', hireDate: DateTime(2021, 1, 10), salary: 90000),
    Employee(id: '004', name: 'Zeynep Celik', position: 'UI/UX Tasarimci', hireDate: DateTime(2019, 11, 5), salary: 95000),
    Employee(id: '005', name: 'Mustafa Sahin', position: 'Sistem Yoneticisi', hireDate: DateTime(2017, 5, 20), salary: 110000),
  ];

  Future<Uint8List> _readFontData() async {
    final ByteData bytes = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
  }

  Future<void> generatePDF(BuildContext context) async {
    final pdf = pw.Document();
    final fontData = await _readFontData();
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Çalışan Raporu', style: pw.TextStyle(font: ttf, fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              border: null,
              headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              cellStyle: pw.TextStyle(font: ttf),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.centerRight,
              },
              data: <List<String>>[
                <String>['ID', 'Ad Soyad', 'Pozisyon', 'İşe Başlama Tarihi', 'Maaş'],
                ...employees.map((employee) => [
                  employee.id,
                  employee.name,
                  employee.position,
                  DateFormat('dd.MM.yyyy').format(employee.hireDate),
                  '${employee.salary.toStringAsFixed(2)} TL',
                ]),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Paragraph(
              text: 'Toplam Çalışan Sayısı: ${employees.length}',
              style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold),
            ),
            pw.Paragraph(
              text: 'Ortalama Maaş: ${(employees.map((e) => e.salary).reduce((a, b) => a + b) / employees.length).toStringAsFixed(2)} TL',
              style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
      html.Url.revokeObjectUrl(url);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/calisan_raporu.pdf');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF raporu oluşturuldu ve ${kIsWeb ? 'indirildi' : 'açıldı'}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Çalışan Raporu')),
      body: ListView.builder(
        itemCount: employees.length,
        itemBuilder: (context, index) {
          final employee = employees[index];
          return ListTile(
            title: Text(employee.name),
            subtitle: Text(employee.position),
            trailing: Text('${employee.salary.toStringAsFixed(2)} TL'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => generatePDF(context),
        child: Icon(Icons.picture_as_pdf),
        tooltip: 'PDF Raporu Oluştur',
      ),
    );
  }
}