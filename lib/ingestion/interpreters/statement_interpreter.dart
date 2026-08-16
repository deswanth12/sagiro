import '../../models/transaction.dart';
import '../extractors/table_extractor.dart';

abstract class StatementInterpreter {
  String get bankId;
  String get bankName;
  bool canInterpret(String rawHeader);
  List<TransactionItem> interpret(List<TableRow> rows);
}
