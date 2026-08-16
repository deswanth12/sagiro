import 'package:intl/intl.dart';
import 'financial_documents.dart';

class ContextPayload {
  final String formattedContext;
  final List<FinancialDocument> retrievedDocs;

  ContextPayload({required this.formattedContext, required this.retrievedDocs});
}

class ContextBuilder {
  static ContextPayload buildContextPayload(List<FinancialDocument> docs) {
    if (docs.isEmpty) {
      return ContextPayload(
        formattedContext: 'No relevant local financial context retrieved.',
        retrievedDocs: const [],
      );
    }

    final buffer = StringBuffer();
    buffer
        .writeln('RETRIEVED LOCAL FINANCIAL CONTEXT (${docs.length} records):');

    for (int i = 0; i < docs.length; i++) {
      final doc = docs[i];
      if (doc.type == DocumentType.transaction && doc.transaction != null) {
        final t = doc.transaction!;
        buffer.writeln(
          '${i + 1}. [TX] ${DateFormat('dd MMM yyyy').format(t.date)}: ${t.merchant} | ₹${t.amount.toInt()} | ${t.category} | ${t.type.name.toUpperCase()}',
        );
      } else if (doc.type == DocumentType.subscription &&
          doc.subscription != null) {
        final s = doc.subscription!;
        buffer.writeln(
          '${i + 1}. [SUB] ${s.merchant} | ₹${s.averageAmount.toInt()}/mo | ${s.category}',
        );
      } else {
        buffer.writeln('${i + 1}. ${doc.content}');
      }
    }

    return ContextPayload(
      formattedContext: buffer.toString().trim(),
      retrievedDocs: docs,
    );
  }
}
