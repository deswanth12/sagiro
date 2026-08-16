class TableRow {
  final List<String> cells;
  final int lineNumber;

  const TableRow({required this.cells, required this.lineNumber});
}

class TableExtractor {
  static List<TableRow> extractGrid(String text,
      {String delimiter = r'[\t,;\s]+'}) {
    final lines = text.split(RegExp(r'\r?\n'));
    final grid = <TableRow>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cells =
          line.split(RegExp(delimiter)).where((c) => c.isNotEmpty).toList();
      if (cells.isNotEmpty) {
        grid.add(TableRow(cells: cells, lineNumber: i + 1));
      }
    }
    return grid;
  }
}
