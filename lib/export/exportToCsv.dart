import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'dart:io';

Future<void> exportToCSV(List<Map<String, dynamic>> speedData) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/speed_data.csv';

  List<List<String>> rows = [
    ['Timestamp', 'Speed (km/h)'],
    ...speedData.map((data) => [
      data['timestamp'].toString(),
      data['speed'].toString(),
    ]),
  ];

  String csvData = const ListToCsvConverter().convert(rows);
  final file = File(filePath);
  await file.writeAsString(csvData);

  print('Fichier CSV enregistré à : $filePath');
}
